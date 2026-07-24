import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SeniorsServiceScreen extends StatelessWidget {
  const SeniorsServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خدمة كبار السن', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              color: AppColors.secondaryBackground,
              child: const Icon(Icons.elderly, size: 100, color: AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'رعاية واهتمام في كل مشوار',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'خدمة مخصصة لتوفير الراحة والأمان لكبار السن. نوفر سائقين مدربين على المساعدة في الركوب والنزول، مع سيارات مريحة ووصول سهل.',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureItem(
                    icon: Icons.check_circle,
                    text: 'سائقون متعاونون ومدربون',
                  ),
                  _buildFeatureItem(
                    icon: Icons.check_circle,
                    text: 'مساعدة في حمل الأمتعة',
                  ),
                  _buildFeatureItem(
                    icon: Icons.check_circle,
                    text: 'سيارات واسعة وسهلة الدخول',
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Request senior ride
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('اطلب الآن', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
