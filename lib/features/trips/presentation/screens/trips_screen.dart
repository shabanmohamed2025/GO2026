import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاويرك', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildTripItem(
            date: '7 أبريل، 04:30 م',
            destination: 'ميدان التحرير، القاهرة',
            price: '45.00 ج.م.',
            status: 'مكتمل',
          ),
          _buildTripItem(
            date: '5 أبريل، 10:15 ص',
            destination: 'سيتي ستارز، مدينة نصر',
            price: '82.50 ج.م.',
            status: 'مكتمل',
          ),
          _buildTripItem(
            date: '2 أبريل، 09:00 م',
            destination: 'المعادي، شارع 9',
            price: '30.00 ج.م.',
            status: 'ملغي',
            isCanceled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTripItem({
    required String date,
    required String destination,
    required String price,
    required String status,
    bool isCanceled = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.directions_car, color: Colors.black),
      ),
      title: Text(destination, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date),
          Text(
            status,
            style: TextStyle(
              color: isCanceled ? Colors.red : Colors.green,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
