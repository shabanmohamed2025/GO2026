import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'trip_chat_sheet.dart';
import '../../../home/presentation/widgets/map_widget.dart';

class ActiveTripScreen extends StatefulWidget {
  final int tripId;
  final bool isDriverMode;

  const ActiveTripScreen({
    super.key,
    required this.tripId,
    this.isDriverMode = false,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  Map<String, dynamic>? _trip;
  bool _isLoading = true;
  Timer? _pollingTimer;
  LatLng? _mapTargetLocation;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    final tripData = await ApiService().fetchTripStatus(widget.tripId);
    if (!mounted) return;
    setState(() {
      _trip = tripData;
      _isLoading = false;
    });
    if (_trip != null) {
      _updateMapViewState();
    }
  }

  void _updateMapViewState() {
    if (_trip == null) return;
    
    // Attempt to center map on the Driver if they are updating location, 
    // otherwise fallback to pickup location.
    double lat = _trip!['pickupLat'];
    double lng = _trip!['pickupLng'];
    
    if (_trip!['driver'] != null && _trip!['driver']['currentLat'] != null) {
      lat = _trip!['driver']['currentLat'];
      lng = _trip!['driver']['currentLng'];
    }

    setState(() {
      _mapTargetLocation = LatLng(lat, lng);
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    final success = await ApiService().updateTripStatus(widget.tripId, newStatus);
    if (!mounted) return;
    Navigator.pop(context); // close loader
    
    if (success) {
      _fetchStatus();
      if (newStatus == 'COMPLETED') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء الرحلة بنجاح!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back home
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في تحديث الحالة'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    
    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isDriverMode ? 'رحلة #${widget.tripId} 🛵' : 'تتبع شحنة #${widget.tripId} 📍', style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: const Center(
          child: Text('عفواً، لا توجد رحلة أو شحنة فعلية متاحة بهذا الرقم.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }

    final double pickupLat = (_trip!['pickupLat'] as num).toDouble();
    final double pickupLng = (_trip!['pickupLng'] as num).toDouble();
    final double dropOffLat = (_trip!['dropOffLat'] as num).toDouble();
    final double dropOffLng = (_trip!['dropOffLng'] as num).toDouble();
    final status = _trip!['status'];

    final Set<Marker> markers = {
      Marker(markerId: const MarkerId('pickup'), position: LatLng(pickupLat, pickupLng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
      Marker(markerId: const MarkerId('dropoff'), position: LatLng(dropOffLat, dropOffLng), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
    };

    if (_trip!['driver'] != null && _trip!['driver']['currentLat'] != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'), 
          position: LatLng(_trip!['driver']['currentLat'], _trip!['driver']['currentLng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'موقع الكابتن')
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriverMode ? 'رحلة #${widget.tripId} 🛵' : 'تتبع شحنة #${widget.tripId} 📍', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          MapWidget(
            targetLocation: _mapTargetLocation ?? LatLng(pickupLat, pickupLng),
            markers: markers,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildControlPanel(status),
          ),
          // Floating Chat Button
          if (status != 'COMPLETED')
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'chat_btn',
                backgroundColor: AppColors.primary,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                      child: TripChatSheet(tripId: widget.tripId),
                    ),
                  );
                },
                child: const Icon(Icons.chat, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(String status) {
    String statusText = '';
    switch(status) {
      case 'ACCEPTED': statusText = 'الكابتن في الطريق إليك'; break;
      case 'IN_PROGRESS': statusText = 'أنت الآن في الرحلة'; break;
      case 'COMPLETED': statusText = 'انتهت الرحلة'; break;
      default: statusText = 'جاري المعالجة...';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,-5))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الطلب: #${widget.tripId}', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(statusText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              Text('${_trip!['fare']?.toStringAsFixed(2) ?? '0.00'} ج.م.', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.isDriverMode) ...[
            if (status == 'ACCEPTED')
              ElevatedButton(
                onPressed: () => _updateStatus('IN_PROGRESS'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('بدء الرحلة (العميل ركب معي)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            if (status == 'IN_PROGRESS')
              ElevatedButton(
                onPressed: () => _updateStatus('COMPLETED'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('إنهاء الرحلة وتحصيل المبلغ نقداً', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
          ] else ...[
            if (status == 'IN_PROGRESS')
              ElevatedButton(
                onPressed: () async {
                  final success = await ApiService().payTripWithWallet(widget.tripId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الدفع بالمحفظة بنجاح وانتهت الرحلة!'), backgroundColor: Colors.green));
                    _fetchStatus();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ أو حدث خطأ.'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('دفع الأجرة من محفظتي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
             if (status != 'IN_PROGRESS' && status != 'COMPLETED')
               const Text('يُرجى الانتظار في الموقع المُحدد لتسهيل وصول الكابتن.', style: TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
