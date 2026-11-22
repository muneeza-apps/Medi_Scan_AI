import 'dart:math' as math;

import '../../../../core/services/drap_pharmacology_service.dart';
import '../../domain/domain.dart';

class SkinAnalysisModel {
  final String conditionName;
  final double confidence;
  final String confidenceScore;
  final String riskLevel;
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

  const SkinAnalysisModel({
    required this.conditionName,
    required this.confidence,
    required this.confidenceScore,
    required this.riskLevel,
    required this.topPredictions,
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

  factory SkinAnalysisModel.nonSkinSurface({
    required String imagePath,
    double confidence = 0.98,
    List<String>? labels,
  }) {
    return SkinAnalysisModel.universalInconclusive(
      imagePath: imagePath,
      confidence: confidence,
      labels: labels,
    );
  }

  factory SkinAnalysisModel.cleanHealthySkin({
    required String imagePath,
    double topConfidence = 0.20,
    List<String>? labels,
  }) {
    final double normalcyScore = (1.0 - topConfidence).clamp(0.0, 1.0);
    final double pct = (normalcyScore * 100).clamp(0.0, 100.0);
    final pred = SkinPrediction(
      conditionName: 'Healthy & Clear Skin',
      rawScore: normalcyScore,
      confidencePercentage: double.parse(pct.toStringAsFixed(1)),
      confidenceScore: '${pct.toStringAsFixed(1)}%',
      riskLevel: 'Low',
      rank: 1,
    );

    return SkinAnalysisModel(
      conditionName: 'Healthy Skin / No Active Lesion',
      confidence: normalcyScore,
      confidenceScore: '${pct.toStringAsFixed(1)}%',
      riskLevel: 'Normal / Benign',
      topPredictions: [pred],
      rawProbabilities: {
        'Healthy Skin / No Active Lesion': normalcyScore,
        if (labels != null)
          for (final l in labels) l: (1.0 - normalcyScore) / labels.length,
      },
      isHighRisk: false,
      imagePath: imagePath,
      explanation:
          'Epidermal surface appears clear with no inflammatory lesion patterns detected.',
      tier: TriageTier.cleanHealthySkin,
      friendlyNameEn: 'Healthy & Clear Skin',
      friendlyNameUr: 'صاف اور صحت مند جلد',
      urgencyTagEn: 'Normal / Low Risk',
      urgencyTagUr: 'محفوظ / کم خطرہ',
      instructionEn: 'No treatment required. Maintain healthy skincare.',
      instructionUr: 'علاج کی ضرورت نہیں، جلد کو صاف اور صحت مند رکھیں۔',
    );
  }

  factory SkinAnalysisModel.inconclusiveRescan({
    required String imagePath,
    double topConfidence = 0.20,
    List<String>? labels,
  }) {
    final pct = (topConfidence * 100).clamp(0.0, 100.0);
    final pred = SkinPrediction(
      conditionName: 'Inconclusive Scan',
      rawScore: topConfidence,
      confidencePercentage: double.parse(pct.toStringAsFixed(1)),
      confidenceScore: '${pct.toStringAsFixed(1)}%',
      riskLevel: 'Inconclusive',
      rank: 1,
    );

    return SkinAnalysisModel(
      conditionName: 'Inconclusive Scan',
      confidence: topConfidence,
      confidenceScore: '${pct.toStringAsFixed(1)}%',
      riskLevel: 'Inconclusive',
      topPredictions: [pred],
      rawProbabilities: {
        'Inconclusive Scan': topConfidence,
        if (labels != null)
          for (final l in labels) l: (1.0 - topConfidence) / labels.length,
      },
      isHighRisk: false,
      imagePath: imagePath,
      explanation:
          'Lighting is low or the spot is blurry. Please hold camera 10cm away with direct light and rescan.',
      tier: TriageTier.inconclusiveRescan,
      friendlyNameEn: 'Inconclusive Scan',
      friendlyNameUr: 'تصویر واضح نہیں ہے',
      urgencyTagEn: 'Retake Photo',
      urgencyTagUr: 'دوبارہ تصویر لیں',
      instructionEn:
          'Lighting is low or the spot is blurry. Please hold camera 10cm away with direct light and rescan.',
      instructionUr:
          'براہ کرم اچھی روشنی میں داغ کے قریب سے دوبارہ تصویر بنائیں۔',
      isIndeterminate: true,
    );
  }

  factory SkinAnalysisModel.universalInconclusive({
    required String imagePath,
    double confidence = 0.0,
    List<String>? labels,
    String? customExplanation,
    String? customInstructionEn,
    String? customInstructionUr,
  }) {
    const String defaultSubtitleEn =
        'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.';
    const String defaultSubtitleUr =
        'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔';

    final explanationText = customExplanation ?? defaultSubtitleEn;
    final instructionEnText = customInstructionEn ?? defaultSubtitleEn;
    final instructionUrText = customInstructionUr ?? defaultSubtitleUr;

    return SkinAnalysisModel(
      conditionName: 'Invalid or Inconclusive Scan',
      confidence: confidence,
      confidenceScore: '${(confidence * 100).toStringAsFixed(1)}%',
      riskLevel: 'Scan Not Accepted',
      topPredictions: const [],
      rawProbabilities: {
        'Invalid or Inconclusive Scan': confidence,
      },
      isHighRisk: false,
      imagePath: imagePath,
      explanation: explanationText,
      tier: TriageTier.universalInconclusive,
      friendlyNameEn: 'Invalid or Inconclusive Scan',
      friendlyNameUr: 'ناقابل قبول یا غیر واضح اسکین',
      urgencyTagEn: 'Scan Not Accepted',
      urgencyTagUr: 'ناقابل قبول یا غیر واضح اسکین',
      instructionEn: instructionEnText,
      instructionUr: instructionUrText,
      isIndeterminate: false,
    );
  }

  static List<double> sharpenProbabilities(
    List<double> probabilities, {
    double power = 1.30,
  }) {
    if (probabilities.isEmpty) return probabilities;
    final List<double> powered = probabilities
        .map((p) => math.pow(math.max(0.0, p), power).toDouble())
        .toList();
    final double sum = powered.fold(0.0, (acc, val) => acc + val);
    if (sum <= 0.0) return probabilities;
    return powered.map((p) => p / sum).toList();
  }

  factory SkinAnalysisModel.fromInference({
    required List<double> probabilities,
    required List<String> labels,
    required String imagePath,
  }) {
    final List<({int index, double score})> rawIndexedScores = [];
    double nonSkinProb = 0.0;

    for (int i = 0; i < probabilities.length; i++) {
      final label = (i < labels.length) ? labels[i].trim() : 'Class $i';
      final score = probabilities[i];
      rawIndexedScores.add((index: i, score: score));

      final labelLower = label.toLowerCase();
      if (label == 'non_skin' ||
          labelLower == 'non_skin' ||
          labelLower == 'non-skin' ||
          labelLower.contains('non_skin') ||
          labelLower.contains('non-skin')) {
        nonSkinProb = math.max(nonSkinProb, score);
      }
    }

    rawIndexedScores.sort((a, b) => b.score.compareTo(a.score));

    bool isNonSkinInTop3 = false;
    for (int i = 0; i < math.min(3, rawIndexedScores.length); i++) {
      final l = (rawIndexedScores[i].index < labels.length)
          ? labels[rawIndexedScores[i].index].trim().toLowerCase()
          : '';
      if (l == 'non_skin' ||
          l == 'non-skin' ||
          l.contains('non_skin') ||
          l.contains('non-skin')) {
        isNonSkinInTop3 = true;
        break;
      }
    }

    if (nonSkinProb >= 0.12 || isNonSkinInTop3) {
      return SkinAnalysisModel.universalInconclusive(
        imagePath: imagePath,
        confidence: nonSkinProb,
        labels: labels,
        customExplanation:
            'The system could not detect valid human skin. Vehicles, sky, and non-biological objects are rejected.',
        customInstructionEn:
            'The system could not detect valid human skin. Vehicles, sky, and non-biological objects are rejected.',
        customInstructionUr:
            'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ گاڑیاں، آسمان اور غیر حیاتیاتی اشیاء مسترد کی جاتی ہیں۔',
      );
    }

    final rawSkinScores = rawIndexedScores.where((item) {
      final l = (item.index < labels.length)
          ? labels[item.index].trim().toLowerCase()
          : '';
      return l != 'non_skin' &&
          l != 'non-skin' &&
          !l.contains('non_skin') &&
          !l.contains('non-skin');
    }).toList();

    final topItem = rawIndexedScores.isNotEmpty
        ? rawIndexedScores.first
        : (index: 0, score: 0.0);
    final topLabel = (topItem.index < labels.length)
        ? labels[topItem.index].trim()
        : 'Class ${topItem.index}';
    final topLabelLower = topLabel.toLowerCase();

    if (topLabelLower.contains('healthy') ||
        topLabelLower.contains('normal skin')) {
      return SkinAnalysisModel.cleanHealthySkin(
        imagePath: imagePath,
        topConfidence: topItem.score,
        labels: labels,
      );
    }

    final double power = 1.30;
    double skinPoweredSum = 0.0;
    for (final item in rawSkinScores) {
      skinPoweredSum += math.pow(math.max(0.0, item.score), power).toDouble();
    }

    final Map<String, double> probabilityMap = {};
    final List<SkinPrediction> top3 = [];
    final int topK = math.min(3, rawSkinScores.length);

    for (int i = 0; i < rawSkinScores.length; i++) {
      final item = rawSkinScores[i];
      final label = (item.index < labels.length)
          ? labels[item.index].trim()
          : 'Class ${item.index}';
      final double rawScore = item.score;
      final double powered = math.pow(math.max(0.0, rawScore), power).toDouble();
      final double sharpenedScore =
          skinPoweredSum > 0 ? (powered / skinPoweredSum) : rawScore;
      final double pct = (sharpenedScore * 100).clamp(0.0, 100.0);
      final String itemRisk = SkinRiskClassifier.determineRiskLevel(label);

      probabilityMap[label] = sharpenedScore;

      if (i < topK) {
        top3.add(
          SkinPrediction(
            conditionName: label,
            rawScore: sharpenedScore,
            confidencePercentage: double.parse(pct.toStringAsFixed(1)),
            confidenceScore: '${pct.toStringAsFixed(1)}%',
            riskLevel: itemRisk,
            rank: i + 1,
          ),
        );
      }
    }

    final primary = top3.isNotEmpty
        ? top3.first
        : const SkinPrediction(
            conditionName: 'Unknown',
            rawScore: 0.0,
            confidencePercentage: 0.0,
            confidenceScore: '0.0%',
            riskLevel: 'Low',
            rank: 1,
          );

    final double sharpenedTop1 = primary.rawScore;

    if (sharpenedTop1 < 0.22) {
      final pct = (sharpenedTop1 * 100).clamp(0.0, 100.0);
      const indeterminateTitle = 'Indeterminate Scan';

      return SkinAnalysisModel(
        conditionName: indeterminateTitle,
        confidence: sharpenedTop1,
        confidenceScore: '${pct.toStringAsFixed(1)}%',
        riskLevel: 'Indeterminate',
        topPredictions: top3,
        rawProbabilities: probabilityMap,
        isHighRisk: false,
        imagePath: imagePath,
        explanation:
            'Top inference confidence (${pct.toStringAsFixed(1)}%) is strictly below threshold (<22%). '
            'Please reposition under direct, even room lighting or consult a certified dermatologist.',
        tier: TriageTier.inconclusiveRescan,
        friendlyNameEn: 'Indeterminate Scan',
        friendlyNameUr: 'غیر حتمی اسکین',
        urgencyTagEn: 'Reposition & Retake Photo',
        urgencyTagUr: 'دوبارہ تصویر لیں',
        instructionEn:
            'Lighting is low or spot features are unclear (<22% confidence). Please reposition under direct, even room lighting and rescan.',
        instructionUr:
            'روشنی کم ہے یا علامات واضح نہیں ہیں (<22% یقین)۔ براہ کرم مناسب اور یکساں روشنی میں دوبارہ اسکین کریں۔',
        isDifferentialAssessment: false,
        isIndeterminate: true,
      );
    }

    final layman = ClinicalTerminologyMapper.mapToLayman(primary.conditionName);
    final String risk = SkinRiskClassifier.determineRiskLevel(primary.conditionName);

    final bool isSevere = DrapPharmacologyService.isSevereHighRiskClass(primary.conditionName);
    const criticalWarning = DrapPharmacologyService.criticalReferralBanner;

    final bool highRisk = isSevere ||
        layman.isHighUrgency ||
        risk == 'High' ||
        top3.any((p) => p.riskLevel == 'High' && p.rawScore >= 0.15) ||
        probabilityMap.entries.any((e) {
          final k = e.key.toLowerCase();
          return (k.contains('melanoma') ||
                  k.contains('carcinoma') ||
                  k.contains('malignant')) &&
              e.value >= 0.15;
        });

    final bool isDifferential = sharpenedTop1 < 0.45;

    final String displayEn = isDifferential
        ? 'Differential Assessment: ${layman.friendlyNameEn}'
        : layman.friendlyNameEn;
    final String displayUr = isDifferential
        ? 'تقابلی تشخیصی جائزہ: ${layman.friendlyNameUr}'
        : layman.friendlyNameUr;

    final String explanationText = isSevere
        ? 'CRITICAL ALERT: $criticalWarning. Suspected high-risk lesion (${layman.benchmarkScientificName}). OTC medication is strictly contraindicated.'
        : (isDifferential
            ? 'Top confidence (${(sharpenedTop1 * 100).toStringAsFixed(1)}%) is between 22% and 44%. Displaying primary match alongside Top-3 differential assessment options. ${layman.patientExplanationEn}'
            : layman.patientExplanationEn);

    return SkinAnalysisModel(
      conditionName: primary.conditionName,
      confidence: sharpenedTop1,
      confidenceScore: '${(sharpenedTop1 * 100).toStringAsFixed(1)}%',
      riskLevel: isSevere ? 'Critical / Urgent Referral' : primary.riskLevel,
      topPredictions: top3,
      rawProbabilities: probabilityMap,
      isHighRisk: highRisk,
      imagePath: imagePath,
      explanation: explanationText,
      tier: TriageTier.highConfidenceLesion,
      friendlyNameEn: displayEn,
      friendlyNameUr: displayUr,
      urgencyTagEn: isSevere ? 'Critical Medical Alert' : layman.urgencyTagEn,
      urgencyTagUr: isSevere ? 'فوری ماہر امراض جلد سے رجوع کریں' : layman.urgencyTagUr,
      instructionEn: isSevere ? criticalWarning : layman.patientExplanationEn,
      instructionUr: isSevere ? 'فوری طور پر ماہر امراض جلد سے رجوع کریں' : layman.patientExplanationUr,
      isDifferentialAssessment: isDifferential,
      isIndeterminate: false,
      isSeverePathology: isSevere,
      criticalReferralWarningEn: isSevere ? criticalWarning : null,
      criticalReferralWarningUr: isSevere
          ? 'فوری طور پر ماہر امراض جلد سے رجوع کریں'
          : null,
    );
  }

  SkinAnalysisEntity toEntity() {
    return SkinAnalysisEntity(
      conditionName: conditionName,
      confidence: confidence,
      confidenceScore: confidenceScore,
      riskLevel: riskLevel,
      topPredictions: topPredictions,
      rawProbabilities: rawProbabilities,
      isHighRisk: isHighRisk,
      imagePath: imagePath,
      explanation: explanation,
      tier: tier,
      friendlyNameEn: friendlyNameEn,
      friendlyNameUr: friendlyNameUr,
      urgencyTagEn: urgencyTagEn,
      urgencyTagUr: urgencyTagUr,
      instructionEn: instructionEn,
      instructionUr: instructionUr,
      isDifferentialAssessment: isDifferentialAssessment,
      isIndeterminate: isIndeterminate,
      isSeverePathology: isSeverePathology,
      criticalReferralWarningEn: criticalReferralWarningEn,
      criticalReferralWarningUr: criticalReferralWarningUr,
    );
  }
}
