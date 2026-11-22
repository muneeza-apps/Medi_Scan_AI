import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record_model.dart';

class ScanHistoryStorage {
  static const String _storageKey = 'mediscan_scan_history_v1';

  static final StreamController<List<ScanRecord>> _scansStreamController =
      StreamController<List<ScanRecord>>.broadcast();

  static Stream<List<ScanRecord>> get scansStream =>
      _scansStreamController.stream;

  static final ValueNotifier<List<ScanRecord>> scansNotifier =
      ValueNotifier<List<ScanRecord>>(<ScanRecord>[]);

  static Future<void> saveScan(ScanRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJsonList = prefs.getStringList(_storageKey) ?? [];

      final updatedList = existingJsonList.where((item) {
        try {
          final map = json.decode(item) as Map<String, dynamic>;
          return map['id'] != record.id;
        } catch (_) {
          return true;
        }
      }).toList();

      updatedList.insert(0, record.toJson());

      await prefs.setStringList(_storageKey, updatedList);
      final refreshed = await getAllScans();
      scansNotifier.value = refreshed;
      _scansStreamController.add(refreshed);
    } catch (_) {}
  }

  static Future<List<ScanRecord>> getAllScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      final records = <ScanRecord>[];
      for (final raw in jsonList) {
        try {
          records.add(ScanRecord.fromJson(raw));
        } catch (_) {}
      }

      records.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      scansNotifier.value = records;
      _scansStreamController.add(records);
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteScan(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJsonList = prefs.getStringList(_storageKey) ?? [];

      final updatedList = existingJsonList.where((item) {
        try {
          final map = json.decode(item) as Map<String, dynamic>;
          return map['id'] != id;
        } catch (_) {
          return true;
        }
      }).toList();

      await prefs.setStringList(_storageKey, updatedList);
      final refreshed = await getAllScans();
      scansNotifier.value = refreshed;
      _scansStreamController.add(refreshed);
    } catch (_) {}
  }

  static Future<void> clearAllScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      scansNotifier.value = <ScanRecord>[];
      _scansStreamController.add(<ScanRecord>[]);
    } catch (_) {}
  }
}
