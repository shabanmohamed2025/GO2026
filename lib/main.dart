import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'widgets/egypt_map.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/push_notification_service.dart';

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'core/widgets/jailbreak_alert_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ Dotenv load error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully for project: go-shaban');

    // Initialize Push Notifications
    await PushNotificationService().initialize();
  } catch (e) {
    print('⚠️ Firebase init error (fallback mode active): $e');
  }

  bool jailbroken = false;
  // الفحص يعمل فقط على أنظمة الموبايل المدعومة لتفادي أخطاء الويندوز أو الويب
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      jailbroken = await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      print('⚠️ Jailbreak detection error: $e');
    }
  }

  runApp(TricycleGoApp(isJailbroken: jailbroken));
}

class TricycleGoApp extends StatelessWidget {
  final bool isJailbroken;
  const TricycleGoApp({super.key, required this.isJailbroken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تروسيكل GO',
      debugShowCheckedModeBanner: false,
        routes: {
          '/egypt_map': (context) => const EgyptMapScreen(),
        },
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'EG'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG')],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: isJailbroken ? const JailbreakAlertScreen() : const LoginScreen(),
      ),
    );
  }
}
