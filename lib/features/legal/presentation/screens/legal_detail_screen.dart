import 'package:flutter/material.dart';

class LegalDetailScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDetailScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.6),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
