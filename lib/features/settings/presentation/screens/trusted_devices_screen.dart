import 'package:flutter/material.dart';

class TrustedDevicesScreen extends StatefulWidget {
  const TrustedDevicesScreen({super.key});

  @override
  State<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends State<TrustedDevicesScreen> {
  final List<Map<String, String>> _devices = [
    {
      'name': 'iPhone 13 (هذا الجهاز)',
      'location': 'القاهرة، مصر',
      'lastActive': 'نشط الآن',
    },
    {
      'name': 'Windows PC - Chrome',
      'location': 'الجيزة، مصر',
      'lastActive': 'منذ يومين',
    },
    {
      'name': 'Samsung Galaxy S21',
      'location': 'الإسكندرية، مصر',
      'lastActive': 'منذ أسبوع',
    },
  ];

  void _removeDevice(int index) {
    setState(() {
      _devices.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إزالة الجهاز بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة الموثوقة', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _devices.isEmpty
          ? const Center(child: Text('لا توجد أجهزة أخرى مسجلة'))
          : ListView.separated(
              itemCount: _devices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final device = _devices[index];
                final bool isCurrent = device['name']!.contains('هذا الجهاز');
                
                return ListTile(
                  leading: Icon(
                    device['name']!.contains('iPhone') || device['name']!.contains('Samsung')
                        ? Icons.phone_android
                        : Icons.computer,
                    color: isCurrent ? Colors.green : Colors.black,
                  ),
                  title: Text(device['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${device['location']} • ${device['lastActive']}'),
                  trailing: isCurrent
                      ? null
                      : TextButton(
                          onPressed: () => _removeDevice(index),
                          child: const Text('إزالة', style: TextStyle(color: Colors.red)),
                        ),
                );
              },
            ),
    );
  }
}
