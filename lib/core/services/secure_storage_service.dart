import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';

class SecureStorageService {
  // تصميم (Singleton) لضمان عدم إنشاء أكثر من نسخة من الكلاس في الرام
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  // إعداد الكائن الخاص بالتخزين الآمن
  final FlutterSecureStorage _storage;

  SecureStorageService._internal()
      : _storage = const FlutterSecureStorage(
          // إعدادات خاصة لأجهزة Android لضمان استخدام نظام التشفير المتقدم (EncryptedSharedPreferences)
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          // إعدادات خاصة لأجهزة iOS لضمان إمكانية قراءة القيم بعد إعادة التشغيل مباشرة
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // Memory fallback for Windows and Web where flutter_secure_storage might fail or not be supported yet
  final Map<String, String> _memoryStorage = {};

  /// ----------------------------------------
  /// دوال التعامل مع التوكن (Token)
  /// ----------------------------------------
  
  // حفظ التوكن
  Future<void> saveToken(String token) async {
    try {
      final encryptedToken = EncryptionService().encryptData(token);
      if (kIsWeb) {
        _memoryStorage['auth_token'] = encryptedToken;
      } else {
        await _storage.write(key: 'auth_token', value: encryptedToken);
        _memoryStorage['auth_token'] = encryptedToken; // Cache it in memory too
      }
    } catch (e) {
      _memoryStorage['auth_token'] = EncryptionService().encryptData(token);
    }
  }

  // استرجاع التوكن
  Future<String?> getToken() async {
    try {
      String? encryptedToken;
      if (kIsWeb) {
        encryptedToken = _memoryStorage['auth_token'];
      } else {
        encryptedToken = await _storage.read(key: 'auth_token');
        if (encryptedToken != null) _memoryStorage['auth_token'] = encryptedToken;
        encryptedToken ??= _memoryStorage['auth_token'];
      }
      
      if (encryptedToken != null) {
        return EncryptionService().decryptData(encryptedToken);
      }
      return null;
    } catch (e) {
      final cached = _memoryStorage['auth_token'];
      return cached != null ? EncryptionService().decryptData(cached) : null;
    }
  }

  // مسح التوكن (عند تسجيل الخروج)
  Future<void> deleteToken() async {
    try {
      _memoryStorage.remove('auth_token');
      if (!kIsWeb) {
        await _storage.delete(key: 'auth_token');
      }
    } catch (e) {
      // Ignored
    }
  }

  /// ----------------------------------------
  /// دوال التعامل مع بيانات المستخدم
  /// ----------------------------------------
  
  // حفظ بيانات المستخدم (يمكنك تمرير JSON String)
  Future<void> saveUserData(String userData) async {
    final encryptedData = EncryptionService().encryptData(userData);
    await _storage.write(key: 'user_data', value: encryptedData);
  }

  // استرجاع بيانات المستخدم
  Future<String?> getUserData() async {
    final encryptedData = await _storage.read(key: 'user_data');
    if (encryptedData != null) {
      return EncryptionService().decryptData(encryptedData);
    }
    return null;
  }

  // مسح بيانات المستخدم
  Future<void> deleteUserData() async {
    await _storage.delete(key: 'user_data');
  }

  /// ----------------------------------------
  /// دوال عامة (General Functions)
  /// ----------------------------------------

  // تخزين أي قيمة نصية مفردة بناءً على مفتاح (Key)
  Future<void> writeData({required String key, required String value}) async {
    final encryptedValue = EncryptionService().encryptData(value);
    await _storage.write(key: key, value: encryptedValue);
  }

  // استرجاع أي قيمة نصية بناءً على المفتاح
  Future<String?> readData({required String key}) async {
    final encryptedValue = await _storage.read(key: key);
    if (encryptedValue != null) {
      return EncryptionService().decryptData(encryptedValue);
    }
    return null;
  }

  // مسح جميع البيانات المخزنة من التخزين الآمن بالكامل
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
