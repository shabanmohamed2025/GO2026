import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'dart:async';
import 'dart:math' as math;
import '../core/services/api_service.dart';
import '../core/theme/app_colors.dart';

class Governorate {
  final String name;
  final double latitude;
  final double longitude;
  final String details;

  const Governorate({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.details,
  });
}

const List<Governorate> egyptGovernorates = [
  Governorate(
    name: 'القاهرة',
    latitude: 30.0444,
    longitude: 31.2358,
    details: 'عاصمة جمهورية مصر العربية وأكبر مدنها، وتشتهر بتاريخها العريق ومعالمها الإسلامية والقبطية.',
  ),
  Governorate(
    name: 'الجيزة',
    latitude: 29.9870,
    longitude: 31.2118,
    details: 'تقع على الضفة الغربية لنهر النيل وتضم أهم الآثار المصرية القديمة مثل أهرامات الجيزة وأبو الهول.',
  ),
  Governorate(
    name: 'الإسكندرية',
    latitude: 31.1975,
    longitude: 29.8925,
    details: 'العاصمة الثانية لمصر وعروس البحر الأبيض المتوسط، وتشتهر بمكتبتها العريقة وقلعة قايتباي وشواطئها الجميلة.',
  ),
  Governorate(
    name: 'القليوبية',
    latitude: 30.4667,
    longitude: 31.1833,
    details: 'تقع في جنوب الدلتا وتشتهر بالزراعة وخاصة الموالح والقناطر الخيرية التاريخية.',
  ),
  Governorate(
    name: 'الدقهلية',
    latitude: 31.0500,
    longitude: 31.3833,
    details: 'تقع في الدلتا وعاصمتها المنصورة، وتشتهر بكونها مركزاً طبياً وتعليمياً رائداً في مصر.',
  ),
  Governorate(
    name: 'الغربية',
    latitude: 30.7833,
    longitude: 31.0000,
    details: 'تقع في قلب الدلتا وعاصمتها طنطا، وتشتهر بوجود مسجد السيد البدوي وصناعة الغزل والنسيج في المحلة الكبرى.',
  ),
  Governorate(
    name: 'المنوفية',
    latitude: 30.5500,
    longitude: 31.0000,
    details: 'تقع في الدلتا وتشتهر بالزراعة والتعليم، ويُعرف أهلها بحبهم الشديد للعلم والمعرفة.',
  ),
  Governorate(
    name: 'دمياط',
    latitude: 31.4167,
    longitude: 31.8167,
    details: 'مدينة ساحلية تشتهر بصناعة الأثاث الفاخر والحلويات وتضم ميناء دمياط الهام ورأس البر.',
  ),
  Governorate(
    name: 'كفر الشيخ',
    latitude: 31.1167,
    longitude: 30.8333,
    details: 'تقع شمال مصر وتطل على البحر المتوسط، وتشتهر بالزراعة وصيد الأسماك وبحيرة البرلس.',
  ),
  Governorate(
    name: 'البحيرة',
    latitude: 31.0333,
    longitude: 30.4667,
    details: 'من أكبر المحافظات الزراعية في مصر وتضم مدناً هامة مثل دمنهور ورشيد التاريخية.',
  ),
  Governorate(
    name: 'الشرقية',
    latitude: 30.5833,
    longitude: 31.5000,
    details: 'تقع شرق الدلتا وعاصمتها الزقازيق، وتشتهر بتربية الخيول العربية الأصيلة والزراعة الكثيفة.',
  ),
  Governorate(
    name: 'بورسعيد',
    latitude: 31.2625,
    longitude: 32.3061,
    details: 'مدينة ساحلية تقع عند المدخل الشمالي لقناة السويس وتشتهر بنظام المنطقة الحرة والتجارة وشواطئها الجميلة.',
  ),
  Governorate(
    name: 'الإسماعيلية',
    latitude: 30.5965,
    longitude: 32.2715,
    details: 'تقع على قناة السويس وتشتهر بزراعة المانجو الاسماعيلاوي المتميز والحدائق والمسطحات الخضراء الشاسعة.',
  ),
  Governorate(
    name: 'السويس',
    latitude: 29.9667,
    longitude: 32.5333,
    details: 'تقع عند المدخل الجنوبي لقناة السويس وتشتهر بتاريخها النضالي ومينائها التجاري وصيد الأسماك.',
  ),
  Governorate(
    name: 'الفيوم',
    latitude: 29.3090,
    longitude: 30.8423,
    details: 'واحة طبيعية مميزة تضم بحيرة قارون ووادي الريان وشلالاته البديعة وتشتهر بتاريخها الزراعي الممتد.',
  ),
  Governorate(
    name: 'بني سويف',
    latitude: 29.0733,
    longitude: 31.0970,
    details: 'بوابة الصعيد وتشتهر بالزراعة والصناعة وتضم هرم ميدوم الأثري الشهير.',
  ),
  Governorate(
    name: 'المنيا',
    latitude: 28.1000,
    longitude: 30.7500,
    details: 'عروس الصعيد وتعتبر متحفاً مفتوحاً يضم العديد من المواقع الأثرية الهامة من العصور الفرعونية واليونانية الرومانية.',
  ),
  Governorate(
    name: 'أسيوط',
    latitude: 27.1809,
    longitude: 31.1837,
    details: 'العاصمة التجارية والتاريخية للصعيد وتضم جامعة أسيوط العريقة والعديد من الأديرة الأثرية والأماكن الفرعونية.',
  ),
  Governorate(
    name: 'سوهاج',
    latitude: 26.5591,
    longitude: 31.6957,
    details: 'تقع في جنوب الصعيد وتضم معالم أثرية هامة مثل معبد أبيدوس ومتحف سوهاج القومي وتشتهر بصناعة النسيج اليدوي.',
  ),
  Governorate(
    name: 'قنا',
    latitude: 26.1648,
    longitude: 32.7261,
    details: 'محافظة عريقة بصعيد مصر تضم معبد دندرة الشهير المخصص للإلهة حتحور وتشتهر بزراعة قصب السكر.',
  ),
  Governorate(
    name: 'الأقصر',
    latitude: 25.6872,
    longitude: 32.6396,
    details: 'عاصمة السياحة العالمية وتضم ثلث آثار العالم مثل معبد الكرنك، معبد الأقصر، ووادي الملوك والملكات.',
  ),
  Governorate(
    name: 'أسوان',
    latitude: 24.0889,
    longitude: 32.8998,
    details: 'تقع في أقصى جنوب مصر وتتميز بالطبيعة النوبية الخلابة وتضم السد العالي، معبد فيلة، ومعبد أبو سمبل الشهير.',
  ),
  Governorate(
    name: 'مطروح',
    latitude: 31.3543,
    longitude: 27.2373,
    details: 'محافظة حدودية ساحلية تضم واحة سيوة التاريخية وشواطئ مرسى مطروح ذات المياه الفيروزية الساحرة.',
  ),
  Governorate(
    name: 'الوادي الجديد',
    latitude: 25.4373,
    longitude: 30.5463,
    details: 'أكبر محافظات مصر مساحة وتقع في الصحراء الغربية وتضم الواحات الخارجة والداخلة والفرافرة وتتميز بالآثار الفرعونية والعيون الكبريتية.',
  ),
  Governorate(
    name: 'البحر الأحمر',
    latitude: 27.2579,
    longitude: 33.8116,
    details: 'محافظة ساحلية تمتد على شاطئ البحر الأحمر وتضم مدناً سياحية عالمية مثل الغردقة وسهل حشيش ومرسى علم وتشتهر بالشعاب المرجانية الساحرة.',
  ),
  Governorate(
    name: 'شمال سيناء',
    latitude: 31.1316,
    longitude: 33.8013,
    details: 'تقع في الجزء الشمالي الشرقي لمصر وتطلب على البحر المتوسط وتشتهر بزراعة الزيتون واللوز وثرواتها الطبيعية.',
  ),
  Governorate(
    name: 'جنوب سيناء',
    latitude: 28.2412,
    longitude: 33.6212,
    details: 'تضم معالم دينية وسياحية بارزة مثل جبل موسى ودير سانت كاترين ومدينة شرم الشيخ العالمية ومحمية رأس محمد.',
  ),
];

