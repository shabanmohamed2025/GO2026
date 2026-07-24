import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main_scaffold.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 100,
                color: AppColors.accent,
              ),
              const SizedBox(height: 32),
              const Text(
                'تم إعداد كل شيء!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'يمكنك الآن البدء في استخدام GO تروسيكل.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScaffold()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBackground,
                    foregroundColor: AppColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('تابع'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
