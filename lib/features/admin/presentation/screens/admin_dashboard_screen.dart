import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../trips/presentation/screens/active_trip_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_users_screen.dart';
import 'admin_trips_screen.dart';
import 'admin_financials_screen.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _metrics;
  List<dynamic> _recentTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await ApiService().fetchAdminMetrics();
    if (mounted) {
      if (data != null) {
        setState(() {
          _metrics = data['metrics'];
          _recentTrips = data['recentTrips'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في جلب بيانات الإدارة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_metrics == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة تحكم الإدارة')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('لا توجد بيانات متاحة، قد لا تملك صلاحيات الوصول.'),
              const SizedBox(height: 16),
              // Add a debug login button for easy troubleshooting
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  final success = await ApiService().debugLogin();
                  if (success) {
                    await _fetchData();
                  } else {
                    setState(() => _isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('فشل تسجيل الدخول كمسؤول')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('تسجيل دخول كمسؤول (تطوير)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة الإدارة والمراقبة 📊', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() => _isLoading = true);
            _fetchData();
          })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('مؤشرات الأداء الرئيسية (KPIs)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.4 : 1.8,
              children: [
                _buildKpiCard('إجمالي المستخدمين', _metrics!['totalUsers'].toString(), Icons.people, Colors.blue, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
                }),
                _buildKpiCard('الكباتن', _metrics!['totalDrivers'].toString(), Icons.two_wheeler, Colors.orange, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDriversScreen()));
                }),
                _buildKpiCard('الرحلات', '${_metrics!['completedTrips']} / ${_metrics!['totalTrips']}', Icons.check_circle, Colors.green, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsScreen()));
                }),
                _buildKpiCard('الأرباح', '${_metrics!['totalRevenue'].toStringAsFixed(0)} ج.م', Icons.attach_money, AppColors.accent, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinancialsScreen()));
                }),
              ],
            ),
            
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('أحدث الرحلات المسجلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsScreen()));
                  }, 
                  child: const Text('عرض الكل', style: TextStyle(color: AppColors.primary))
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._recentTrips.map((trip) {
              final status = trip['status'];
              Color statusColor = Colors.grey;
              if (status == 'COMPLETED') statusColor = Colors.green;
              if (status == 'IN_PROGRESS') statusColor = Colors.blue;
              if (status == 'ACCEPTED') statusColor = Colors.orange;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () {
                    // For debug and monitoring, an admin can click any trip and peek into it
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTripScreen(tripId: trip['id'])));
                  },
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.route, color: statusColor),
                  ),
                  title: Text('رحلة #${trip['id']} - ${trip['fare'] ?? '0'} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('الراكب: ${trip['rider']['name'] ?? 'مجهول'}\nالكابتن: ${trip['driver'] != null ? trip['driver']['user']['name'] : 'لا يوجد'}'),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(status.toString(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              );
            }),
            if (_recentTrips.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد رحلات مسجلة بعد.'))),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تفاصيل $title قادمة قريباً')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
