import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_colors.dart';
import 'guidelines_screen.dart';

class PasskeyScreen extends StatelessWidget {
  const PasskeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.accent.withOpacity(0.1),
              child: const Icon(
                Icons.fingerprint,
                size: 60,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'سجّل الدخول بشكل أسرع باستخدام مفتاح مرور',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تستخدم مفاتيح المرور بصمة الإصبع أو الوجه أو قفل الشاشة لإثبات هويتك بطريقة آمنة وسهلة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  bool didAuthenticate = false;
                  try {
                    final LocalAuthentication auth = LocalAuthentication();
                    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
                    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
                    
                    if (canAuthenticate) {
                      didAuthenticate = await auth.authenticate(
                        localizedReason: 'يرجى المصادقة بالبصمة لتفعيل مفتاح المرور والدخول السريع مستقبلاً',
                        biometricOnly: false,
                        persistAcrossBackgrounding: true,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جهازك لا يدعم المصادقة بالبصمة حالياً.')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: $e')),
                      );
                    }
                  }

                  if (didAuthenticate && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إنشاء مفتاح المرور وتفعيل الدخول السريع بنجاح!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GuidelinesScreen()),
                    );
                  }
                },
                child: const Text(
                  'إنشاء مفتاح مرور',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GuidelinesScreen()),
                  );
              },
              child: const Text(
                'ليس الآن',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
