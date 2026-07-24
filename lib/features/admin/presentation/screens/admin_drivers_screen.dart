import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'admin_driver_tracking_screen.dart';

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  List<dynamic> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    final drivers = await ApiService().fetchAdminDrivers();
    if (mounted) {
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('قائمة الكباتن مسجلي النظام', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
              ? const Center(child: Text('لا يوجد كباتن مسجلين بعد.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drivers.length,
                  itemBuilder: (context, index) {
                    final driver = _drivers[index];
                    final user = driver['user'] ?? {};
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name'] ?? 'مستخدم بدون اسم',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      Text(
                                        user['phone'] ?? 'لا يوجد رقم هاتف',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(driver['approvalStatus']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getStatusText(driver['approvalStatus']),
                                        style: TextStyle(
                                          color: _getStatusColor(driver['approvalStatus']),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (driver['isOnline'] == true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        (driver['isOnline'] == true) ? 'متصل الآن' : 'غير متصل',
                                        style: TextStyle(
                                          color: (driver['isOnline'] == true) ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            _buildInfoRow('الرقم القومي:', driver['nationalId'] ?? 'غير مسجل'),
                            const SizedBox(height: 8),
                            _buildInfoRow('نوع المركبة:', driver['vehicleType'] ?? 'تروسيكل'),
                            const SizedBox(height: 8),
                            _buildInfoRow('لوحة المركبة:', driver['plateNumber'] ?? 'غير مسجل'),
                            const SizedBox(height: 8),
                            _buildInfoRow('التقييم:', '⭐ ${driver['rating'] ?? '5.0'}'),
                            const SizedBox(height: 8),
                            _buildInfoRow('الرصيد/الأرباح:', '${driver['walletBalance'] ?? '0.0'} ج.م'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      _showDriverDocuments(context, driver);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                    ),
                                    child: const Text('المستندات'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminDriverTrackingScreen(initialDriver: driver),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('تتبع الكابتن'),
                                  ),
                                ),
                              ],
                            ),
                            if (driver['approvalStatus'] == 'PENDING') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateApprovalStatus(driver['id'], true),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('قبول'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateApprovalStatus(driver['id'], false),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('رفض'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'APPROVED') return Colors.blue;
    if (status == 'REJECTED') return Colors.red;
    return Colors.orange; // PENDING
  }

  String _getStatusText(String? status) {
    if (status == 'APPROVED') return 'مقبول';
    if (status == 'REJECTED') return 'مرفوض';
    return 'قيد المراجعة';
  }

  Future<void> _updateApprovalStatus(int driverId, bool isApprove) async {
    setState(() => _isLoading = true);
    bool success;
    if (isApprove) {
      success = await ApiService().approveDriver(driverId);
    } else {
      success = await ApiService().rejectDriver(driverId);
    }
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isApprove ? 'تم قبول الكابتن بنجاح' : 'تم رفض الكابتن')));
        _fetchDrivers(); // Refresh list
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('حدث خطأ أثناء تعديل حالة الكابتن')));
      }
    }
  }

  void _showDriverDocuments(BuildContext context, Map<String, dynamic> driver) {
    final frontBase64 = driver['idCardFront'];
    final backBase64 = driver['idCardBack'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('المستندات المرفقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (frontBase64 != null) ...[
                  const Text('الوجه الأمامي للبطاقة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: _buildBase64Image(frontBase64),
                  ),
                ] else const Text('الوجه الأمامي غير متوفر'),
                const SizedBox(height: 16),
                if (backBase64 != null) ...[
                  const Text('الوجه الخلفي للبطاقة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: _buildBase64Image(backBase64),
                  ),
                ] else const Text('الوجه الخلفي غير متوفر'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBase64Image(String base64String) {
    try {
      return Image.memory(
        Uri.parse('data:image/jpeg;base64,$base64String').data!.contentAsBytes(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          try {
             return Image.memory(
                base64Decode(base64String),
                fit: BoxFit.contain,
             );
          } catch (e) {
             return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
          }
        },
      );
    } catch (e) {
      return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
