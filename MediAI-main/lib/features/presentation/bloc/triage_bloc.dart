import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/scan_record_model.dart';
import '../../../core/models/triage_draft_model.dart';
import '../../../core/services/clinic_locator_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/network_connectivity_service.dart';
import '../../../core/services/scan_history_storage.dart';
import '../../../core/services/triage_draft_storage.dart';
import '../../data/data.dart';
import '../../domain/domain.dart';
import 'triage_event.dart';
import 'triage_state.dart';

class TriageBloc extends Bloc<TriageEvent, TriageState> {
  final ISkinTriageRepository repository;
  final SkinTfliteDatasource _skinDatasource;

  SkinAnalysisEntity? _currentSkinAnalysis;
  Uint8List? _cachedModelBytes;
  List<String>? _cachedLabels;
  String? _currentScanRecordId;
  String? _currentAnatomicalLocation;
  String? _currentLesionTag;

  TriageBloc({required this.repository, SkinTfliteDatasource? skinDatasource})
    : _skinDatasource = skinDatasource ?? SkinTfliteDatasource(),
      super(const TriageInitial()) {
    on<PickAndAnalyzeImage>(_onPickAndAnalyzeImage);
    on<SubmitFullTriage>(_onSubmitFullTriage);
    on<ResetTriage>(_onResetTriage);

    _skinDatasource.initialize();
  }

