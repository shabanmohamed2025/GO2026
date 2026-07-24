import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'package:intl/intl.dart';

class AdminFinancialsScreen extends StatefulWidget {
  const AdminFinancialsScreen({super.key});

  @override
  State<AdminFinancialsScreen> createState() => _AdminFinancialsScreenState();
}

class _AdminFinancialsScreenState extends State<AdminFinancialsScreen> {
  Map<String, dynamic>? _financials;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancials();
  }

  Future<void> _fetchFinancials() async {
    final data = await ApiService().fetchAdminFinancials();
    if (mounted) {
      setState(() {
        _financials = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('التقارير المالية', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_financials == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('التقارير المالية', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
        body: const Center(child: Text('خطأ في جلب البيانات المالية.')),
      );
    }

    final payments = _financials!['payments'] as List<dynamic>? ?? [];
    final totalRevenue = _financials!['totalRevenue'] ?? 0;
    final totalTransactions = _financials!['totalTransactions'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير المالية', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Revenue Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي الإيرادات المسجلة', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '$totalRevenue ج.م',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'إجمالي الحركات الناجحة: $totalTransactions',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('سجل الدفع للمحافظ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...payments.map((payment) {
              final dateStr = payment['createdAt'];
              String formattedDate = '';
              if (dateStr != null) {
                try {
                  formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(dateStr).toLocal());
                } catch (_) {}
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: Text(
                    '${payment['amount']} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                  ),
                  subtitle: Text('المستخدم: ${payment['user']?['name'] ?? 'مجهول'}\nتاريخ: $formattedDate'),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('SUCCESS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              );
            }),
            if (payments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('لا توجد تقارير مالية متاحة.'))),
          ],
        ),
      ),
    );
  }
}
