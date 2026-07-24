import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class EgyptGeoRepository {
  Future<Map<String, dynamic>> loadGovernorates() async {
    final data = await rootBundle.loadString('assets/geo/egypt_governorates.geojson');
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loadVillages() async {
    final data = await rootBundle.loadString('assets/geo/egypt_villages.geojson');
    return jsonDecode(data) as Map<String, dynamic>;
  }
}