  Future<void> _onPickAndAnalyzeImage(
    PickAndAnalyzeImage event,
    Emitter<TriageState> emit,
  ) async {
    _currentAnatomicalLocation = event.anatomicalLocation;
    _currentLesionTag = event.lesionTag;

    emit(TriageAnalyzingSkin(imagePath: event.imagePath));

    try {
      final imageFile = File(event.imagePath);
      if (!await imageFile.exists()) {
        emit(
          const TriageFailure(
            message: 'Lesion image file could not be found on device.',
          ),
        );
        return;
      }

      _cachedModelBytes ??= await _skinDatasource.getModelBytes();
      _cachedLabels ??= await _skinDatasource.getLabels();

      final skinAnalysis = await repository.analyzeSkinLesion(
        imagePath: event.imagePath,
        modelBytes: _cachedModelBytes!,
        labels: _cachedLabels!,
      );

      _currentSkinAnalysis = skinAnalysis;
      final scanId = 'scan_${DateTime.now().millisecondsSinceEpoch}';
      _currentScanRecordId = scanId;

      final initialRecommendations = <String>[];
      if (skinAnalysis.explanation != null &&
          skinAnalysis.explanation!.isNotEmpty) {
        initialRecommendations.add(skinAnalysis.explanation!);
      }
      if (skinAnalysis.isHighRisk) {
        initialRecommendations.add(
          'High-risk presentation: urgent clinical examination by a certified dermatologist is strongly recommended.',
        );
      } else {
        initialRecommendations.add(
          'Low/moderate presentation: continue routine skin self-exams using the ABCDE guidelines.',
        );
      }

      final String recordedLesionName = switch (skinAnalysis.tier) {
        TriageTier.nonSkin => 'Non-Skin Surface Detected',
        TriageTier.inconclusiveRescan => 'Inconclusive Scan',
        TriageTier.cleanHealthySkin => 'Healthy & Clear Skin',
        TriageTier.universalInconclusive => 'Invalid or Inconclusive Scan',
        TriageTier.highConfidenceLesion => skinAnalysis.friendlyNameEn.isNotEmpty
            ? skinAnalysis.friendlyNameEn
            : skinAnalysis.conditionName,
      };

      final String recordedRiskLevel = switch (skinAnalysis.tier) {
        TriageTier.nonSkin => 'Invalid Scan',
        TriageTier.inconclusiveRescan => 'Inconclusive',
        TriageTier.cleanHealthySkin => 'Normal',
        TriageTier.universalInconclusive => 'Scan Not Accepted',
        TriageTier.highConfidenceLesion => skinAnalysis.urgencyTagEn,
      };

      final initialRecord = ScanRecord(
        id: scanId,
        dateTime: DateTime.now(),
        lesionName: recordedLesionName,
        riskLevel: recordedRiskLevel,
        confidenceScore: skinAnalysis.confidence,
        thumbnailPath: event.imagePath,
        clinicalRecommendations: initialRecommendations,
        recommendedClinics: const [],
        anatomicalLocation: _currentAnatomicalLocation,
        lesionTag: _currentLesionTag,
      );
      await ScanHistoryStorage.saveScan(initialRecord);

      emit(
        TriageSkinAnalyzed(
          skinAnalysis: skinAnalysis,
        ),
      );

      _enrichClinicsInBackground(scanId, initialRecord);
    } catch (e) {
      emit(
        TriageFailure(
          message: 'Dermatological analysis error: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSubmitFullTriage(
    SubmitFullTriage event,
    Emitter<TriageState> emit,
  ) async {
    if (event.anatomicalLocation != null) {
      _currentAnatomicalLocation = event.anatomicalLocation;
    }
    if (event.lesionTag != null) {
      _currentLesionTag = event.lesionTag;
    }

    if (_currentSkinAnalysis == null ||
        _currentSkinAnalysis!.isNonSkin ||
        _currentSkinAnalysis!.isInconclusive ||
        _currentSkinAnalysis!.conditionName.contains('Invalid Capture')) {
      emit(
        const TriageFailure(
          message:
              'A valid and clear skin image is required before synthesizing clinical triage report.',
        ),
      );
      return;
    }

    final isOnline = await NetworkConnectivityService.isNetworkAvailable();
    if (!isOnline) {

      final draft = TriageDraft(
        id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
        imagePath: _currentSkinAnalysis!.imagePath,
        createdAt: DateTime.now(),
        symptoms: event.symptoms,
        medication: event.medication,
        anatomicalLocation: _currentAnatomicalLocation,
        lesionTag: _currentLesionTag,
      );
      await TriageDraftStorage.saveDraft(draft);
    }

    emit(TriageGeneratingGenUi(skinAnalysis: _currentSkinAnalysis!));

    try {
      String? drugSafety;
      final med = event.medication?.trim();
      if (med != null && med.isNotEmpty) {
        drugSafety = await repository.fetchDrugSafetyInfo(med);
      }

      final summary = await repository.generateTriageSummary(
        skinAnalysis: _currentSkinAnalysis!,
        symptoms: event.symptoms.trim(),
        medication: med,
        drugSafetyDetails: drugSafety,
      );

      final pos = await LocationService.instance.getCurrentCoordinates();
      final nearbyList = pos != null
          ? await ClinicLocatorService.getNearbyClinics(
              pos.latitude,
              pos.longitude,
            )
          : ClinicLocatorService.getOfflineCachedClinics(31.4239, 73.0845);
      final clinics = nearbyList.take(3).toList();

      final enrichedSummary = summary.copyWith(recommendedClinics: clinics);
      await repository.saveTriageSummary(enrichedSummary);

      if (_currentScanRecordId != null && _currentSkinAnalysis != null) {
        final synthesisRecs = <String>[];
        if (enrichedSummary.diagnosticSynthesisEn.isNotEmpty) {
          synthesisRecs.add(enrichedSummary.diagnosticSynthesisEn);
        }
        for (final item in enrichedSummary.protocolRecommendationsEn) {
          if (item.trim().isNotEmpty) synthesisRecs.add(item.trim());
        }
        if (synthesisRecs.isEmpty &&
            _currentSkinAnalysis!.explanation != null) {
          synthesisRecs.add(_currentSkinAnalysis!.explanation!);
        }

        final riskLevel = _currentSkinAnalysis!.effectiveRiskLevel;

        await ScanHistoryStorage.saveScan(
          ScanRecord(
            id: _currentScanRecordId!,
            dateTime: DateTime.now(),
            lesionName: _currentSkinAnalysis!.conditionName,
            riskLevel: riskLevel,
            confidenceScore: _currentSkinAnalysis!.confidence,
            thumbnailPath: _currentSkinAnalysis!.imagePath,
            clinicalRecommendations: synthesisRecs,
            recommendedClinics: clinics,
            anatomicalLocation: _currentAnatomicalLocation,
            lesionTag: _currentLesionTag,
          ),
        );
      }

      emit(TriageSuccess(summary: enrichedSummary));
    } catch (e) {
      debugPrint('[TriageBloc] Clinical triage synthesis error: $e');
      emit(
        TriageFailure(
          message: 'Clinical triage synthesis error: ${e.toString()}',
        ),
      );
    }
  }

  void _enrichClinicsInBackground(String scanId, ScanRecord baseRecord) {
    Future<void>(() async {
      try {
        final pos = await LocationService.instance.getCurrentCoordinates();
        if (pos != null) {
          final nearbyList = await ClinicLocatorService.getNearbyClinics(
            pos.latitude,
            pos.longitude,
          );
          final clinics = nearbyList.take(3).toList();
          if (clinics.isNotEmpty) {
            await ScanHistoryStorage.saveScan(
              baseRecord.copyWith(recommendedClinics: clinics),
            );
          }
        }
      } catch (_) {
      }
    });
  }

  void _onResetTriage(ResetTriage event, Emitter<TriageState> emit) {
    _currentSkinAnalysis = null;
    _currentScanRecordId = null;
    _currentAnatomicalLocation = null;
    _currentLesionTag = null;
    emit(const TriageInitial());
  }
}
