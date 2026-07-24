import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'shipment_tracking_screen.dart';
import 'schedule_selection_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';

class ServicesScreen extends StatelessWidget {
  final VoidCallback? onSwitchToHome;
  const ServicesScreen({super.key, this.onSwitchToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('جميع الخدمات 🌟', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ماذا تحتاج اليوم؟', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('اختر الخدمة المناسبة لك وسنقوم بتوصيلها لك بأسرع وقت.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            
            _buildServiceCategory(context, 'نقل الركاب السريع', Icons.electric_rickshaw, AppColors.primary, [
              _ServiceItem(
                title: 'طلب تروسيكل',
                icon: Icons.two_wheeler,
                onTap: () => _showTricycleFeatures(context),
              ),
              _ServiceItem(
                title: 'حجز مسبق',
                icon: Icons.calendar_month,
                onTap: () async {
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleSelectionScreen()));
                   onSwitchToHome?.call();
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildServiceCategory(context, 'نقل البضائع والمعدات', Icons.local_shipping, Colors.orange, [
              _ServiceItem(
                title: 'نقل عفش كامل',
                icon: Icons.chair,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد موقع الانطلاق والوصول على الخريطة.')));
                  onSwitchToHome?.call();
                },
              ),
              _ServiceItem(
                title: 'شحن بضائع',
                icon: Icons.inventory_2,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد موقع الانطلاق والوصول على الخريطة.')));
                  onSwitchToHome?.call();
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildServiceCategory(context, 'خدمات أخرى', Icons.more_horiz, Colors.blue, [
              _ServiceItem(
                title: 'المحفظة والدفع',
                icon: Icons.account_balance_wallet,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _ServiceItem(
                title: 'تتبع الشحنات',
                icon: Icons.map,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShipmentTrackingScreen())),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategory(BuildContext context, String title, IconData icon, Color color, List<_ServiceItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: items.map((item) => SizedBox(
              width: 140,
              height: 120,
              child: _buildServiceCard(item),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(_ServiceItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showTricycleFeatures(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.two_wheeler, color: AppColors.primary, size: 32),
                    SizedBox(width: 12),
                    Text('طلب تروسيكل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(Icons.location_on, 'تحديد موقع الاستلام والتوصيل.'),
                _buildFeatureItem(Icons.price_check, 'معرفة السعر قبل الرحلة.'),
                _buildFeatureItem(Icons.map, 'تتبع السائق على الخريطة مباشرة.'),
                _buildFeatureItem(Icons.star_rate, 'تقييم السائق والعميل وتجربة آمنة.'),
                _buildFeatureItem(Icons.payment, 'الدفع نقدًا أو إلكترونيًا عبر المحفظة.'),
                _buildFeatureItem(Icons.notifications_active, 'إشعارات فورية بكل جديد.'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                     onPressed: () {
                        Navigator.pop(bottomSheetContext); // Close the bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تحديد الوجهة على الخريطة.')));
                        onSwitchToHome?.call();
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.black,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: const Text('طلب تروسيكل الآن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _ServiceItem({required this.title, required this.icon, required this.onTap});
}
