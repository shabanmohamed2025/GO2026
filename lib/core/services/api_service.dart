import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';
import 'encryption_service.dart';

import '../config/api_config.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  // ضع هنا بصمة سيرفر الإنتاج الخاص بك (SHA-256)
  // تم ضبطها الآن للاستمرار مع: go.com
  static const String serverFingerprint =
      "21:EE:35:78:78:7C:75:51:FD:D0:6E:3D:7A:75:79:76:42:8C:C2:36:3B:16:FA:EF:A7:AD:3D:66:92:59:42:CA";

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // إضافة الـ Custom JWT (الخاص بالسيرفر) في كل طلب تلقائياً (بدلاً من فايربيس)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // لا نحتاج للتوكن في مسار الدخول لأنه يحتاج لتوكن فايربيس بشكل خاص
          if (!options.path.contains('/api/auth/login')) {
            final backendToken = await SecureStorageService().getToken();
            if (backendToken != null) {
              options.headers['Authorization'] = 'Bearer $backendToken';
            }
          }
          options.headers['Bypass-Tunnel-Reminder'] = 'true';
          return handler.next(options);
        },
      ),
    );

    // إعداد الـ SSL Pinning على المنصات التي تدعم dart:io (مثل Android و iOS و Windows)
    if (!kIsWeb) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client
              .badCertificateCallback = (X509Certificate cert, String host, int port) {
            // التحقق من البصمة باستخدام تشفير SHA-256 للشهادة
            final hash = sha256.convert(cert.der).toString().toUpperCase();
            // تحويل الـ hash إلى صيغة بصمات الأصابع (مفصولة بنقاطتين :)
            final certFingerprint = [
              for (var i = 0; i < hash.length; i += 2) hash.substring(i, i + 2),
            ].join(':');

            if (kDebugMode) {
              debugPrint('⚠️ تجنب SSL Pinning في وضع التطوير.');
              debugPrint('بصمة السيرفر الحالي هي: $certFingerprint');
              // في وضع التطوير (بيئة localhost)، نسمح بمرور الشهادات غير الموثوقة
              return true;
            }

            // في وضع الإنتاج
            if (host == "go.com" || host == "www.go.com") {
              // تم ضبط الدومين على go.com
              final isValid = certFingerprint == serverFingerprint;
              if (!isValid) {
                debugPrint(
                  '🚨 تنبيه أمني: محاولة هجوم Man-in-the-Middle! البصمة غير مطابقة.',
                );
              }
              return isValid; // لن يعمل الاتصال إلا إذا كانت البصمة متطابقة 100%
            }

            return true;
          };
          return client;
        },
      );
    }
  }

  // Getter for the base URL depending on ApiConfig
  String get baseUrl => ApiConfig.baseUrl;

  /// Extracts the Firebase Token and exchanges it for a Custom Backend JWT.
  Future<bool> syncUserWithBackend() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // 1. استخراج توكن فايربيس المبدئي
      final firebaseToken = await user.getIdToken();
      if (firebaseToken == null) return false;

      // 2. إرسال توكن فايربيس للسيرفر للحصول على Custom JWT
      final response = await _dio.post(
        '/api/auth/login',
        options: Options(headers: {'Authorization': 'Bearer $firebaseToken'}),
      );

      // 3. إذا نجح الدخول، نستلم التوكن الخاص بالسيرفر ونحفظه مشفراً
      if (response.statusCode == 200 && response.data['backendToken'] != null) {
        final backendToken = response.data['backendToken'];
        await SecureStorageService().saveToken(backendToken);

        // Send the request to authenticate with the Node.js backend
        final profileResponse = await _dio.get('/api/user/profile');

        if (profileResponse.statusCode == 200 &&
            profileResponse.data['encryptedPayload'] != null) {
          // فك تشفير البيانات الواردة باستخدام AES-256
          final encryptedData = profileResponse.data['encryptedPayload'];
          final decryptedJson = EncryptionService().decryptJson(encryptedData);

          if (decryptedJson != null) {
            debugPrint(
              'ApiService: Successfully synchronized & decrypted data.',
            );
            // يمكنك استخدام decryptedJson['user'] هنا لحفظ بيانات المستخدم أو عرضها
          } else {
            debugPrint('ApiService: Failed to decrypt payload.');
          }
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badCertificate) {
        debugPrint('🚨 فشل تأكيد الشهادة من SSL Pinning!');
      } else {
        debugPrint('ApiService DioError: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('ApiService Error: $e');
      return false;
    }
  }

  /// Fetches nearby active drivers from the backend
  Future<List<dynamic>> fetchNearbyDrivers() async {
    try {
      final response = await _dio.get('/api/drivers/nearby');

      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);

        if (decryptedJson != null && decryptedJson['drivers'] != null) {
          return List<dynamic>.from(decryptedJson['drivers']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('ApiService fetchNearbyDrivers Error: $e');
      return [];
    }
  }

  /// Fetches the User Profile including live Wallet Balance
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final response = await _dio.get('/api/user/profile');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['user'] != null) {
          return decryptedJson['user'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService fetchUserProfile Error: $e');
      return null;
    }
  }

  /// Updates User Profile
  Future<bool> updateUserProfile(String name, String phone) async {
    try {
      final response = await _dio.put(
        '/api/user/profile',
        data: {'name': name, 'phone': phone},
      );
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService updateUserProfile Error: $e');
      return false;
    }
  }

  /// Initiates a wallet charge via Paymob, returns Paymob logic (Iframe URL)
  Future<String?> initiateWalletCharge(double amount) async {
    try {
      final response = await _dio.post(
        '/api/payment/checkout',
        data: {'amount': amount},
      );

      if (response.statusCode == 200 && response.data['iframeUrl'] != null) {
        return response.data['iframeUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('ApiService initiateWalletCharge Error: $e');
      return null;
    }
  }

  /// Apppy Promo Code
  Future<bool> applyPromoCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/wallet/promo',
        data: {'code': code},
      );
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService applyPromoCode Error: $e');
      return false;
    }
  }

  /// Pay Trip via Wallet
  Future<bool> payTripWithWallet(int tripId) async {
    try {
      final response = await _dio.post('/api/trips/$tripId/pay');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('ApiService payTripWithWallet Error: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('ApiService payTripWithWallet Error: $e');
      return false;
    }
  }

  /// Sends a trip request with pickup and dropoff coordinates and payment method
  Future<Map<String, dynamic>?> requestNewTrip(
    double pLat,
    double pLng,
    double dLat,
    double dLng, {
    String paymentMethod = 'CASH',
  }) async {
    try {
      final response = await _dio.post(
        '/api/trips/request',
        data: {
          'pickupLat': pLat,
          'pickupLng': pLng,
          'dropOffLat': dLat,
          'dropOffLng': dLng,
          'paymentMethod': paymentMethod,
        },
      );

      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['trip'] != null) {
          return decryptedJson['trip'];
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('ApiService requestNewTrip Dio Error: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data['error'] != null) {
        return {'error': e.response?.data['error']};
      }
      return null;
    } catch (e) {
      debugPrint('ApiService requestNewTrip Error: $e');
      return null;
    }
  }

  /// Fetches pending trips for drivers
  Future<List<dynamic>> fetchPendingTrips() async {
    try {
      final response = await _dio.get('/api/trips/pending');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['trips'] != null) {
          return List<dynamic>.from(decryptedJson['trips']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('ApiService fetchPendingTrips Error: $e');
      return [];
    }
  }

  /// Accepts a trip by ID
  Future<bool> acceptTrip(int tripId) async {
    try {
      final response = await _dio.post('/api/trips/$tripId/accept');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        // We can parse the updated trip if needed, but returning true for success is enough here
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('ApiService acceptTrip Error: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('ApiService acceptTrip Error: $e');
      return false;
    }
  }

  /// Fetches trip status and live details
  Future<Map<String, dynamic>?> fetchTripStatus(int tripId) async {
    try {
      final response = await _dio.get('/api/trips/$tripId/status');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['trip'] != null) {
          return decryptedJson['trip'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService fetchTripStatus Error: $e');
      return null;
    }
  }

  /// Updates trip status (Used by Driver)
  Future<bool> updateTripStatus(int tripId, String status) async {
    try {
      final response = await _dio.post(
        '/api/trips/$tripId/update-status',
        data: {'status': status},
      );
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService updateTripStatus Error: $e');
      return false;
    }
  }

  /// Register the current user as a Driver
  Future<bool> registerDriver({
    required String name,
    required String phone,
    required String vehicleType,
    required String plateNumber,
    required String nationalId,
    required String idCardFront,
    required String idCardBack,
  }) async {
    try {
      final response = await _dio.post(
        '/api/drivers/register',
        data: {
          'name': name,
          'phone': phone,
          'vehicleType': vehicleType,
          'plateNumber': plateNumber,
          'nationalId': nationalId,
          'idCardFront': idCardFront,
          'idCardBack': idCardBack,
        },
      );
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService registerAsDriver Error: $e');
      return false;
    }
  }

  /// Fetches messages for a specific trip
  Future<List<dynamic>> fetchTripMessages(int tripId) async {
    try {
      final response = await _dio.get('/api/trips/$tripId/messages');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['messages'] != null) {
          return List<dynamic>.from(decryptedJson['messages']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('ApiService fetchTripMessages Error: $e');
      return [];
    }
  }

  /// Special debug login to bypass Firebase and get a JWT token
  Future<bool> debugLogin() async {
    try {
      final response = await _dio.post('/api/auth/debug-login');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['token'] != null) {
          await SecureStorageService().saveToken(decryptedJson['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('ApiService debugLogin Error: $e');
      return false;
    }
  }

  /// Sends a message inside a trip
  Future<bool> sendTripMessage(int tripId, String content) async {
    try {
      final response = await _dio.post(
        '/api/trips/$tripId/messages',
        data: {'content': content},
      );
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService sendTripMessage Error: $e');
      return false;
    }
  }

  /// Fetches Admin Drivers
  Future<List<dynamic>> fetchAdminDrivers() async {
    try {
      final response = await _dio.get('/api/admin/drivers');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['drivers'] != null) {
          return List<dynamic>.from(decryptedJson['drivers']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('ApiService fetchAdminDrivers Error: $e');
      return [];
    }
  }

  /// Fetches Admin Dashboard Metrics
  Future<Map<String, dynamic>?> fetchAdminMetrics() async {
    try {
      final response = await _dio.get('/api/admin/metrics');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null) {
          return {
            'metrics': decryptedJson['metrics'],
            'recentTrips': decryptedJson['recentTrips'],
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService fetchAdminMetrics Error: $e');
      return null;
    }
  }

  /// Fetches Admin Users
  Future<List<dynamic>> fetchAdminUsers() async {
    try {
      final response = await _dio.get('/api/admin/users');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['users'] != null) {
          return List<dynamic>.from(decryptedJson['users']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('ApiService fetchAdminUsers Error: $e');
      return [];
    }
  }

  /// Fetches Admin Trips
  Future<List<dynamic>> fetchAdminTrips() async {
    try {
      final response = await _dio.get('/api/admin/trips');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['trips'] != null) {
          return List<dynamic>.from(decryptedJson['trips']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('ApiService fetchAdminTrips Error: $e');
      return [];
    }
  }

  /// Fetches Admin Financials
  Future<Map<String, dynamic>?> fetchAdminFinancials() async {
    try {
      final response = await _dio.get('/api/admin/financials');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null) {
          return {
            'payments': decryptedJson['payments'],
            'totalRevenue': decryptedJson['totalRevenue'],
            'totalTransactions': decryptedJson['totalTransactions'],
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService fetchAdminFinancials Error: $e');
      return null;
    }
  }

  /// Fetches Admin Driver Tracking & Active Trip
  Future<Map<String, dynamic>?> fetchAdminDriverTracking(int driverId) async {
    try {
      final response = await _dio.get('/api/admin/drivers/$driverId/tracking');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null) {
          return decryptedJson;
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService fetchAdminDriverTracking Error: $e');
      return null;
    }
  }

  /// Approve Driver (Admin)
  Future<bool> approveDriver(int driverId) async {
    try {
      final response = await _dio.post('/api/admin/drivers/$driverId/approve');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService approveDriver Error: $e');
      return false;
    }
  }

  /// Reject Driver (Admin)
  Future<bool> rejectDriver(int driverId) async {
    try {
      final response = await _dio.post('/api/admin/drivers/$driverId/reject');
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ApiService rejectDriver Error: $e');
      return false;
    }
  }

  /// Estimate Trip Cost
  Future<double?> estimateTripCost(
    double distanceKm, {
    String vehicleType = 'Tricycle',
  }) async {
    try {
      final response = await _dio.get(
        '/api/trips/estimate',
        queryParameters: {'distance': distanceKm, 'vehicleType': vehicleType},
      );
      if (response.statusCode == 200 &&
          response.data['encryptedPayload'] != null) {
        final encryptedData = response.data['encryptedPayload'];
        final decryptedJson = EncryptionService().decryptJson(encryptedData);
        if (decryptedJson != null && decryptedJson['estimatedFare'] != null) {
          return (decryptedJson['estimatedFare'] as num).toDouble();
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService estimateTripCost Error: $e');
      return null;
    }
  }

  /// Send FCM Token to Server
  Future<bool> updateFCMToken(String token) async {
    try {
      final response = await _dio.post(
        '/api/user/fcm-token',
        data: {'fcmToken': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updateFCMToken Error: $e');
      return false;
    }
  }

  /// Update Driver Location
  Future<bool> updateDriverLocation(double lat, double lng) async {
    try {
      final response = await _dio.post(
        '/api/drivers/location',
        data: {'lat': lat, 'lng': lng},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updateDriverLocation Error: $e');
      return false;
    }
  }
}
