import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile_model.dart';

class PatientProfileService {
  PatientProfileService._();

  static const String _nameKey = 'patient_name';
  static const String _ageKey = 'patient_age';
  static const String _fitzpatrickKey = 'patient_fitzpatrick';
  static const String _cityKey = 'patient_city';

  static final ValueNotifier<PatientProfile> currentProfile =
      ValueNotifier<PatientProfile>(const PatientProfile());

  static PatientProfile get profile => currentProfile.value;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_nameKey) ?? 'Clinical Patient';
      final age = prefs.getString(_ageKey) ?? '34';
      final fitzpatrick = prefs.getString(_fitzpatrickKey) ?? 'Type III';
      final city = prefs.getString(_cityKey) ?? 'Faisalabad';

      currentProfile.value = PatientProfile(
        name: name,
        age: age,
        fitzpatrickType: fitzpatrick,
        city: city,
      );
    } catch (_) {}
  }

  static Future<void> saveProfile(PatientProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, profile.name);
      await prefs.setString(_ageKey, profile.age);
      await prefs.setString(_fitzpatrickKey, profile.fitzpatrickType);
      await prefs.setString(_cityKey, profile.city);

      currentProfile.value = profile;
    } catch (_) {}
  }
}