class EgyptMapScreen extends StatefulWidget {
  const EgyptMapScreen({super.key});

  @override
  State<EgyptMapScreen> createState() => _EgyptMapScreenState();
}

class _EgyptMapScreenState extends State<EgyptMapScreen> {
  gmaps.GoogleMapController? _controller;
  final fm.MapController _mapController = fm.MapController();
  Governorate? _selectedGovernorate;
  
  ll.LatLng? _pickupLocation;
  ll.LatLng? _dropoffLocation;
  
  List<dynamic> _drivers = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    // جلب المواقع كل 15 ثانية كأنه Real-Time
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchDrivers();
    });
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
      });
    }
  }

  // Haversine formula to get distance between two latlng points in Km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
              math.cos(lat1 * p) * math.cos(lat2 * p) * 
              (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a));
  }

  String? _getNearestDriverInfo() {
    if (_pickupLocation == null || _drivers.isEmpty) return null;
    
    double minDistance = double.infinity;
    for (var d in _drivers) {
      if (d['currentLat'] != null && d['currentLng'] != null) {
        final dist = _calculateDistance(
          _pickupLocation!.latitude, _pickupLocation!.longitude,
          d['currentLat'], d['currentLng']
        );
        if (dist < minDistance) minDistance = dist;
      }
    }
    
    if (minDistance == double.infinity) return null;
    int estimatedMinutes = (minDistance * 2).ceil(); // Rough estimate: 2 mins per km
    return 'أقرب كابتن يبعد عن موقعك ${minDistance.toStringAsFixed(1)} كم (مقدار $estimatedMinutes دقيقة تقريباً)';
  }

  void _onMapLongPress(double lat, double lng) {
    setState(() {
      if (_pickupLocation == null) {
        _pickupLocation = ll.LatLng(lat, lng);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديد نقطة الركوب! اضغط مطولاً مجدداً لتحديد الوجهة.')));
      } else if (_dropoffLocation == null) {
        _dropoffLocation = ll.LatLng(lat, lng);
        _showTripConfirmationPanel();
      } else {
        // Reset if both are selected
        _pickupLocation = ll.LatLng(lat, lng);
        _dropoffLocation = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إعادة التحديد: نقطة ركوب جديدة.')));
      }
    });
  }

  void _showTripConfirmationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _buildTripSheet(ctx),
    );
  }

  Widget _buildTripSheet(BuildContext ctx) {
    bool isRequesting = false;
    return StatefulBuilder(builder: (context, setModalState) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تأكيد مسار الرحلة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            if (_getNearestDriverInfo() != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getNearestDriverInfo()!, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
            const Text('تم تحديد نقطتي الانطلاق والوصول على الخريطة بنجاح.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isRequesting ? null : () async {
                  setModalState(() => isRequesting = true);
                  final trip = await ApiService().requestNewTrip(
                    _pickupLocation!.latitude, _pickupLocation!.longitude,
                    _dropoffLocation!.latitude, _dropoffLocation!.longitude
                  );
                  setModalState(() => isRequesting = false);

                  if (!mounted) return;
                  Navigator.pop(ctx);

                  if (trip != null) {
                    final fare = trip['fare']?.toStringAsFixed(2) ?? '0.00';
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('تم تأكيد الطلب! الفاتورة المتوقعة: $fare ج.م.'), backgroundColor: Colors.green, duration: const Duration(seconds: 4)),
                    );
                    setState(() {
                      _pickupLocation = null;
                      _dropoffLocation = null;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في طلب الرحلة.'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isRequesting ? const CircularProgressIndicator(color: Colors.white) : const Text('اطلب GO تروسيكل الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  void _onMapTapped(double lat, double lng) {
    if (egyptGovernorates.isEmpty) return;

    Governorate closest = egyptGovernorates.first;
    double minDistanceSq = double.infinity;
    for (var gov in egyptGovernorates) {
      final distanceSq = (gov.latitude - lat) * (gov.latitude - lat) + (gov.longitude - lng) * (gov.longitude - lng);
      if (distanceSq < minDistanceSq) {
        minDistanceSq = distanceSq;
        closest = gov;
      }
    }

    setState(() {
      _selectedGovernorate = closest;
    });

    // Zoom and center the camera on the tapped governorate
    final isDesktop = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.macOS ||
            Theme.of(context).platform == TargetPlatform.linux);

    if (isDesktop) {
      _mapController.move(ll.LatLng(closest.latitude, closest.longitude), 9.5);
    } else {
      _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(closest.latitude, closest.longitude),
          9.5,
        ),
      );
    }

    _showGovernorateInfo(closest);
  }

  void _showGovernorateInfo(Governorate gov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.accent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    gov.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                gov.details,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'موافق',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb &&
        (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.macOS ||
            Theme.of(context).platform == TargetPlatform.linux);

    final Set<gmaps.Marker> googleMarkers = {};
    if (_selectedGovernorate != null) {
      googleMarkers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('selected_gov'),
        position: gmaps.LatLng(_selectedGovernorate!.latitude, _selectedGovernorate!.longitude),
        infoWindow: gmaps.InfoWindow(title: _selectedGovernorate!.name),
      ));
    }

    // إضافة السائقين للـ Google Map
    for (var driver in _drivers) {
      final double lat = (driver['currentLat'] as num).toDouble();
      final double lng = (driver['currentLng'] as num).toDouble();
      final id = driver['id'].toString();
      final rating = driver['rating'].toString();

      googleMarkers.add(gmaps.Marker(
        markerId: gmaps.MarkerId('driver_$id'),
        position: gmaps.LatLng(lat, lng),
        infoWindow: gmaps.InfoWindow(title: 'سائق تروسيكل', snippet: 'تقييم: $rating'),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange),
      ));
    }
    
    if (_pickupLocation != null) {
      googleMarkers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('pickup'),
        position: gmaps.LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
      ));
    }
    if (_dropoffLocation != null) {
      googleMarkers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('dropoff'),
        position: gmaps.LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة مصر'),
        centerTitle: true,
      ),
      body: isDesktop
          ? EgyptMapFallback(
              selectedGovernorate: _selectedGovernorate,
              onTap: _onMapTapped,
              onLongPress: _onMapLongPress,
              mapController: _mapController,
              drivers: _drivers,
              pickupLoc: _pickupLocation,
              dropoffLoc: _dropoffLocation,
            )
          : gmaps.GoogleMap(
              initialCameraPosition: const gmaps.CameraPosition(
                target: gmaps.LatLng(26.8206, 30.8025),
                zoom: 5.5,
              ),
              markers: googleMarkers,
              onTap: (latLng) => _onMapTapped(latLng.latitude, latLng.longitude),
              onLongPress: (latLng) => _onMapLongPress(latLng.latitude, latLng.longitude),
              onMapCreated: (controller) => _controller = controller,
              myLocationEnabled: false,
            ),
    );
  }
}

