import '../../../../core/models/clinic_recommendation_model.dart';
import 'skin_analysis_entity.dart';

class TriageSummaryEntity {
  final String id;
  final SkinAnalysisEntity skinAnalysis;
  final String symptoms;
  final String? medication;
  final String riskLevel;
  final String laymanTitleEn;
  final String laymanTitleUr;
  final String diagnosticSynthesisEn;
  final String diagnosticSynthesisUr;
  final List<String> clinicalObservations;
  final List<String> clinicalObservationsUr;
  final String? openFdaWarnings;
  final String? openFdaWarningsUr;
  final List<String> protocolRecommendationsEn;
  final List<String> protocolRecommendationsUr;
  final List<ClinicRecommendation> recommendedClinics;
  final Map<String, dynamic>? a2uiPayload;
  final DateTime createdAt;

  String get diagnosticSynthesis => diagnosticSynthesisEn.isNotEmpty
      ? diagnosticSynthesisEn
      : diagnosticSynthesisUr;

  List<String> get protocolRecommendations =>
      protocolRecommendationsEn.isNotEmpty
      ? protocolRecommendationsEn
      : protocolRecommendationsUr;

  const TriageSummaryEntity({
    required this.id,
    required this.skinAnalysis,
    required this.symptoms,
    this.medication,
    required this.riskLevel,
    this.laymanTitleEn = '',
    this.laymanTitleUr = '',
    String? diagnosticSynthesisEn,
    this.diagnosticSynthesisUr = '',
    String? diagnosticSynthesis,
    this.clinicalObservations = const [],
    this.clinicalObservationsUr = const [],
    this.openFdaWarnings,
    this.openFdaWarningsUr,
    List<String>? protocolRecommendationsEn,
    this.protocolRecommendationsUr = const [],
    List<String>? protocolRecommendations,
    this.recommendedClinics = const [],
    this.a2uiPayload,
    required this.createdAt,
  }) : diagnosticSynthesisEn =
           diagnosticSynthesisEn ?? diagnosticSynthesis ?? '',
       protocolRecommendationsEn =
           protocolRecommendationsEn ?? protocolRecommendations ?? const [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skinAnalysis': skinAnalysis.toJson(),
      'symptoms': symptoms,
      'medication': medication,
      'riskLevel': riskLevel,
      'laymanTitleEn': laymanTitleEn,
      'laymanTitleUr': laymanTitleUr,
      'diagnosticSynthesisEn': diagnosticSynthesisEn,
      'diagnosticSynthesisUr': diagnosticSynthesisUr,
      'diagnosticSynthesis': diagnosticSynthesis,
      'clinicalObservations': clinicalObservations,
      'clinicalObservationsUr': clinicalObservationsUr,
      'openFdaWarnings': openFdaWarnings,
      'openFdaWarningsUr': openFdaWarningsUr,
      'protocolRecommendationsEn': protocolRecommendationsEn,
      'protocolRecommendationsUr': protocolRecommendationsUr,
      'protocolRecommendations': protocolRecommendations,
      'recommendedClinics': recommendedClinics.map((c) => c.toMap()).toList(),
      'a2uiPayload': a2uiPayload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TriageSummaryEntity.fromJson(Map<String, dynamic> json) {
    final legacySynthesis = json['diagnosticSynthesis'] as String? ?? '';
    final synthesisEn =
        json['diagnosticSynthesisEn'] as String? ?? legacySynthesis;
    final synthesisUr = json['diagnosticSynthesisUr'] as String? ?? '';

    final legacyRecs =
        (json['protocolRecommendations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final recsEn =
        (json['protocolRecommendationsEn'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        legacyRecs;
    final recsUr =
        (json['protocolRecommendationsUr'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final clinics =
        (json['recommendedClinics'] as List<dynamic>?)
            ?.map(
              (e) => ClinicRecommendation.fromMap(e as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return TriageSummaryEntity(
      id: json['id'] as String? ?? '',
      skinAnalysis: SkinAnalysisEntity.fromJson(
        json['skinAnalysis'] as Map<String, dynamic>? ?? {},
      ),
      symptoms: json['symptoms'] as String? ?? '',
      medication: json['medication'] as String?,
      riskLevel: json['riskLevel'] as String? ?? 'Moderate',
      laymanTitleEn: json['laymanTitleEn'] as String? ?? '',
      laymanTitleUr: json['laymanTitleUr'] as String? ?? '',
      diagnosticSynthesisEn: synthesisEn,
      diagnosticSynthesisUr: synthesisUr,
      clinicalObservations:
          (json['clinicalObservations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      clinicalObservationsUr:
          (json['clinicalObservationsUr'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      openFdaWarnings: json['openFdaWarnings'] as String?,
      openFdaWarningsUr: json['openFdaWarningsUr'] as String?,
      protocolRecommendationsEn: recsEn,
      protocolRecommendationsUr: recsUr,
      recommendedClinics: clinics,
      a2uiPayload: json['a2uiPayload'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TriageSummaryEntity copyWith({
    String? id,
    SkinAnalysisEntity? skinAnalysis,
    String? symptoms,
    String? medication,
    String? riskLevel,
    String? laymanTitleEn,
    String? laymanTitleUr,
    String? diagnosticSynthesisEn,
    String? diagnosticSynthesisUr,
    List<String>? clinicalObservations,
    List<String>? clinicalObservationsUr,
    String? openFdaWarnings,
    String? openFdaWarningsUr,
    List<String>? protocolRecommendationsEn,
    List<String>? protocolRecommendationsUr,
    List<ClinicRecommendation>? recommendedClinics,
    Map<String, dynamic>? a2uiPayload,
    DateTime? createdAt,
  }) {
    return TriageSummaryEntity(
      id: id ?? this.id,
      skinAnalysis: skinAnalysis ?? this.skinAnalysis,
      symptoms: symptoms ?? this.symptoms,
      medication: medication ?? this.medication,
      riskLevel: riskLevel ?? this.riskLevel,
      laymanTitleEn: laymanTitleEn ?? this.laymanTitleEn,
      laymanTitleUr: laymanTitleUr ?? this.laymanTitleUr,
      diagnosticSynthesisEn: diagnosticSynthesisEn ?? this.diagnosticSynthesisEn,
      diagnosticSynthesisUr: diagnosticSynthesisUr ?? this.diagnosticSynthesisUr,
      clinicalObservations: clinicalObservations ?? this.clinicalObservations,
      clinicalObservationsUr:
          clinicalObservationsUr ?? this.clinicalObservationsUr,
      openFdaWarnings: openFdaWarnings ?? this.openFdaWarnings,
      openFdaWarningsUr: openFdaWarningsUr ?? this.openFdaWarningsUr,
      protocolRecommendationsEn:
          protocolRecommendationsEn ?? this.protocolRecommendationsEn,
      protocolRecommendationsUr:
          protocolRecommendationsUr ?? this.protocolRecommendationsUr,
      recommendedClinics: recommendedClinics ?? this.recommendedClinics,
      a2uiPayload: a2uiPayload ?? this.a2uiPayload,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
