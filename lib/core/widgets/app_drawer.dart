import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../../features/messages/presentation/screens/messages_screen.dart';
import '../../../features/trips/presentation/screens/trips_screen.dart';
import '../../../features/legal/presentation/screens/legal_screen.dart';
import '../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/profile/presentation/screens/driver_registration_screen.dart';
import '../../../features/trips/presentation/screens/driver_requests_screen.dart';
import '../../../features/admin/presentation/screens/admin_dashboard_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.phoneNumber ?? user?.email ?? 'مستخدم';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            accountName: Text(
              displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Row(
              children: [
                Text('5.0'),
                Icon(Icons.star, color: Colors.white, size: 14),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage:
                  (user?.photoURL != null && user!.photoURL!.startsWith('http'))
                  ? NetworkImage(user.photoURL!)
                  : null,
              child:
                  (user?.photoURL == null ||
                      !user!.photoURL!.startsWith('http'))
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
          ),
          _buildDrawerItem(
            icon: Icons.message,
            title: 'الرسائل',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.wallet,
            title: 'المحفظة',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: 'مشاويرك',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TripsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.map,
            title: 'خريطة مصر',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/egypt_map');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.info,
            title: 'المعلومات القانونية',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LegalScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'الإعدادات',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            onTap: () async {
              Navigator.pop(context);
              // مسح التخزين الآمن محلياً
              await SecureStorageService().deleteAll();
              // مسح جلسة فايربيس
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverRegistrationScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'هل تريد تحقيق أرباح من القيادة؟',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverRequestsScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'لوحة طلبات الكابتن (للعرض)',
                    style: TextStyle(color: Colors.green),
                  ),
                  Spacer(),
                  Icon(Icons.directions_bike, size: 18, color: Colors.green),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                _showAdminPasswordDialog(context);
              },
              child: const Row(
                children: [
                  Text(
                    'لوحة الإدارة (Admin)',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.admin_panel_settings,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    bool hasError = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('دخول الإدارة'),
                ],
              ),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  errorText: hasError ? 'كلمة المرور غير صحيحة' : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.redAccent),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (passwordController.text.trim().toLowerCase() == 'admingo') {
                      // إغلاق نافذة إدخال كلمة المرور
                      Navigator.pop(context);
                      
                      // تفعيل توكن المسؤول حتى تمنح الإدارة صلاحية الوصول في الموبايل
                      await ApiService().debugLogin();

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminDashboardScreen(),
                          ),
                        );
                      }
                    } else {
                      setState(() {
                        hasError = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('دخول'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
