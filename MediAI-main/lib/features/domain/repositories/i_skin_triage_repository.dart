import 'dart:typed_data';

import '../entities/skin_analysis_entity.dart';
import '../entities/triage_summary_entity.dart';

abstract class ISkinTriageRepository {

  Future<SkinAnalysisEntity> analyzeSkinLesion({
    required String imagePath,
    required Uint8List modelBytes,
    required List<String> labels,
  });

  Future<String?> fetchDrugSafetyInfo(String medicationName);

  Future<TriageSummaryEntity> generateTriageSummary({
    required SkinAnalysisEntity skinAnalysis,
    required String symptoms,
    String? medication,
    String? drugSafetyDetails,
  });

  Future<void> saveTriageSummary(TriageSummaryEntity summary);
}
