import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  final Geocoding _geocoding = Geocoding();

  Future<Position?> getCurrentCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return await Geolocator.getLastKnownPosition();
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return position;
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  Future<String> resolveDistrictOrTown(double lat, double lng) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        lat,
        lng,
      ).timeout(const Duration(seconds: 6));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final subDistrict = place.subLocality?.trim();
        final locality = place.locality?.trim();
        final district = place.subAdministrativeArea?.trim();

        if (locality != null && locality.isNotEmpty) {
          if (district != null && district.isNotEmpty && district != locality) {
            return '$locality, $district';
          }
          return locality;
        }

        if (district != null && district.isNotEmpty) {
          if (subDistrict != null &&
              subDistrict.isNotEmpty &&
              subDistrict != district) {
            return '$subDistrict, $district';
          }
          return district;
        }

        if (subDistrict != null && subDistrict.isNotEmpty) {
          return subDistrict;
        }

        final admin = place.administrativeArea?.trim();
        if (admin != null && admin.isNotEmpty) {
          return admin;
        }
      }
    } catch (_) {}
    return '';
  }

  Future<String> resolveCityName(double lat, double lng) =>
      resolveDistrictOrTown(lat, lng);
}
