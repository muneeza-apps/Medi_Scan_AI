import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/scan_record_model.dart';
import '../services/scan_history_storage.dart';

abstract class IScanRepository {
  Stream<List<ScanRecord>> get scansStream;
  ValueNotifier<List<ScanRecord>> get scansNotifier;
  Future<List<ScanRecord>> getAllScans();
  Future<void> saveScan(ScanRecord record);
  Future<void> deleteScan(String id);
  Future<void> clearAllScans();
}

class ScanRepository implements IScanRepository {
  ScanRepository._();
  static final ScanRepository instance = ScanRepository._();

  @override
  Stream<List<ScanRecord>> get scansStream => ScanHistoryStorage.scansStream;

  @override
  ValueNotifier<List<ScanRecord>> get scansNotifier =>
      ScanHistoryStorage.scansNotifier;

  @override
  Future<List<ScanRecord>> getAllScans() => ScanHistoryStorage.getAllScans();

  @override
  Future<void> saveScan(ScanRecord record) =>
      ScanHistoryStorage.saveScan(record);

  @override
  Future<void> deleteScan(String id) => ScanHistoryStorage.deleteScan(id);

  @override
  Future<void> clearAllScans() => ScanHistoryStorage.clearAllScans();
}
