import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/iot_vitals_service.dart';
import '../../../../core/services/on_device_triage_synthesis_engine.dart';
import '../../domain/domain.dart';
import '../datasources/datasources.dart';

class SkinTriageRepositoryImpl implements ISkinTriageRepository {
  final SkinTfliteDatasource _skinDatasource;
  final DrapPharmacologyDatasource _drapDatasource;
  final AiTriageDatasource _aiTriageDatasource;
  final FirebaseFirestore _firestore;

  SkinTriageRepositoryImpl({
    SkinTfliteDatasource? skinDatasource,
    DrapPharmacologyDatasource? drapDatasource,
    AiTriageDatasource? aiTriageDatasource,
    FirebaseFirestore? firestore,
  }) : _skinDatasource = skinDatasource ?? SkinTfliteDatasource(),
       _drapDatasource = drapDatasource ?? DrapPharmacologyDatasource(),
       _aiTriageDatasource = aiTriageDatasource ?? AiTriageDatasource(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  AiTriageDatasource get aiTriageDatasource => _aiTriageDatasource;

  @override
  Future<SkinAnalysisEntity> analyzeSkinLesion({
    required String imagePath,
    required Uint8List modelBytes,
    required List<String> labels,
  }) async {
    final model = await _skinDatasource.runInference(
      imagePath: imagePath,
      modelBytes: modelBytes,
      labels: labels,
    );
    return model.toEntity();
  }

  @override
  Future<String?> fetchDrugSafetyInfo(String medicationName) async {
    final clean = medicationName.trim();
    if (clean.isEmpty) return null;
    return _drapDatasource.fetchDrugSafetyInfo(clean);
  }

  @override
  Future<TriageSummaryEntity> generateTriageSummary({
    required SkinAnalysisEntity skinAnalysis,
    required String symptoms,
    String? medication,
    String? drugSafetyDetails,
  }) async {
    final latestVitals = IotVitalsService.instance.latestReading;
    final validVitals = (latestVitals != null &&
            latestVitals.heartRate > 40 &&
            latestVitals.spo2 > 70)
        ? latestVitals
        : null;

    debugPrint(
      '[SkinTriageRepo] 100% Offline Edge Report Generator Active: Instant 0-second deterministic synthesis.',
    );
    return OnDeviceTriageSynthesisEngine.instance.synthesizeTriageSummary(
      skinAnalysis: skinAnalysis,
      symptoms: symptoms,
      medication: medication,
      drugSafetyDetails: drugSafetyDetails,
      vitals: validVitals,
    );
  }

  @override
  Future<void> saveTriageSummary(TriageSummaryEntity summary) async {
    try {
      await _firestore
          .collection('skin_triage_reports')
          .doc(summary.id)
          .set(summary.toJson());
      debugPrint(
        '[SkinTriageRepo] Persisted triage report #${summary.id} to Firestore.',
      );
    } catch (e) {
      debugPrint(
        '[SkinTriageRepo] Firestore offline or unauthenticated note: $e',
      );
    }
  }
}
