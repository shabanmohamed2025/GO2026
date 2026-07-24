import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';

class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen> {
  List<dynamic> _pendingTrips = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    // Poll every 10 seconds for new incoming requests
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchRequests());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    final trips = await ApiService().fetchPendingTrips();
    if (mounted) {
      setState(() {
        _pendingTrips = trips;
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptTrip(int tripId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final success = await ApiService().acceptTrip(tripId);
    
    if (!mounted) return;
    Navigator.pop(context); // close dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الرحلة بنجاح! توجه للعميل الآن.'), backgroundColor: Colors.green),
      );
      // Refresh list
      _fetchRequests();
      // Navigate to active trip map screen (TODO)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عفواً، تم قبول الرحلة من سائق آخر أو حدث خطأ.'), backgroundColor: Colors.red),
      );
      _fetchRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الطلبات المتاحة 🛵', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchRequests();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _pendingTrips.isEmpty
              ? _buildEmptyState()
              : _buildRequestsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'جاري البحث عن ركاب...',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'أنت الآن مُتصل، الطلبات ستظهر هنا قريباً.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingTrips.length,
        itemBuilder: (context, index) {
          final trip = _pendingTrips[index];
          final riderName = trip['rider']?['name'] ?? 'راكب محلي';
          final distance = trip['distanceKm'] != null ? '${trip['distanceKm'].toStringAsFixed(1)} كم' : 'مسافة غير محددة';
          final fare = trip['fare'] != null ? '${trip['fare'].toStringAsFixed(2)} ج.م' : 'السعر غير محدد';
          final tripId = trip['id'];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.secondaryBackground,
                            child: Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(riderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  Text(' 5.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(fare, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.route, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text('مسافة الرحلة: $distance', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // تجاهل (مؤقت من الواجهة فقط)
                            setState(() {
                              _pendingTrips.removeAt(index);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('تجاهل'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _acceptTrip(tripId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('قبول ✅', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
