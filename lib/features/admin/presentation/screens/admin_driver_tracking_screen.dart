import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../home/presentation/widgets/map_widget.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';

class AdminDriverTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> initialDriver;

  const AdminDriverTrackingScreen({super.key, required this.initialDriver});

  @override
  State<AdminDriverTrackingScreen> createState() => _AdminDriverTrackingScreenState();
}

class _AdminDriverTrackingScreenState extends State<AdminDriverTrackingScreen> {
  Map<String, dynamic>? _driver;
  Map<String, dynamic>? _activeTrip;
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _driver = widget.initialDriver;
    _fetchTrackingInfo();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchTrackingInfo());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrackingInfo() async {
    final data = await ApiService().fetchAdminDriverTracking(widget.initialDriver['id']);
    if (mounted && data != null) {
      setState(() {
        _driver = data['driver'];
        _activeTrip = data['activeTrip'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('جاري التحميل...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final double? lat = _driver!['currentLat'] != null ? double.tryParse(_driver!['currentLat'].toString()) : null;
    final double? lng = _driver!['currentLng'] != null ? double.tryParse(_driver!['currentLng'].toString()) : null;
    final hasLocation = lat != null && lng != null;

    final targetLocation = hasLocation ? LatLng(lat, lng) : null;
    
    // Build Markers
    final Set<Marker> markers = {};
    if (hasLocation) {
      markers.add(
        Marker(
          markerId: MarkerId('driver_${_driver!['id']}'),
          position: targetLocation!,
          infoWindow: InfoWindow(
            title: _driver!['user']?['name'] ?? 'كابتن',
            snippet: _driver!['vehicleType'] ?? 'تروسيكل',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        )
      );
    }

    // Build Polylines & Additional Markers for Active Trip
    final Set<Polyline> polylines = {};
    if (_activeTrip != null) {
      final double? pickupLat = _activeTrip!['pickupLat'] != null ? double.tryParse(_activeTrip!['pickupLat'].toString()) : null;
      final double? pickupLng = _activeTrip!['pickupLng'] != null ? double.tryParse(_activeTrip!['pickupLng'].toString()) : null;
      final double? dropOffLat = _activeTrip!['dropOffLat'] != null ? double.tryParse(_activeTrip!['dropOffLat'].toString()) : null;
      final double? dropOffLng = _activeTrip!['dropOffLng'] != null ? double.tryParse(_activeTrip!['dropOffLng'].toString()) : null;

      if (pickupLat != null && pickupLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat, pickupLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }

      if (dropOffLat != null && dropOffLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(dropOffLat, dropOffLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }

      // Draw Path (Driver -> Pickup -> Dropoff depends on status, but simply connecting them serves the MVP tracking well)
      final List<LatLng> points = [];
      if (hasLocation) points.add(targetLocation!);
      if (pickupLat != null && pickupLng != null) points.add(LatLng(pickupLat, pickupLng));
      if (dropOffLat != null && dropOffLng != null) points.add(LatLng(dropOffLat, dropOffLng));

      if (points.length > 1) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('driver_path'),
            points: points,
            color: AppColors.primary,
            width: 5,
          )
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('تتبع الكابتن: ${_driver!['user']?['name'] ?? ''}', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          hasLocation
            ? Positioned.fill(
                child: MapWidget(
                  targetLocation: targetLocation,
                  markers: markers,
                  polylines: polylines,
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('موقع الكابتن غير متوفر حالياً', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  ],
                ),
              ),
          if (_activeTrip != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'في رحلة حالياً (${_activeTrip!['status'] == 'ACCEPTED' ? 'متجه للعميل' : 'في الطريق للوجهة'})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
