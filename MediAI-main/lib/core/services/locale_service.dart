import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'app_language';
  static final ValueNotifier<Locale> currentLocale = ValueNotifier<Locale>(
    const Locale('en'),
  );

  static bool get isUrdu => currentLocale.value.languageCode == 'ur';
  static String get languageCode => currentLocale.value.languageCode;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_localeKey) ?? 'en';
      currentLocale.value = Locale(savedCode);
      debugPrint('[LocaleService] Initialized with locale: $savedCode');
    } catch (e) {
      debugPrint('[LocaleService] Error initializing locale: $e');
    }
  }

  static Future<void> setLocale(String langCode) async {
    if (langCode != 'en' && langCode != 'ur') return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, langCode);
      currentLocale.value = Locale(langCode);
      debugPrint('[LocaleService] Locale updated to: $langCode');
    } catch (e) {
      debugPrint('[LocaleService] Error setting locale: $e');
    }
  }

  static void toggleLocale() {
    final next = isUrdu ? 'en' : 'ur';
    setLocale(next);
  }
}
