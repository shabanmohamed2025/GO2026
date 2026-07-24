import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/theme/app_colors.dart';
import 'otp_verification_screen.dart';
import 'email_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import '../../../../core/services/api_service.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phoneNumber = '';
  bool _isLoading = false;

  void _verifyPhoneNumber(String phoneNumber) async {
    setState(() {
      _isLoading = true;
    });

    // Check if running on Windows desktop
    if (defaultTargetPlatform == TargetPlatform.windows) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('تنبيه النظام'),
              ],
            ),
            content: const Text(
              'تسجيل الدخول عبر رقم الهاتف (Firebase SMS) مدعوم فقط على أجهزة Android و iOS.\n\n'
              'يرجى تشغيل التطبيق على محاكي أو جهاز حقيقي لتجربة تسجيل الدخول وإرسال الرسائل.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          // Sync with Node.js
          final syncSuccess = await ApiService().syncUserWithBackend();
          
          if (mounted) {
            if (!syncSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('فشل الاتصال بالخادم الرئيسي! تأكد من الـ IP.'), backgroundColor: Colors.red),
              );
              await FirebaseAuth.instance.signOut();
              return;
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          String errorMsg;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg = 'رقم الهاتف غير صحيح. تأكد من الصيغة الدولية مثل: +201234567890';
              break;
            case 'too-many-requests':
              errorMsg = 'تم تجاوز الحد المسموح من المحاولات. حاول مرة أخرى لاحقاً.';
              break;
            case 'quota-exceeded':
              errorMsg = 'تم تجاوز الحصة اليومية. حاول غداً.';
              break;
            default:
              errorMsg = 'فشل إرسال رمز التحقق: ${e.message}';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم إرسال الرمز بنجاح مع Firebase SMS!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ غير متوقع: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    // Check if running on Windows desktop
    if (defaultTargetPlatform == TargetPlatform.windows) {
      try {
        final result = await DesktopWebviewAuth.signIn(
          GoogleSignInArgs(
            clientId: '381146946885-jpj4qcmlnnt6il1c3euh33r95dut61f6.apps.googleusercontent.com',
            redirectUri: 'http://localhost',
          ),
        );

        if (result == null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: result.accessToken,
          idToken: result.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        // Sync with Node.js
        final syncSuccess = await ApiService().syncUserWithBackend();

        if (mounted) {
          if (!syncSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فشل الاتصال بالخادم الرئيسي!'), backgroundColor: Colors.red),
            );
            await FirebaseAuth.instance.signOut();
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تسجيل الدخول من ويندوز: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      return;
    }

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId: '381146946885-3r6mh2tdi6j5hc2hbntvf1f4lps1tdj7.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      // Sync with Node.js
      final syncSuccess = await ApiService().syncUserWithBackend();

      if (mounted) {
        if (!syncSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل الاتصال بالخادم الرئيسي!'), backgroundColor: Colors.red),
          );
          await FirebaseAuth.instance.signOut();
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تسجيل الدخول بجوجل: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            },
            child: const Text(
              'تخطي',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل رقم هاتفك الجوّال',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            IntlPhoneField(
              decoration: const InputDecoration(
                hintText: 'رقم الهاتف',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                fillColor: AppColors.background,
              ),
              initialCountryCode: 'EG',
              languageCode: 'ar',
              onChanged: (phone) {
                _phoneNumber = phone.completeNumber;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_phoneNumber.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء إدخال رقم هاتف صحيح')),
                          );
                          return;
                        }
                        _verifyPhoneNumber(_phoneNumber);
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تابع'),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('أو'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            SocialLoginButton(
              icon: Icons.g_mobiledata,
              text: 'Google',
              onPressed: _isLoading ? () {} : _signInWithGoogle,
            ),
            const SizedBox(height: 12),
            SocialLoginButton(
              icon: Icons.email_outlined,
              text: 'البريد الإلكتروني',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EmailLoginScreen()),
                );
              },
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await ApiService().debugLogin();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.developer_mode, color: Colors.orange),
                  label: const Text(
                    'تخطي تسجيل الدخول (Debug)',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: AppColors.primary),
                  label: const Text(
                    'ابحث عن حسابي',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.secondaryBackground,
          side: BorderSide.none,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
