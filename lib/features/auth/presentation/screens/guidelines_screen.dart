import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'success_screen.dart';

class GuidelinesScreen extends StatelessWidget {
  const GuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إرشادات المجتمع'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Image.asset(
              'assets/images/tricycle_full.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'نحن نسعى لجعل المجتمع مكاناً آمناً للجميع.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                GuidelineItem(
                  text: 'عامل الجميع بلطف واحترام',
                ),
                GuidelineItem(
                  text: 'ساعد في الحفاظ على سلامة الآخرين',
                ),
                GuidelineItem(
                  text: 'اتبع القوانين واللوائح المحلية',
                ),
                GuidelineItem(
                  text: 'احترم الخصوصية والممتلكات',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SuccessScreen()),
                  );
                },
                child: const Text('أوافق'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuidelineItem extends StatelessWidget {
  final String text;

  const GuidelineItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
      title: Text(text),
    );
  }
}
