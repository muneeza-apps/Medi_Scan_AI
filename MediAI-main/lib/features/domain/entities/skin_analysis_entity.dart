import '../utils/clinical_terminology_mapper.dart';
import 'skin_prediction.dart';

enum TriageTier {
  nonSkin,
  highConfidenceLesion,
  inconclusiveRescan,
  cleanHealthySkin,
  universalInconclusive,
}

class SkinAnalysisEntity {
  final String conditionName;
  final double confidence;
  final String? confidenceScore;
  final String? riskLevel;
  final List<SkinPrediction> topPredictions;
  final Map<String, double> rawProbabilities;
  final bool isHighRisk;
  final String imagePath;
  final String? explanation;

  final TriageTier tier;
  final String friendlyNameEn;
  final String friendlyNameUr;
  final String urgencyTagEn;
  final String urgencyTagUr;
  final String instructionEn;
  final String instructionUr;

  final bool isDifferentialAssessment;
  final bool isIndeterminate;
  final bool isSeverePathology;
  final String? criticalReferralWarningEn;
  final String? criticalReferralWarningUr;

  Map<String, double> get differentialDiagnoses => rawProbabilities;

  String get formattedConfidenceScore =>
      confidenceScore ?? '${(confidence * 100).toStringAsFixed(1)}%';

  String get effectiveRiskLevel =>
      riskLevel ??
      (isHighRisk ? 'High' : (confidence >= 0.40 ? 'Moderate' : 'Low'));

  bool get isNonSkin =>
      tier == TriageTier.nonSkin ||
      tier == TriageTier.universalInconclusive ||
      conditionName == 'non_skin' ||
      conditionName.toLowerCase().contains('non-skin') ||
      conditionName.toLowerCase().contains('non_skin') ||
      conditionName == 'Invalid or Inconclusive Scan' ||
      conditionName == 'Non-Skin Surface Detected';
  bool get isInconclusive => tier == TriageTier.inconclusiveRescan || isIndeterminate;
  bool get isHealthySkin => tier == TriageTier.cleanHealthySkin;
  bool get isHighConfidenceLesion =>
      tier == TriageTier.highConfidenceLesion &&
      confidence >= 0.40 &&
      !isNonSkin;

  bool get isConfirmedCondition =>
      tier == TriageTier.highConfidenceLesion &&
      confidence >= 0.45 &&
      !isDifferentialAssessment &&
      !isIndeterminate &&
      !isNonSkin;
  bool get isUniversalInconclusive =>
      tier == TriageTier.universalInconclusive ||
      tier == TriageTier.nonSkin ||
      isNonSkin;
  String get predictedLabel => conditionName;

  ThreeTieredClinicalLabel get taxonomy =>
      ClinicalTerminologyMapper.getTaxonomy(conditionName);

  String getBilingualTitle([String? languageCode]) {
    if (languageCode == 'ur') {
      return friendlyNameUr;
    }
    return friendlyNameEn;
  }

  String getDisplayTitle(String languageCode) {
    return languageCode == 'ur' ? friendlyNameUr : friendlyNameEn;
  }

  String getDisplaySubtitle(String languageCode) {
    return languageCode == 'ur' ? friendlyNameEn : friendlyNameUr;
  }

  String getDisplayUrgency(String languageCode) {
    return languageCode == 'ur' ? urgencyTagUr : urgencyTagEn;
  }

  String getDisplayInstruction(String languageCode) {
    return languageCode == 'ur' ? instructionUr : instructionEn;
  }

  const SkinAnalysisEntity({
    required this.conditionName,
    required this.confidence,
    this.confidenceScore,
    this.riskLevel,
    this.topPredictions = const [],
    required this.rawProbabilities,
    required this.isHighRisk,
    required this.imagePath,
    this.explanation,
    this.tier = TriageTier.highConfidenceLesion,
    this.friendlyNameEn = '',
    this.friendlyNameUr = '',
    this.urgencyTagEn = 'Self-Care / Low Risk',
    this.urgencyTagUr = 'گھریلو دیکھ بھال / کم خطرہ',
    this.instructionEn = '',
    this.instructionUr = '',
    this.isDifferentialAssessment = false,
    this.isIndeterminate = false,
    this.isSeverePathology = false,
    this.criticalReferralWarningEn,
    this.criticalReferralWarningUr,
  });

