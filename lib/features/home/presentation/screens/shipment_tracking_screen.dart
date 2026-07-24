import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../trips/presentation/screens/active_trip_screen.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class ShipmentTrackingScreen extends StatefulWidget {
  const ShipmentTrackingScreen({super.key});

  @override
  State<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends State<ShipmentTrackingScreen> {
  final TextEditingController _trackingController = TextEditingController();
  bool _isTracking = false;

  void _startTracking() {
    if (_trackingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الشحنة أولاً')),
      );
      return;
    }
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isTracking = true;
    });
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تتبع الشحنات 📦', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أدخل رقم الشحنة لتتبع تحركاتها:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
              TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: 'مثال: GO-12345678',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  onPressed: () async {
                    String? res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimpleBarcodeScannerPage(),
                      ),
                    );
                    if (res is String && res != '-1') {
                      setState(() {
                         _trackingController.text = res;
                      });
                      _startTracking(); // Automatically track after scan
                    }
                  },
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppColors.primary),
                  onPressed: _startTracking,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onSubmitted: (_) => _startTracking(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _startTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تتبع الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
            
            if (_isTracking)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListView(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('حالة الشحنة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('قيد التوصيل', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTimelineStep(
                        title: 'تم استلام الطلب',
                        subtitle: '10:30 صباحاً - من موقع البائع المعتمد',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        isLast: false,
                        isActive: true,
                      ),
                      _buildTimelineStep(
                        title: 'الطلب في الطريق',
                        subtitle: 'الكابتن محمد متجه إليك\nتروسيكل رقم: أ ب ج 1234',
                        icon: Icons.local_shipping,
                        color: Colors.orange,
                        isLast: false,
                        isActive: true,
                      ),
                      _buildTimelineStep(
                        title: 'تم التوصيل',
                        subtitle: 'في انتظار الوصول للوجهة المحددة',
                        icon: Icons.home,
                        color: Colors.grey,
                        isLast: true,
                        isActive: false,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 45,
                        child: OutlinedButton.icon(
                          onPressed: () {
                             final input = _trackingController.text.trim();
                             int? extractedTripId;
                             if (input.toUpperCase().startsWith('GO-')) {
                                extractedTripId = int.tryParse(input.substring(3));
                             } else {
                                extractedTripId = int.tryParse(input);
                             }
                             
                             if (extractedTripId != null) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTripScreen(tripId: extractedTripId!)));
                             } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الشحنة غير صالح للتبع على الخريطة')));
                             }
                          },
                          icon: const Icon(Icons.map, color: AppColors.primary),
                          label: const Text('تتبع السائق على الخريطة', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('أدخل رقم الشحنة لمعرفة حالتها', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLast,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? color : Colors.grey, size: 24),
            ),
            if (!isLast)
              Container(
                height: 40,
                width: 2,
                color: isActive ? color : Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
