import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخصوصية', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildPrivacyItem(
            title: 'مركز الخصوصية',
            subtitle: 'تحكم في خصوصيتك واعرف كيف نستخدم بياناتك.',
          ),
          _buildPrivacyItem(
            title: 'مشاركة الموقع',
            subtitle: 'مفعّل - نشارك موقعك مع السائقين لسهولة الالتقاء.',
          ),
          _buildPrivacyItem(
            title: 'البيانات الشخصية',
            subtitle: 'عرض وتنزيل نسخة من بياناتك لدى GO تروسيكل.',
          ),
          _buildPrivacyItem(
            title: 'حذف الحساب',
            subtitle: 'ابدأ عملية حذف حسابك وبياناتك بشكل نهائي.',
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem({
    required String title,
    required String subtitle,
    bool isDestructive = false,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {},
    );
  }
}
