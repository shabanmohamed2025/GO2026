import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;

class MapWidget extends StatefulWidget {
  final gmaps.LatLng? targetLocation;
  final Set<gmaps.Marker> markers;
  final Set<gmaps.Polyline> polylines;
  final Function(gmaps.LatLng)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final Function(gmaps.LatLng)? onTap;

  const MapWidget({
    super.key,
    this.targetLocation,
    this.markers = const {},
    this.polylines = const {},
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Completer<gmaps.GoogleMapController> _controllerCompleter = Completer<gmaps.GoogleMapController>();
  final fm.MapController _mapController = fm.MapController();

  static const gmaps.LatLng _initialPosition = gmaps.LatLng(30.0444, 31.2357); // Cairo, Egypt
  static const double _initialZoom = 14.0;

  bool _isDesktopDevice() {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetLocation != null && widget.targetLocation != oldWidget.targetLocation) {
      if (_isDesktopDevice()) {
        try {
          _mapController.move(
            ll.LatLng(widget.targetLocation!.latitude, widget.targetLocation!.longitude),
            14.0,
          );
        } catch (e) {
          debugPrint('MapController error: $e');
        }
      } else {
        _animateToLocation(widget.targetLocation!);
      }
    }
  }

  Future<void> _animateToLocation(gmaps.LatLng location) async {
    final gmaps.GoogleMapController controller = await _controllerCompleter.future;
    controller.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: location, zoom: 16.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktopDevice()) {
      final initialCenter = widget.targetLocation != null
          ? ll.LatLng(widget.targetLocation!.latitude, widget.targetLocation!.longitude)
          : ll.LatLng(_initialPosition.latitude, _initialPosition.longitude);

      return fm.FlutterMap(
        mapController: _mapController,
        options: fm.MapOptions(
          center: initialCenter,
          zoom: _initialZoom,
          maxZoom: 18.0,
          minZoom: 5.0,
          onTap: (tapPosition, point) {
            if (widget.onTap != null) {
              widget.onTap!(gmaps.LatLng(point.latitude, point.longitude));
            }
          },
          onPositionChanged: (position, hasGesture) {
            if (widget.onCameraMove != null && position.center != null) {
              widget.onCameraMove!(gmaps.LatLng(position.center!.latitude, position.center!.longitude));
            }
          },
        ),
        children: [
          fm.TileLayer(
            urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.go.tricycle',
            maxZoom: 18.0,
          ),
          fm.MarkerLayer(
            markers: widget.markers.map((marker) {
              return fm.Marker(
                point: ll.LatLng(marker.position.latitude, marker.position.longitude),
                width: 40,
                height: 40,
                builder: (ctx) => const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.red,
                ),
              );
            }).toList(),
          ),
          if (widget.polylines.isNotEmpty)
            fm.PolylineLayer(
              polylines: widget.polylines.map((poly) {
                return fm.Polyline(
                  points: poly.points.map((p) => ll.LatLng(p.latitude, p.longitude)).toList(),
                  color: poly.color,
                  strokeWidth: poly.width.toDouble(),
                );
              }).toList(),
            ),
        ],
      );
    }

    // Mobile fallback (Google Maps)
    return gmaps.GoogleMap(
      initialCameraPosition: const gmaps.CameraPosition(
        target: _initialPosition,
        zoom: _initialZoom,
      ),
      cameraTargetBounds: gmaps.CameraTargetBounds(
        gmaps.LatLngBounds(
          southwest: const gmaps.LatLng(22.0, 24.7),
          northeast: const gmaps.LatLng(31.6, 36.9),
        ),
      ),
      minMaxZoomPreference: const gmaps.MinMaxZoomPreference(5.0, 18.0),
      onMapCreated: (gmaps.GoogleMapController controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
        if (widget.targetLocation != null) {
          _animateToLocation(widget.targetLocation!);
        }
      },
      markers: widget.markers,
      polylines: widget.polylines,
      onTap: widget.onTap,
      onCameraMove: (position) {
        if (widget.onCameraMove != null) {
          widget.onCameraMove!(position.target);
        }
      },
      onCameraIdle: widget.onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: gmaps.MapType.normal,
    );
  }
}
