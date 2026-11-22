import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/triage_draft_model.dart';

class TriageDraftStorage {
  static const String _storageKey = 'mediscan_triage_drafts_v1';

  static Future<void> saveDraft(TriageDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJsonList = prefs.getStringList(_storageKey) ?? [];

      final updatedList = existingJsonList.where((item) {
        try {
          final map = json.decode(item) as Map<String, dynamic>;
          return map['id'] != draft.id;
        } catch (_) {
          return true;
        }
      }).toList();

      updatedList.insert(0, draft.toJson());
      await prefs.setStringList(_storageKey, updatedList);
    } catch (e) {
      debugPrint('Error saving triage draft: $e');
    }
  }

  static Future<List<TriageDraft>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];

      final drafts = <TriageDraft>[];
      for (final raw in jsonList) {
        try {
          drafts.add(TriageDraft.fromJson(raw));
        } catch (e) {
          debugPrint('Deserialization error for draft: $e');
        }
      }
      drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return drafts;
    } catch (e) {
      debugPrint('Error loading drafts: $e');
      return [];
    }
  }

  static Future<void> deleteDraft(String id) async {
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
    } catch (e) {
      debugPrint('Error deleting draft: $e');
    }
  }

  static Future<void> clearAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing drafts: $e');
    }
  }
}
