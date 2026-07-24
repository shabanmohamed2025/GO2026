import 'package:flutter/material.dart';
import 'legal_detail_screen.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومات القانونية', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildLegalItem(context, 'حقوق الملكية الفكرية', 'تخضع كافة المحتويات الموجودة في هذا التطبيق لحقوق الملكية الفكرية الخاصة بشركة GO تروسيكل...'),
          _buildLegalItem(context, 'الشروط والأحكام', 'باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بالشروط والأحكام التالية...'),
          _buildLegalItem(context, 'سياسة الخصوصية', 'نحن نولي أهمية كبرى لخصوصية بياناتك. توضح هذه السياسة كيفية جمعنا واستخدامنا لبياناتك...'),
          _buildLegalItem(context, 'إشعارات البرامج مفتوحة المصدر', 'يستخدم هذا التطبيق مجموعة من البرمجيات مفتوحة المصدر التالية...'),
          _buildLegalItem(context, 'معلومات عن GO تروسيكل', 'GO تروسيكل هي منصة تقنية تربط بين الركاب والسائقين لتوفير رحلات آمنة وموثوقة...'),
        ],
      ),
    );
  }

  Widget _buildLegalItem(BuildContext context, String title, String content) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LegalDetailScreen(title: title, content: content),
          ),
        );
      },
    );
  }
}