class EgyptMapFallback extends StatelessWidget {
  final Governorate? selectedGovernorate;
  final Function(double, double) onTap;
  final Function(double, double) onLongPress;
  final fm.MapController mapController;
  final List<dynamic> drivers;
  final ll.LatLng? pickupLoc;
  final ll.LatLng? dropoffLoc;

  const EgyptMapFallback({
    super.key,
    required this.selectedGovernorate,
    required this.onTap,
    required this.onLongPress,
    required this.mapController,
    this.drivers = const [],
    this.pickupLoc,
    this.dropoffLoc,
  });

  @override
  Widget build(BuildContext context) {
    final initialCenter = selectedGovernorate != null
        ? ll.LatLng(selectedGovernorate!.latitude, selectedGovernorate!.longitude)
        : const ll.LatLng(26.8206, 30.8025);

    return Stack(
      children: [
        fm.FlutterMap(
          mapController: mapController,
          options: fm.MapOptions(
            center: initialCenter,
            zoom: 6.5,
            minZoom: 4.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              onTap(point.latitude, point.longitude);
            },
            onLongPress: (tapPosition, point) {
              onLongPress(point.latitude, point.longitude);
            },
          ),
          children: [
            fm.TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.go.tricycle',
            ),
            if (selectedGovernorate != null)
              fm.MarkerLayer(
                markers: [
                  fm.Marker(
                    point: ll.LatLng(selectedGovernorate!.latitude, selectedGovernorate!.longitude),
                    width: 140,
                    height: 85,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            selectedGovernorate!.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          size: 36,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (drivers.isNotEmpty)
              fm.MarkerLayer(
                markers: drivers.map((d) {
                  return fm.Marker(
                    point: ll.LatLng((d['currentLat'] as num).toDouble(), (d['currentLng'] as num).toDouble()),
                    width: 40,
                    height: 40,
                    builder: (context) => const Icon(
                      Icons.two_wheeler,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  );
                }).toList(),
              ),
              if (pickupLoc != null)
                fm.MarkerLayer(
                  markers: [
                    fm.Marker(
                      point: pickupLoc!,
                      width: 40,
                      height: 40,
                      builder: (context) => const Icon(Icons.location_on, color: Colors.green, size: 40),
                    )
                  ]
                ),
              if (dropoffLoc != null)
                fm.MarkerLayer(
                  markers: [
                    fm.Marker(
                      point: dropoffLoc!,
                      width: 40,
                      height: 40,
                      builder: (context) => const Icon(Icons.location_on, color: Colors.red, size: 40),
                    )
                  ]
                ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'اضغط مطولاً لتحديد موقع الركوب والنزول',
                  style: TextStyle(
                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
