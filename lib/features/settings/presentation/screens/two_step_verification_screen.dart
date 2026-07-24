import 'package:flutter/material.dart';

class TwoStepVerificationScreen extends StatefulWidget {
  const TwoStepVerificationScreen({super.key});

  @override
  State<TwoStepVerificationScreen> createState() => _TwoStepVerificationScreenState();
}

class _TwoStepVerificationScreenState extends State<TwoStepVerificationScreen> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق بخطوتين', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 60, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'أضف طبقة أمان إضافية',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'عند تفعيل هذه الميزة، سنطلب منك رمزاً إضافياً عند تسجيل الدخول من جهاز جديد لضمان حماية حسابك.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('رسائل SMS القصيرة', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('تلقي رمز التحقق عبر هاتفك المحمول'),
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isEnabled ? 'تم تفعيل التحقق بخطوتين' : 'تم تعطيل التحقق بخطوتين'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
