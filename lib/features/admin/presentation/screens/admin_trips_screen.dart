import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../trips/presentation/screens/active_trip_screen.dart';

class AdminTripsScreen extends StatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  State<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends State<AdminTripsScreen> {
  List<dynamic> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    final trips = await ApiService().fetchAdminTrips();
    if (mounted) {
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل الرحلات', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(child: Text('لا يوجد رحلات بعد.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
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
                          // Allow admin to view trip details (e.g., active trip tracking)
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTripScreen(tripId: trip['id'])));
                        },
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(Icons.route, color: statusColor),
                        ),
                        title: Text('رحلة #${trip['id']} - ${trip['fare'] ?? '0'} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الراكب: ${trip['rider']?['name'] ?? 'مجهول'}\nالكابتن: ${trip['driver']?['user']?['name'] ?? 'لا يوجد'}'),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(status.toString(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
