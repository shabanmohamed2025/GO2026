import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class DestinationSearchScreen extends StatefulWidget {
  final bool isPickupSearch;
  const DestinationSearchScreen({super.key, this.isPickupSearch = false});

  @override
  State<DestinationSearchScreen> createState() => _DestinationSearchScreenState();
}

class _DestinationSearchScreenState extends State<DestinationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, dynamic>> _allLocations = [
    {
      'title': 'القاهرة، مصر',
      'subtitle': 'وسط البلد',
      'location': const LatLng(30.0444, 31.2357),
    },
    {
      'title': 'القاهره، مصر', // Variant with Teh Marbuta
      'subtitle': 'وسط مصر',
      'location': const LatLng(30.0444, 31.2357),
    },
    {
      'title': 'الجيزة، مصر',
      'subtitle': 'الأهرامات',
      'location': const LatLng(29.9773, 31.1325),
    },
    {
      'title': 'المعادي، القاهرة',
      'subtitle': 'شارع 9',
      'location': const LatLng(29.9602, 31.2569),
    },
    {
      'title': 'مدينة نصر',
      'subtitle': 'القاهرة',
      'location': const LatLng(30.0609, 31.3397),
    },
    {
      'title': 'التجمع الخامس',
      'subtitle': 'القاهرة الجديدة',
      'location': const LatLng(30.0074, 31.4285),
    },
    {
      'title': 'CAIRO',
      'subtitle': 'Capital City',
      'location': const LatLng(30.0444, 31.2357),
    },
    {
      'title': 'cairo',
      'subtitle': 'lowercase city',
      'location': const LatLng(30.0444, 31.2357),
    },
    {
      'title': 'أبو ظبي',
      'subtitle': 'الإمارات',
      'location': const LatLng(24.4539, 54.3773),
    },
    {
      'title': 'اسوان', // Without Hamza
      'subtitle': 'صعيد مصر',
      'location': const LatLng(24.0889, 32.8998),
    },
  ];

  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = _allLocations;
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _allLocations;
      } else {
        final queryLower = query.toLowerCase();
        
        // Case-insensitive filtering
        var results = _allLocations.where((loc) {
          final String title = (loc['title'] as String).toLowerCase();
          final String subtitle = (loc['subtitle'] as String).toLowerCase();
          return title.contains(queryLower) || subtitle.contains(queryLower);
        }).toList();

        // Ranking Logic (still prioritizes prefix matches)
        results.sort((a, b) {
          final String titleA = (a['title'] as String).toLowerCase();
          final String titleB = (b['title'] as String).toLowerCase();

          if (titleA == queryLower) return -1;
          if (titleB == queryLower) return 1;

          if (titleA.startsWith(queryLower) && !titleB.startsWith(queryLower)) return -1;
          if (!titleA.startsWith(queryLower) && titleB.startsWith(queryLower)) return 1;

          return 0;
        });

        _filteredLocations = results;
      }
    });
  }

  void _selectLocation(Map<String, dynamic> locationData) {
    Navigator.pop(context, {
      'name': locationData['title'],
      'location': locationData['location'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPickupSearch ? 'نقطة الانطلاق' : 'خطط لرحلتك',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterLocations,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    // Usability: Check for best match case-insensitively for quick-select
                    final match = _filteredLocations.firstWhere(
                      (loc) => (loc['title'] as String).toLowerCase() == value.toLowerCase(),
                      orElse: () => <String, dynamic>{},
                    );
                    if (match.isNotEmpty) {
                      _selectLocation(match);
                    } else {
                      Navigator.pop(context, {
                        'action': 'search_on_map',
                        'query': value,
                      });
                    }
                  }
                },
                decoration: InputDecoration(
                  hintText: widget.isPickupSearch ? 'من أين؟' : 'إلى أين؟',
                  border: InputBorder.none,
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        final match = _filteredLocations.firstWhere(
                          (loc) => loc['title'] == _searchController.text,
                          orElse: () => <String, dynamic>{},
                        );
                        if (match.isNotEmpty) {
                          _selectLocation(match);
                        } else {
                          Navigator.pop(context, {
                            'action': 'search_on_map',
                            'query': _searchController.text,
                          });
                        }
                      }
                    },
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.push_pin_outlined, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(context, {'action': 'pick_on_map'});
                    },
                    tooltip: 'تحديد على الخريطة',
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                if (_searchController.text.isEmpty)
                  _buildSearchActionItem(
                    context,
                    icon: Icons.map,
                    title: 'تحديد الموقع على الخريطة',
                    onTap: () {
                      Navigator.pop(context, {'action': 'pick_on_map'});
                    },
                  ),
                if (_searchController.text.isNotEmpty && _filteredLocations.isEmpty)
                  _buildSearchActionItem(
                    context,
                    icon: Icons.search,
                    title: 'بحث عن "${_searchController.text}" في الخريطة',
                    onTap: () {
                      Navigator.pop(context, {
                        'action': 'search_on_map',
                        'query': _searchController.text,
                      });
                    },
                  ),
                const Divider(),
                ..._filteredLocations.map((loc) => _buildLocationItem(
                      context,
                      icon: Icons.location_on,
                      title: loc['title'],
                      subtitle: loc['subtitle'],
                      locationData: loc,
                    )),
                if (_filteredLocations.isEmpty && _searchController.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLocationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Map<String, dynamic> locationData,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.secondaryBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: () => _selectLocation(locationData),
    );
  }
}