  Map<String, dynamic> toJson() {
    return {
      'conditionName': conditionName,
      'confidence': confidence,
      if (confidenceScore != null) 'confidenceScore': confidenceScore,
      if (riskLevel != null) 'riskLevel': riskLevel,
      'topPredictions': topPredictions.map((p) => p.toJson()).toList(),
      'rawProbabilities': rawProbabilities,
      'isHighRisk': isHighRisk,
      'imagePath': imagePath,
      if (explanation != null) 'explanation': explanation,
      'tier': tier.name,
      'friendlyNameEn': friendlyNameEn,
      'friendlyNameUr': friendlyNameUr,
      'urgencyTagEn': urgencyTagEn,
      'urgencyTagUr': urgencyTagUr,
      'instructionEn': instructionEn,
      'instructionUr': instructionUr,
      'isDifferentialAssessment': isDifferentialAssessment,
      'isIndeterminate': isIndeterminate,
      'isSeverePathology': isSeverePathology,
      if (criticalReferralWarningEn != null)
        'criticalReferralWarningEn': criticalReferralWarningEn,
      if (criticalReferralWarningUr != null)
        'criticalReferralWarningUr': criticalReferralWarningUr,
    };
  }

  factory SkinAnalysisEntity.fromJson(Map<String, dynamic> json) {
    final cond = json['conditionName'] as String? ?? 'Unknown';
    final conf = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    final tierStr = json['tier'] as String?;

    final TriageTier tier = tierStr != null
        ? TriageTier.values.firstWhere(
            (t) => t.name == tierStr,
            orElse: () => _inferTier(cond, conf),
          )
        : _inferTier(cond, conf);

    final layman = ClinicalTerminologyMapper.mapToLayman(cond);

    return SkinAnalysisEntity(
      conditionName: cond,
      confidence: conf,
      confidenceScore: json['confidenceScore'] as String?,
      riskLevel: json['riskLevel'] as String?,
      topPredictions: (json['topPredictions'] as List<dynamic>?)
              ?.map(
                (item) => SkinPrediction.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      rawProbabilities:
          (json['rawProbabilities'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      isHighRisk: json['isHighRisk'] as bool? ?? false,
      imagePath: json['imagePath'] as String? ?? '',
      explanation: json['explanation'] as String?,
      tier: tier,
      friendlyNameEn:
          json['friendlyNameEn'] as String? ?? layman.friendlyNameEn,
      friendlyNameUr:
          json['friendlyNameUr'] as String? ?? layman.friendlyNameUr,
      urgencyTagEn:
          json['urgencyTagEn'] as String? ?? layman.urgencyTagEn,
      urgencyTagUr:
          json['urgencyTagUr'] as String? ?? layman.urgencyTagUr,
      instructionEn:
          json['instructionEn'] as String? ?? layman.patientExplanationEn,
      instructionUr:
          json['instructionUr'] as String? ?? layman.patientExplanationUr,
      isDifferentialAssessment:
          json['isDifferentialAssessment'] as bool? ?? (conf < 0.45 && conf >= 0.22),
      isIndeterminate: json['isIndeterminate'] as bool? ??
          (conf < 0.22 &&
              !cond.toLowerCase().contains('non_skin') &&
              !cond.toLowerCase().contains('non-skin') &&
              !cond.toLowerCase().contains('invalid')),
      isSeverePathology: json['isSeverePathology'] as bool? ?? false,
      criticalReferralWarningEn: json['criticalReferralWarningEn'] as String?,
      criticalReferralWarningUr: json['criticalReferralWarningUr'] as String?,
    );
  }

  static TriageTier _inferTier(String cond, double conf) {
    final lower = cond.toLowerCase();
    if (lower.contains('non-skin') ||
        lower.contains('non_skin') ||
        lower.contains('invalid')) {
      return TriageTier.nonSkin;
    }
    if (lower.contains('healthy') ||
        lower.contains('normal')) {
      return TriageTier.cleanHealthySkin;
    }
    if (conf < 0.22) {
      return TriageTier.inconclusiveRescan;
    }
    return TriageTier.highConfidenceLesion;
  }
}
