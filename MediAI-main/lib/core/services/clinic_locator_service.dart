import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/clinic_recommendation_model.dart';
import 'location_service.dart';

class ClinicLocatorService {
  ClinicLocatorService._();

  static final Dio _dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent': 'MediAI/1.0 (Contact: healthcare-triage@mediai.org)',
      },
      connectTimeout: const Duration(milliseconds: 3000),
      receiveTimeout: const Duration(milliseconds: 3000),
    ),
  );

  static const List<ClinicRecommendation> defaultPakistaniMedicalCenters = [

    ClinicRecommendation(
      id: 'pk_med_allied_fsd',
      name: 'Allied Hospital Faisalabad',
      specialty: 'Dermatology & Tertiary Medical Center',
      address: 'Jail Road, Allied Mor, Faisalabad, Punjab',
      city: 'Faisalabad',
      rating: 4.8,
      contactNumber: '0419210082',
      latitude: 31.4385,
      longitude: 73.0768,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.4385,73.0768',
    ),
    ClinicRecommendation(
      id: 'pk_med_dhq_fsd',
      name: 'DHQ Hospital Faisalabad',
      specialty: 'District Headquarter Hospital & Dermatology Clinic',
      address: 'Mall Road, Civil Lines, Faisalabad, Punjab',
      city: 'Faisalabad',
      rating: 4.6,
      contactNumber: '0419200371',
      latitude: 31.4239,
      longitude: 73.0845,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.4239,73.0845',
    ),
    ClinicRecommendation(
      id: 'pk_med_thq_fsd',
      name: 'THQ Hospital Samundri',
      specialty: 'Tehsil Headquarter Hospital & Primary Dermatology',
      address: 'Gojra Road, Samundri, District Faisalabad',
      city: 'Samundri',
      rating: 4.5,
      contactNumber: '0413421250',
      latitude: 31.0631,
      longitude: 72.9553,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.0631,72.9553',
    ),
    ClinicRecommendation(
      id: 'pk_med_fic_fsd',
      name: 'Faisalabad Institute of Cardiology & Emergency Care',
      specialty: 'Cardiovascular & Emergency Medicine',
      address: 'Civil Lines, Club Road, Faisalabad',
      city: 'Faisalabad',
      rating: 4.9,
      contactNumber: '0419201527',
      latitude: 31.4190,
      longitude: 73.0780,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.4190,73.0780',
    ),

    ClinicRecommendation(
      id: 'pk_med_mayo_lhr',
      name: 'Mayo Hospital (KEMU) Lahore',
      specialty: 'Dermatology Department & Tertiary Hospital',
      address: 'Hospital Road, Anarkali Bazaar, Lahore, Punjab',
      city: 'Lahore',
      rating: 4.9,
      contactNumber: '04299211100',
      latitude: 31.5726,
      longitude: 74.3168,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.5726,74.3168',
    ),
    ClinicRecommendation(
      id: 'pk_med_jinnah_lhr',
      name: 'Jinnah Hospital Lahore',
      specialty: 'Clinical Dermatology & Burn Center',
      address: 'Usmani Road, Faisal Town, Lahore, Punjab',
      city: 'Lahore',
      rating: 4.7,
      contactNumber: '04299231400',
      latitude: 31.4837,
      longitude: 74.2952,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.4837,74.2952',
    ),
    ClinicRecommendation(
      id: 'pk_med_services_lhr',
      name: 'Services Hospital Lahore',
      specialty: 'Department of Dermatology & Inpatient Care',
      address: 'Ghaus-ul-Azam Road, Shadman 1, Lahore, Punjab',
      city: 'Lahore',
      rating: 4.7,
      contactNumber: '04299203402',
      latitude: 31.5398,
      longitude: 74.3331,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.5398,74.3331',
    ),
    ClinicRecommendation(
      id: 'pk_med_gangaram_lhr',
      name: 'Sir Ganga Ram Hospital',
      specialty: 'Dermatology & Cutaneous Surgery',
      address: 'Queen\'s Road, Jubilee Town, Lahore, Punjab',
      city: 'Lahore',
      rating: 4.6,
      contactNumber: '04299203761',
      latitude: 31.5529,
      longitude: 74.3184,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=31.5529,74.3184',
    ),

    ClinicRecommendation(
      id: 'pk_med_pims_isb',
      name: 'Pakistan Institute of Medical Sciences (PIMS)',
      specialty: 'Dermatology Unit & Federal Tertiary Care',
      address: 'Sector G-8/3, Islamabad',
      city: 'Islamabad',
      rating: 4.8,
      contactNumber: '0519261170',
      latitude: 33.7058,
      longitude: 73.0456,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=33.7058,73.0456',
    ),
    ClinicRecommendation(
      id: 'pk_med_holy_family_rwp',
      name: 'Holy Family Hospital Rawalpindi',
      specialty: 'Dermatology Clinic & Teaching Hospital',
      address: 'Holy Family Road, Satellite Town, Rawalpindi',
      city: 'Rawalpindi',
      rating: 4.6,
      contactNumber: '0519290321',
      latitude: 33.6358,
      longitude: 73.0674,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=33.6358,73.0674',
    ),
    ClinicRecommendation(
      id: 'pk_med_dhq_rwp',
      name: 'DHQ Hospital Rawalpindi',
      specialty: 'District Headquarter Hospital',
      address: 'Kashmir Road, Rawalpindi Cantonment',
      city: 'Rawalpindi',
      rating: 4.5,
      contactNumber: '0515556311',
      latitude: 33.5975,
      longitude: 73.0543,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=33.5975,73.0543',
    ),

    ClinicRecommendation(
      id: 'pk_med_jpmc_khi',
      name: 'Jinnah Postgraduate Medical Centre (JPMC)',
      specialty: 'Dermatology Department & Trauma Center',
      address: 'Rafiqui Shaheed Road, Karachi, Sindh',
      city: 'Karachi',
      rating: 4.8,
      contactNumber: '02199201300',
      latitude: 24.8524,
      longitude: 67.0452,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=24.8524,67.0452',
    ),
    ClinicRecommendation(
      id: 'pk_med_civil_khi',
      name: 'Dr. Ruth K.M. Pfau Civil Hospital Karachi',
      specialty: 'Dermatology & Skin Infectious Disease Center',
      address: 'Mission Road, New Chali, Karachi, Sindh',
      city: 'Karachi',
      rating: 4.7,
      contactNumber: '02199215740',
      latitude: 24.8596,
      longitude: 67.0104,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=24.8596,67.0104',
    ),
    ClinicRecommendation(
      id: 'pk_med_dhq_hyd',
      name: 'Liaquat University Hospital (Civil / DHQ) Hyderabad',
      specialty: 'Dermatology & Tertiary Medical Care',
      address: 'Hospital Road, Saddar, Hyderabad, Sindh',
      city: 'Hyderabad',
      rating: 4.6,
      contactNumber: '0229210207',
      latitude: 25.3960,
      longitude: 68.3718,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=25.3960,68.3718',
    ),

    ClinicRecommendation(
      id: 'pk_med_nishtar_mul',
      name: 'Nishtar Hospital Multan',
      specialty: 'Department of Dermatology & Burn Unit',
      address: 'Nishtar Road, Multan, Punjab',
      city: 'Multan',
      rating: 4.8,
      contactNumber: '0619200231',
      latitude: 30.1984,
      longitude: 71.4402,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=30.1984,71.4402',
    ),
    ClinicRecommendation(
      id: 'pk_med_dhq_mul',
      name: 'DHQ Hospital Multan',
      specialty: 'District Headquarter Hospital & Skin Outpatient',
      address: 'Shamsabad, Multan, Punjab',
      city: 'Multan',
      rating: 4.5,
      contactNumber: '0619200781',
      latitude: 30.2091,
      longitude: 71.4682,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=30.2091,71.4682',
    ),

    ClinicRecommendation(
      id: 'pk_med_lrh_pew',
      name: 'Lady Reading Hospital (LRH) Peshawar',
      specialty: 'Dermatology Center & Tertiary Emergency Care',
      address: 'Soekarno Road, Pipal Mandi, Peshawar, KP',
      city: 'Peshawar',
      rating: 4.8,
      contactNumber: '0919211430',
      latitude: 34.0105,
      longitude: 71.5673,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=34.0105,71.5673',
    ),
    ClinicRecommendation(
      id: 'pk_med_kth_pew',
      name: 'Khyber Teaching Hospital (KTH)',
      specialty: 'Department of Dermatology & Academic Medical Center',
      address: 'University Road, Peshawar, KP',
      city: 'Peshawar',
      rating: 4.7,
      contactNumber: '0919224400',
      latitude: 33.9981,
      longitude: 71.4872,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=33.9981,71.4872',
    ),

    ClinicRecommendation(
      id: 'pk_med_bmc_qta',
      name: 'Bolan Medical Complex Hospital Quetta',
      specialty: 'Dermatology & Provincial Tertiary Care',
      address: 'Brewery Road, Quetta, Balochistan',
      city: 'Quetta',
      rating: 4.6,
      contactNumber: '0819213031',
      latitude: 30.1798,
      longitude: 66.9754,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=30.1798,66.9754',
    ),
    ClinicRecommendation(
      id: 'pk_med_civil_qta',
      name: 'Sandeman Provincial Hospital (Civil / DHQ) Quetta',
      specialty: 'District & Provincial Healthcare Facility',
      address: 'Jinnah Road, Quetta, Balochistan',
      city: 'Quetta',
      rating: 4.5,
      contactNumber: '0819202022',
      latitude: 30.1920,
      longitude: 67.0110,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=30.1920,67.0110',
    ),

    ClinicRecommendation(
      id: 'pk_med_dhq_grw',
      name: 'DHQ Teaching Hospital Gujranwala',
      specialty: 'Dermatology Department & Emergency Care',
      address: 'Civil Lines, Gujranwala, Punjab',
      city: 'Gujranwala',
      rating: 4.6,
      contactNumber: '0559200421',
      latitude: 32.1617,
      longitude: 74.1883,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=32.1617,74.1883',
    ),
    ClinicRecommendation(
      id: 'pk_med_allama_skt',
      name: 'Allama Iqbal Memorial Teaching Hospital (DHQ) Sialkot',
      specialty: 'District Headquarter & Dermatology Clinic',
      address: 'Commissioner Road, Sialkot, Punjab',
      city: 'Sialkot',
      rating: 4.6,
      contactNumber: '0529250011',
      latitude: 32.4945,
      longitude: 74.5229,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=32.4945,74.5229',
    ),
    ClinicRecommendation(
      id: 'pk_med_dhq_sgd',
      name: 'DHQ Teaching Hospital Sargodha',
      specialty: 'Dermatology & District Tertiary Care',
      address: 'Club Road, Sargodha, Punjab',
      city: 'Sargodha',
      rating: 4.6,
      contactNumber: '0489230551',
      latitude: 32.0836,
      longitude: 72.6711,
      mapsUrl: 'https://www.google.com/maps/search/?api=1&query=32.0836,72.6711',
    ),
  ];

  static List<ClinicRecommendation> getOfflineCachedClinics(
    double lat,
    double lng, {
    double radiusMeters = 250000,
  }) {
    final List<ClinicRecommendation> computed = [];

    for (final clinic in defaultPakistaniMedicalCenters) {
      final distanceMeters = Geolocator.distanceBetween(
        lat,
        lng,
        clinic.latitude,
        clinic.longitude,
      );
      final distanceKm =
          double.parse((distanceMeters / 1000.0).toStringAsFixed(1));

      computed.add(
        ClinicRecommendation(
          id: clinic.id,
          name: clinic.name,
          specialty: clinic.specialty,
          address: clinic.address,
          city: clinic.city,
          rating: clinic.rating,
          contactNumber: clinic.contactNumber,
          latitude: clinic.latitude,
          longitude: clinic.longitude,
          mapsUrl: clinic.mapsUrl,
          distanceKm: distanceKm,
        ),
      );
    }

    computed.sort(
      (a, b) => (a.distanceKm ?? 0.0).compareTo(b.distanceKm ?? 0.0),
    );
    return computed;
  }

  static Future<List<ClinicRecommendation>> getNearbyClinics(
    double lat,
    double lng, {
    double radiusMeters = 25000,
    Dio? dioClient,
    bool forceOfflineOnly = false,
  }) async {

    final offlineClinics = getOfflineCachedClinics(lat, lng);

    if (forceOfflineOnly) {
      return offlineClinics;
    }

    final client = dioClient ?? _dio;
    final radius = radiusMeters.toInt();
    final query = '''
[out:json][timeout:3];
(
  node["amenity"~"hospital|clinic|doctors"](around:$radius,$lat,$lng);
  way["amenity"~"hospital|clinic|doctors"](around:$radius,$lat,$lng);
);
out center tags;
''';

    dynamic data;
    try {
      final response = await client.post<dynamic>(
        'https://overpass-api.de/api/interpreter',
        data: 'data=${Uri.encodeQueryComponent(query)}',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );
      data = response.data;
    } catch (_) {
      try {
        final fallbackResponse = await client.get<dynamic>(
          'https://overpass.kumi.systems/api/interpreter',
          queryParameters: {'data': query},
          options: Options(responseType: ResponseType.json),
        );
        data = fallbackResponse.data;
      } catch (_) {
        return offlineClinics;
      }
    }

    if (data == null) return offlineClinics;

    Map<String, dynamic> jsonMap;
    if (data is Map<String, dynamic>) {
      jsonMap = data;
    } else if (data is String) {
      try {
        jsonMap = json.decode(data) as Map<String, dynamic>;
      } catch (_) {
        return offlineClinics;
      }
    } else {
      return offlineClinics;
    }

    final elements = jsonMap['elements'] as List<dynamic>?;
    if (elements == null || elements.isEmpty) return offlineClinics;

    final List<ClinicRecommendation> clinics = [];
    final Set<String> seenKeys = {};

    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      final tags = raw['tags'] as Map<String, dynamic>?;
      if (tags == null) continue;

      double? elementLat;
      double? elementLng;

      if (raw['lat'] != null && raw['lon'] != null) {
        elementLat = (raw['lat'] as num?)?.toDouble();
        elementLng = (raw['lon'] as num?)?.toDouble();
      } else if (raw['center'] is Map<String, dynamic>) {
        final center = raw['center'] as Map<String, dynamic>;
        elementLat = (center['lat'] as num?)?.toDouble();
        elementLng = (center['lon'] as num?)?.toDouble();
      }

      if (elementLat == null ||
          elementLng == null ||
          elementLat == 0.0 ||
          elementLng == 0.0) {
        continue;
      }

      final amenity = tags['amenity']?.toString().trim();
      final rawName = tags['name']?.toString().trim() ??
          tags['name:en']?.toString().trim() ??
          tags['name:ur']?.toString().trim();

      String name;
      if (rawName != null && rawName.isNotEmpty) {
        name = rawName;
      } else if (amenity != null && amenity.isNotEmpty) {
        name = amenity[0].toUpperCase() + amenity.substring(1);
      } else {
        continue;
      }

      final dedupeKey =
          '${name.toLowerCase()}_${elementLat.toStringAsFixed(3)}_${elementLng.toStringAsFixed(3)}';
      if (seenKeys.contains(dedupeKey)) continue;
      seenKeys.add(dedupeKey);

      final street = tags['addr:street']?.toString().trim();
      final cityTag = tags['addr:city']?.toString().trim() ??
          tags['addr:city:en']?.toString().trim();
      final district = tags['addr:district']?.toString().trim();
      final suburb = tags['addr:suburb']?.toString().trim();

      final addressParts = [
        if (street != null && street.isNotEmpty) street,
        if (suburb != null && suburb.isNotEmpty) suburb,
        if (district != null && district.isNotEmpty) district,
        if (cityTag != null && cityTag.isNotEmpty) cityTag,
      ];
      final address = addressParts.isNotEmpty
          ? addressParts.join(', ')
          : (cityTag ?? 'Local Healthcare Facility');

      final phone = tags['phone']?.toString().trim() ??
          tags['contact:phone']?.toString().trim() ??
          tags['contact:mobile']?.toString().trim() ??
          '';

      final specialtyTag = tags['healthcare:speciality']?.toString().trim() ??
          tags['speciality']?.toString().trim();

      final specialty = specialtyTag != null && specialtyTag.isNotEmpty
          ? specialtyTag
          : (amenity == 'hospital'
              ? 'Hospital / Medical Center'
              : (amenity == 'doctors'
                  ? 'Medical Clinic / Doctors'
                  : 'Clinic / Outpatient Care'));

      final distanceMeters = Geolocator.distanceBetween(
        lat,
        lng,
        elementLat,
        elementLng,
      );

      if (distanceMeters > radiusMeters) continue;

      final distanceKm =
          double.parse((distanceMeters / 1000.0).toStringAsFixed(1));
      final id = '${raw['type'] ?? 'facility'}_${raw['id']}';

      clinics.add(
        ClinicRecommendation(
          id: id,
          name: name,
          specialty: specialty,
          address: address,
          city: cityTag ?? '',
          rating: 4.6,
          contactNumber: phone,
          latitude: elementLat,
          longitude: elementLng,
          mapsUrl:
              'https://www.google.com/maps/search/?api=1&query=$elementLat,$elementLng',
          distanceKm: distanceKm,
        ),
      );
    }

    if (clinics.isEmpty) {
      return offlineClinics;
    }

    clinics.sort(
      (a, b) => (a.distanceKm ?? 0.0).compareTo(b.distanceKm ?? 0.0),
    );
    return clinics;
  }

  static Future<List<ClinicRecommendation>> getNearbyClinicsForDevice({
    double radiusMeters = 25000,
    Dio? dioClient,
  }) async {
    final pos = await LocationService.instance.getCurrentCoordinates();
    if (pos == null) {

      return getOfflineCachedClinics(31.4239, 73.0845);
    }
    return getNearbyClinics(
      pos.latitude,
      pos.longitude,
      radiusMeters: radiusMeters,
      dioClient: dioClient,
    );
  }

  static Future<bool> launchDirections({
    required double latitude,
    required double longitude,
    String? clinicName,
    String? mapsUrl,
  }) async {
    final webUrl = mapsUrl != null && mapsUrl.isNotEmpty
        ? Uri.parse(mapsUrl)
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
          );
    final navUri = Uri.parse('google.navigation:q=$latitude,$longitude');

    try {
      if (await canLaunchUrl(navUri)) {
        return await launchUrl(navUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> launchDialer(String contactNumber) async {
    final cleaned = contactNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.isEmpty) return false;
    final telUri = Uri(scheme: 'tel', path: cleaned);
    try {
      return await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
