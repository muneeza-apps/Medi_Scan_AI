import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/models/clinic_recommendation_model.dart';
import '../../../../core/services/clinic_locator_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/patient_profile_service.dart';

class NearbyClinicsPage extends StatefulWidget {
  final String cityName;
  final List<ClinicRecommendation>? clinics;
  final Position? position;

  const NearbyClinicsPage({
    super.key,
    required this.cityName,
    this.clinics,
    this.position,
  });

  @override
  State<NearbyClinicsPage> createState() => _NearbyClinicsPageState();
}

class _NearbyClinicsPageState extends State<NearbyClinicsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ClinicRecommendation> _allClinics = [];
  bool _isLoading = false;
  String _selectedDistanceFilter = 'all';
  String _searchQuery = '';
  late String _activeArea;
  double _searchRadiusMeters = 25000;
  Position? _currentPos;

  @override
  void initState() {
    super.initState();
    _activeArea = widget.cityName.trim().isNotEmpty
        ? widget.cityName.trim()
        : PatientProfileService.profile.city;
    _currentPos = widget.position;

    if (widget.clinics != null && widget.clinics!.isNotEmpty) {
      _allClinics = List<ClinicRecommendation>.from(widget.clinics!);
    }
    _loadNearbyClinics(radiusMeters: 25000);
  }

  Future<void> _loadNearbyClinics({double radiusMeters = 25000}) async {
    setState(() {
      _isLoading = true;
      _searchRadiusMeters = radiusMeters;
    });

    try {
      Position? pos = _currentPos;
      if (pos == null) {
        pos = await LocationService.instance.getCurrentCoordinates();
        _currentPos = pos;
      }

      if (pos != null) {
        final area = await LocationService.instance.resolveDistrictOrTown(
          pos.latitude,
          pos.longitude,
        );
        if (area.isNotEmpty && mounted) {
          _activeArea = area;
        }

        final results = await ClinicLocatorService.getNearbyClinics(
          pos.latitude,
          pos.longitude,
          radiusMeters: radiusMeters,
        );

        if (mounted) {
          setState(() {
            _allClinics = results;
            _isLoading = false;
          });
        }
      } else {

        final results = ClinicLocatorService.getOfflineCachedClinics(31.4239, 73.0845);
        if (mounted) {
          setState(() {
            _allClinics = results;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        final results = ClinicLocatorService.getOfflineCachedClinics(31.4239, 73.0845);
        setState(() {
          _allClinics = results;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClinicRecommendation> _getFilteredClinics() {
    return _allClinics.where((clinic) {
      final matchesQuery = _searchQuery.isEmpty ||
          clinic.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          clinic.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          clinic.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          clinic.city.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      final dist = clinic.distanceKm ?? 999999.0;
      if (_selectedDistanceFilter == 'under_5') {
        return dist <= 5.0;
      } else if (_selectedDistanceFilter == 'under_15') {
        return dist <= 15.0;
      } else if (_selectedDistanceFilter == 'under_25') {
        return dist <= 25.0;
      } else if (_selectedDistanceFilter == 'under_50') {
        return dist <= 50.0;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';
        final filteredClinics = _getFilteredClinics();

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                isUrdu
                    ? '$_activeArea کے قریبی طبی مراکز'
                    : 'Healthcare Near $_activeArea',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                ),
              ),
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                        decoration: InputDecoration(
                          hintText: isUrdu
                              ? 'ہسپتال، کلینک یا علاقہ تلاش کریں...'
                              : 'Search hospital, clinic, or area...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF00796B),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F4F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text(isUrdu ? 'تمام' : 'All'),
                              selected: _selectedDistanceFilter == 'all',
                              onSelected: (_) {
                                setState(() => _selectedDistanceFilter = 'all');
                              },
                              selectedColor: const Color(0xFF80CBC4),
                              checkmarkColor: const Color(0xFF004D40),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(
                                isUrdu ? '5 کلومیٹر کے اندر' : 'Under 5 km',
                              ),
                              selected: _selectedDistanceFilter == 'under_5',
                              onSelected: (_) {
                                setState(
                                  () => _selectedDistanceFilter = 'under_5',
                                );
                              },
                              selectedColor: const Color(0xFF80CBC4),
                              checkmarkColor: const Color(0xFF004D40),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(
                                isUrdu ? '15 کلومیٹر کے اندر' : 'Under 15 km',
                              ),
                              selected: _selectedDistanceFilter == 'under_15',
                              onSelected: (_) {
                                setState(
                                  () => _selectedDistanceFilter = 'under_15',
                                );
                              },
                              selectedColor: const Color(0xFF80CBC4),
                              checkmarkColor: const Color(0xFF004D40),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text(
                                isUrdu ? '25 کلومیٹر کے اندر' : 'Under 25 km',
                              ),
                              selected: _selectedDistanceFilter == 'under_25',
                              onSelected: (_) {
                                setState(
                                  () => _selectedDistanceFilter = 'under_25',
                                );
                              },
                              selectedColor: const Color(0xFF80CBC4),
                              checkmarkColor: const Color(0xFF004D40),
                            ),
                            if (_searchRadiusMeters >= 50000) ...[
                              const SizedBox(width: 8),
                              FilterChip(
                                label: Text(
                                  isUrdu ? '50 کلومیٹر کے اندر' : 'Under 50 km',
                                ),
                                selected: _selectedDistanceFilter == 'under_50',
                                onSelected: (_) {
                                  setState(
                                    () => _selectedDistanceFilter = 'under_50',
                                  );
                                },
                                selectedColor: const Color(0xFF80CBC4),
                                checkmarkColor: const Color(0xFF004D40),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF004D40),
                          ),
                        )
                      : _allClinics.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.amber.shade300,
                                      width: 1.2,
                                    ),
                                  ),
                                  color: Colors.amber.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.radar_rounded,
                                          size: 48,
                                          color: Colors.amber.shade900,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isUrdu
                                              ? '25 کلومیٹر کے اندر کوئی طبی مرکز نہیں ملا'
                                              : 'No clinics found within 25 km',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.5,
                                            color: Colors.amber.shade900,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isUrdu
                                              ? 'تلاش کا دائرہ بڑھا کر 50 کلومیٹر تک قریبی ہسپتال تلاش کریں۔'
                                              : 'No healthcare centers found within 25 km. Expanding search radius...',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey.shade800,
                                            height: 1.35,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF004D40),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.travel_explore_rounded,
                                            size: 18,
                                          ),
                                          label: Text(
                                            isUrdu
                                                ? '50 کلومیٹر تک تلاش کریں'
                                                : 'Search Up to 50 km',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          onPressed: () => _loadNearbyClinics(
                                            radiusMeters: 50000,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : filteredClinics.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.location_off_outlined,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          isUrdu
                                              ? 'کوئی کلینک نہیں ملا'
                                              : 'No Clinics Found',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF004D40),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUrdu
                                              ? 'فلٹر تبدیل کریں یا مختلف الفاظ سے تلاش کریں'
                                              : 'Try adjusting distance filters or search query',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filteredClinics.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final clinic = filteredClinics[index];
                                    return _buildClinicListItem(clinic, isUrdu);
                                  },
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClinicListItem(ClinicRecommendation clinic, bool isUrdu) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade100, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clinic.specialty,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF80CBC4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    clinic.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (clinic.distanceKm != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 13,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrdu
                          ? '${clinic.distanceKm!.toStringAsFixed(1)} کلومیٹر دور'
                          : '${clinic.distanceKm!.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isUrdu ? 'طبی سہولت' : 'Healthcare',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ),
                const Spacer(),
                if (clinic.contactNumber.trim().isNotEmpty) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF004D40),
                      side: const BorderSide(color: Color(0xFF00796B)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 15),
                    label: Text(
                      isUrdu ? 'کال کریں' : 'Call',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        ClinicLocatorService.launchDialer(clinic.contactNumber),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 15),
                  label: Text(
                    isUrdu ? 'راستہ دیکھیں' : 'Get Directions',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => ClinicLocatorService.launchDirections(
                    latitude: clinic.latitude,
                    longitude: clinic.longitude,
                    clinicName: clinic.name,
                    mapsUrl: clinic.mapsUrl,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
