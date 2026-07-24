import 'package:flutter/foundation.dart';

/// إعدادات الـ IP ورابط السيرفر للمشروع في مكان واحد مخصص
class ApiConfig {
  // 1. عنوان IP المحلي للكمبيوتر في شبكة الواي فاي
  static String serverIp = '10.125.41.170';
  
  // 2. منفذ السيرفر (Port)
  static int serverPort = 8080;

  // 3. الرابط الرسمي المباشر والشغال للمشروع (HTTPS Tunnel)
  static String? customServerUrl = null;

  /// الحصول على الرابط المناسب تلقائياً حسب نوع الجهاز (موبايل/كمبيوتر/ويب)
  static String get baseUrl {
    if (customServerUrl != null && customServerUrl!.trim().isNotEmpty) {
      return customServerUrl!.trim();
    }
    if (kIsWeb) return 'http://127.0.0.1:$serverPort';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$serverIp:$serverPort';
    }
    return 'http://127.0.0.1:$serverPort';
  }
}
