import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/services/api_service.dart';
import '../../../trips/presentation/screens/active_trip_screen.dart';
import '../widgets/map_widget.dart';
import 'destination_search_screen.dart';
import 'schedule_selection_screen.dart';
import 'dart:async';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _selectedLocation;
  String? _destinationName;
  LatLng? _pickupLocation;
  String? _pickupName;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  bool _isPickingOnMap = false;
  LatLng _currentMapCenter = const LatLng(30.0444, 31.2357);
  String _selectedPaymentMethod = 'نقداً';

  double? _estimatedCost;
  bool _isCalculatingCost = false;
  double _walletBalance = 0.0;

  List<dynamic> _drivers = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchDrivers());
    
    // Sync FCM Token
    PushNotificationService().syncFCMToken();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = await ApiService().fetchUserProfile();
    if (mounted && user != null && user['walletBalance'] != null) {
      setState(() {
        _walletBalance = (user['walletBalance'] as num).toDouble();
      });
      if (user['role'] == 'DRIVER') {
        LocationService().startTracking();
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDrivers() async {
    final fetchedDrivers = await ApiService().fetchNearbyDrivers();
    if (mounted) {
      setState(() {
        _drivers = fetchedDrivers;
        // Optionally add them to markers so they appear on the Home screen too!
        _markers.removeWhere((m) => m.markerId.value.startsWith('driver_'));
        for (var d in _drivers) {
          if (d['currentLat'] != null && d['currentLng'] != null) {
            _markers.add(
               Marker(
                 markerId: MarkerId('driver_${d['id']}'),
                 position: LatLng(d['currentLat'], d['currentLng']),
                 icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
               )
            );
          }
        }
      });
    }
  }

  Future<Map<String, dynamic>> _calculateDrivingDistanceAndRoute(double lat1, double lon1, double lat2, double lon2) async {
    try {
      final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$lon1,$lat1;$lon2,$lat2?overview=full');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final distanceMeters = data['routes'][0]['distance'];
          final geometry = data['routes'][0]['geometry'];
          return {'distance': distanceMeters / 1000.0, 'geometry': geometry};
        }
      }
    } catch (e) {
      debugPrint('OSRM routing error: $e');
    }
    // Fallback to straight line (Haversine)
    return {'distance': Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0, 'geometry': null};
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  String? _getNearestDriverInfo() {
    if (_drivers.isEmpty) return null;
    double minDistance = double.infinity;
    for (var d in _drivers) {
      if (d['currentLat'] != null && d['currentLng'] != null) {
        // Use straight line for nearest driver calculation to avoid spamming OSRM
        final dist = Geolocator.distanceBetween(_currentMapCenter.latitude, _currentMapCenter.longitude, d['currentLat'], d['currentLng']) / 1000.0;
        if (dist < minDistance) minDistance = dist;
      }
    }
    if (minDistance == double.infinity) return null;
    return 'أقرب كابتن يبعد ${minDistance.toStringAsFixed(1)} كم';
  }



  void _updateMarkers() {
    setState(() {
      _markers = {};
      if (_pickupLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: _pickupName ?? 'موقع الاستلام'),
          ),
        );
      }
      if (_selectedLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _selectedLocation!,
            infoWindow: InfoWindow(title: _destinationName ?? 'الوجهة'),
          ),
        );
      }
    });
  }

  void _onLocationSelected(LatLng location, String name) {
    setState(() {
      _pickupLocation ??= _currentMapCenter;
      _pickupName ??= 'موقعي الحالي';
      _selectedLocation = location;
      _destinationName = name;
      _isPickingOnMap = false;
      _estimatedCost = null;
      _updateMarkers();
    });
  }

  void _enterPickingMode() {
    setState(() {
      _isPickingOnMap = true;
      _selectedLocation = null;
      _destinationName = null;
      _markers = {};
    });
  }

  Future<void> _confirmPickedLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تحديد العنوان بدقة...'), duration: Duration(seconds: 2)),
    );

    String addressName = 'موقع العميل';
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${_currentMapCenter.latitude}&lon=${_currentMapCenter.longitude}&format=json&accept-language=ar');
      final response = await http.get(url, headers: {'User-Agent': 'com.uber.app'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final addr = data['address'];
          final state = addr['state'] ?? addr['province'] ?? '';
          final county = addr['county'] ?? addr['city_district'] ?? addr['town'] ?? addr['region'] ?? '';
          final village = addr['village'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? addr['quarter'] ?? '';
          final road = addr['road'] ?? '';

          List<String> parts = [];
          if (state.isNotEmpty) parts.add(state);
          // Avoid duplicate or very similar names
          if (county.isNotEmpty && !parts.contains(county) && county != state) parts.add(county);
          if (village.isNotEmpty && !parts.contains(village) && village != county) parts.add(village);
          if (road.isNotEmpty && !parts.contains(road)) parts.add(road);

          if (parts.isNotEmpty) {
            addressName = parts.join('، ');
          }
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }

    _onLocationSelected(_currentMapCenter, addressName);
  }

  Future<void> _handleSearchOnMap(String query) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 15),
            Expanded(child: Text('جاري البحث عن "$query"...')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1&accept-language=ar&countrycodes=eg');
      
      final response = await http.get(url, headers: {'User-Agent': 'com.uber.app'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final result = data.first;
          final lat = double.parse(result['lat'].toString());
          final lon = double.parse(result['lon'].toString());
          final displayName = result['name'] ?? result['display_name'] ?? query;
          
          _onLocationSelected(LatLng(lat, lon), displayName);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error forward geocoding: $e');
    }

    // Fallback if not found
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لم يتم العثور على نتائج دقيقة، جرب البحث باسم حي أو مدينة، أو استخدم الدبوس!')),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedLocation = null;
      _pickupLocation = null;
      _destinationName = null;
      _pickupName = null;
      _estimatedCost = null;
      _markers = {};
      _polylines = {};
      _isPickingOnMap = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _isPickingOnMap ? null : const AppDrawer(),
      appBar: _isPickingOnMap 
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 28),
              onPressed: () => setState(() => _isPickingOnMap = false),
            ),
            title: const Text('حدد الوجهة', style: TextStyle(color: Colors.black)),
          )
        : AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: const Text(
              'GO تروسيكل',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: false,
          ),
      body: Stack(
        children: [
          // Background Map
          Positioned.fill(
            child: MapWidget(
              targetLocation: _selectedLocation,
              markers: _markers,
              polylines: _polylines,
              onTap: (latLng) {
                if (!_isPickingOnMap) {
                  _onLocationSelected(latLng, 'موقع محدد على الخريطة');
                }
              },
              onCameraMove: (pos) {
                _currentMapCenter = pos;
              },
            ),
          ),
          
          // Picking Pin Overlay
          if (_isPickingOnMap)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 35), // Offset to put the tip at the center
                child: Icon(Icons.location_on, size: 50, color: Colors.red),
              ),
            ),

          // Floating Buttons (on the map)
          Positioned(
            top: 100,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!_isPickingOnMap) ...[
                  FloatingActionButton(
                    heroTag: 'map_search',
                    backgroundColor: Colors.white,
                    mini: true,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DestinationSearchScreen()),
                      );
                      if (result is Map<String, dynamic>) {
                        if (result['action'] == 'pick_on_map') {
                          _enterPickingMode();
                        } else if (result['action'] == 'search_on_map') {
                          _handleSearchOnMap(result['query']);
                        } else {
                          _onLocationSelected(result['location'] as LatLng, result['name'] as String);
                        }
                      }
                    },
                    child: const Icon(Icons.search, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'map_pin',
                    backgroundColor: Colors.white,
                    mini: true,
                    onPressed: _enterPickingMode,
                    child: const Icon(Icons.push_pin, color: Colors.black, size: 20),
                  ),
                ],
                if (_isPickingOnMap) ...[
                  FloatingActionButton.extended(
                    heroTag: 'map_confirm',
                    backgroundColor: Colors.black,
                    onPressed: _confirmPickedLocation,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          
          // Bottom Overlay Content
          Align(
            alignment: Alignment.bottomCenter,
            child: _isPickingOnMap 
            ? const SizedBox.shrink()
            : Container(
                height: _selectedLocation == null 
                    ? MediaQuery.of(context).size.height * 0.45
                    : MediaQuery.of(context).size.height * 0.25,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Search Bar Area
                        if (_selectedLocation == null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DestinationSearchScreen()),
                              );
                              if (result is Map<String, dynamic>) {
                                if (result['action'] == 'pick_on_map') {
                                  _enterPickingMode();
                                } else if (result['action'] == 'search_on_map') {
                                  _handleSearchOnMap(result['query']);
                                } else {
                                  _onLocationSelected(result['location'] as LatLng, result['name'] as String);
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search, size: 24),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'إلى أين؟',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(),
                                  const Icon(Icons.schedule, size: 20),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'لاحقاً',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                // Pickup Field
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DestinationSearchScreen(isPickupSearch: true)),
                                    );
                                    if (result is Map<String, dynamic>) {
                                      if (result['action'] == 'pick_on_map') {
                                        // TODO: support pickup on map
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء البحث بالنص حالياً')));
                                      } else if (result['action'] == 'search_on_map') {
                                        // TODO: support pickup search on map
                                      } else {
                                        setState(() {
                                          _pickupLocation = result['location'] as LatLng;
                                          _pickupName = result['name'] as String;
                                          _estimatedCost = null;
                                          _updateMarkers();
                                        });
                                      }
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 12, color: Colors.green),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _pickupName ?? 'موقعي الحالي',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: SizedBox(
                                    height: 24,
                                    child: VerticalDivider(color: Colors.grey, thickness: 1),
                                  ),
                                ),
                                // Destination Field
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DestinationSearchScreen()),
                                    );
                                    if (result is Map<String, dynamic>) {
                                      if (result['action'] == 'pick_on_map') {
                                        _enterPickingMode();
                                      } else if (result['action'] == 'search_on_map') {
                                        _handleSearchOnMap(result['query']);
                                      } else {
                                        _onLocationSelected(result['location'] as LatLng, result['name'] as String);
                                      }
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.square, size: 12, color: Colors.red),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _destinationName ?? 'إلى أين؟',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                        onPressed: _clearSelection,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      
                      if (_selectedLocation == null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'من أجلك',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ServiceCard(
                                title: 'طلب تروسيكل', 
                                icon: Icons.two_wheeler,
                                onTap: _showTricycleFeatures,
                              ),
                              const SizedBox(width: 12),
                              ServiceCard(
                                title: 'احجز', 
                                icon: Icons.calendar_today,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ScheduleSelectionScreen()),
                                ),
                              ),

                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PromoBanner(
                          title: 'إرسل طرد',
                          subtitle: 'توصيل سريع وسهل',
                          icon: Icons.local_shipping,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DestinationSearchScreen()),
                            );
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        if (_estimatedCost != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'التكلفة التقريبية: $_estimatedCost ج.م',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: _showPaymentMethodSelection,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getPaymentIcon(_selectedPaymentMethod), 
                                        color: _getPaymentIconColor(_selectedPaymentMethod), 
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedPaymentMethod, 
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _selectedPaymentMethod == 'نقداً' ? Colors.green : Colors.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.keyboard_arrow_down, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  if (_estimatedCost == null)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: _isCalculatingCost ? null : () async {
                                          setState(() => _isCalculatingCost = true);
                                          final result = await _calculateDrivingDistanceAndRoute(_pickupLocation!.latitude, _pickupLocation!.longitude, _selectedLocation!.latitude, _selectedLocation!.longitude);
                                          final dist = result['distance'] as double;
                                          final cost = await ApiService().estimateTripCost(dist);
                                          if (mounted) {
                                            setState(() {
                                              _estimatedCost = cost;
                                              _isCalculatingCost = false;
                                              if (result['geometry'] != null) {
                                                final points = _decodePolyline(result['geometry'] as String);
                                                _polylines = {
                                                  Polyline(
                                                    polylineId: const PolylineId('route'),
                                                    points: points,
                                                    color: AppColors.primary,
                                                    width: 5,
                                                  )
                                                };
                                              }
                                            });
                                            if (cost == null) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء حساب التكلفة')));
                                            }
                                          }
                                        },
                                        icon: _isCalculatingCost 
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                            : const Icon(Icons.calculate, color: Colors.black),
                                        label: const Text('احسب التكلفة', style: TextStyle(color: Colors.black, fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.secondaryBackground,
                                          side: const BorderSide(color: Colors.black),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  if (_estimatedCost == null)
                                    const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تحديد أقرب كابتن...')));
                                        
                                        String mappedPaymentMethod = _selectedPaymentMethod == 'محفظة التطبيق' ? 'WALLET' : (_selectedPaymentMethod == 'بطاقة ائتمانية' ? 'PAYMOB' : 'CASH');
                                        final tripData = await ApiService().requestNewTrip(
                                          _pickupLocation!.latitude, _pickupLocation!.longitude,
                                          _selectedLocation!.latitude, _selectedLocation!.longitude,
                                          paymentMethod: mappedPaymentMethod
                                        );
                                        
                                        if (mounted) {
                                          if (tripData != null) {
                                            if (tripData.containsKey('error')) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tripData['error']), backgroundColor: Colors.red));
                                            } else {
                                              _clearSelection();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('تم الطلب! ${_getNearestDriverInfo() ?? "جاري البحث عن كباتن"}'), backgroundColor: Colors.green)
                                              );
                                              // Navigate to Active Trip Screen
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => ActiveTripScreen(tripId: tripData['id'])),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الطلب.'), backgroundColor: Colors.red));
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        _estimatedCost != null ? 'تأكيد واطلب' : 'اطلب بدون تسعير', 
                                        style: const TextStyle(color: Colors.white, fontSize: 16)
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختر طريقة الدفع',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentMethodTile(
                  title: 'نقداً',
                  icon: Icons.payments,
                  iconColor: Colors.green,
                  isSelected: _selectedPaymentMethod == 'نقداً',
                ),
                _buildPaymentMethodTile(
                  title: 'بطاقة ائتمانية',
                  icon: Icons.credit_card,
                  iconColor: Colors.blue,
                  isSelected: _selectedPaymentMethod == 'بطاقة ائتمانية',
                ),
                _buildPaymentMethodTile(
                  title: 'محفظة التطبيق',
                  subtitle: 'الرصيد: $_walletBalance ج.م',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppColors.primary,
                  isSelected: _selectedPaymentMethod == 'محفظة التطبيق',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: () {
        setState(() => _selectedPaymentMethod = title);
        Navigator.pop(context);
      },
    );
  }

  void _showTricycleFeatures() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24.0, right: 24.0, top: 24.0,
              ),
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
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildFeatureItem(Icons.location_on, 'تحديد موقع الاستلام والتوصيل.'),
                      _buildFeatureItem(Icons.price_check, 'معرفة السعر قبل الرحلة.'),
                      _buildFeatureItem(Icons.map, 'تتبع السائق على الخريطة مباشرة.'),
                      _buildFeatureItem(Icons.star_rate, 'تقييم السائق والعميل وتجربة آمنة.'),
                      _buildFeatureItem(Icons.payment, 'الدفع نقدًا أو إلكترونيًا عبر المحفظة.'),
                      _buildFeatureItem(Icons.notifications_active, 'إشعارات فورية بكل جديد.'),
                    ],
                  ),
                  const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                     onPressed: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const DestinationSearchScreen())
                        );
                        
                        if (result is Map<String, dynamic>) {
                          if (result['action'] == 'pick_on_map') {
                            _enterPickingMode();
                          } else if (result['action'] == 'search_on_map') {
                            _handleSearchOnMap(result['query']);
                          } else {
                            _onLocationSelected(result['location'] as LatLng, result['name'] as String);
                          }
                        }
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.black,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     child: const Text('طلب تروسيكل الآن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'نقداً':
        return Icons.payments;
      case 'بطاقة ائتمانية':
        return Icons.credit_card;
      case 'المحفظة':
        return Icons.account_balance_wallet;
      default:
        return Icons.payments;
    }
  }

  Color _getPaymentIconColor(String method) {
    switch (method) {
      case 'نقداً':
        return Colors.green;
      case 'بطاقة ائتمانية':
        return Colors.blue;
      case 'المحفظة':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String? imagePath;
  final IconData? icon;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.title,
    this.imagePath,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, height: 50, fit: BoxFit.contain)
            else if (icon != null)
              Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final IconData? icon;
  final VoidCallback? onTap;

  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: 150,
          child: Stack(
        children: [
          if (imagePath != null)
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.asset(imagePath!, fit: BoxFit.cover, width: 200),
              ),
            )
          else if (icon != null)
            Positioned(
              left: 20,
              bottom: 25,
              child: Icon(icon, size: 100, color: Colors.grey.withOpacity(0.3)),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
