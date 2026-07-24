import 'package:flutter/material.dart';
import 'two_step_verification_screen.dart';
import 'change_password_screen.dart';
import 'trusted_devices_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأمان', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSecurityItem(
            context,
            title: 'التحقق بخطوتين',
            subtitle: 'أضف طبقة أمان إضافية لحسابك باستخدام رسائل SMS.',
            icon: Icons.app_registration,
          ),
          _buildSecurityItem(
            context,
            title: 'تغيير كلمة المرور',
            subtitle: 'قم بتحديث كلمة المرور الخاصة بك بانتظام.',
            icon: Icons.password,
          ),
          _buildSecurityItem(
            context,
            title: 'الأجهزة الموثوقة',
            subtitle: 'إدارة الأجهزة التي سجلت الدخول منها مؤخراً.',
            icon: Icons.devices,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        Widget screen;
        if (title == 'التحقق بخطوتين') {
          screen = const TwoStepVerificationScreen();
        } else if (title == 'تغيير كلمة المرور') {
          screen = const ChangePasswordScreen();
        } else if (title == 'الأجهزة الموثوقة') {
          screen = const TrustedDevicesScreen();
        } else {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}
