import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../home/presentation/screens/destination_search_screen.dart';
import 'privacy_screen.dart';
import 'security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _homeAddress;
  String? _workAddress;

  Future<void> _pickAddress(bool isHome) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DestinationSearchScreen()),
    );

    if (result is LatLng) {
      // In a real app, we would reverse geocode the LatLng to an address string.
      // For this demo, we'll use a placeholder address based on the action.
      setState(() {
        if (isHome) {
          _homeAddress = 'موقع المنزل المختار';
        } else {
          _workAddress = 'موقع العمل المختار';
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isHome ? 'تم حفظ عنوان المنزل' : 'تم حفظ عنوان العمل')),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق التطبيق'),
        content: const Text('هل أنت متأكد أنك تريد إغلاق التطبيق بالكامل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop(); // Exit UI
            },
            child: const Text('إغلاق', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(color: Colors.black)),
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
            _buildProfileSection(),
            const Divider(),
            _buildSettingsItem(
              icon: Icons.home,
              title: _homeAddress ?? 'إضافة مكان المنزل',
              subtitle: _homeAddress != null ? 'تغيير العنوان' : null,
              onTap: () => _pickAddress(true),
            ),
            _buildSettingsItem(
              icon: Icons.work,
              title: _workAddress ?? 'إضافة مكان العمل',
              subtitle: _workAddress != null ? 'تغيير العنوان' : null,
              onTap: () => _pickAddress(false),
            ),
            const Divider(),
            _buildSettingsItem(
              icon: Icons.privacy_tip,
              title: 'الخصوصية',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                );
              },
            ),
            _buildSettingsItem(
              icon: Icons.security,
              title: 'الأمان',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecurityScreen()),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              onTap: _showLogoutDialog,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شعبان السمديسي ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '+20 123 456 7890',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }
}
