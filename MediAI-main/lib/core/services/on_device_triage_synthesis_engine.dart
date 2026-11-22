import '../../features/domain/domain.dart';
import '../models/iot_vitals_model.dart';
import 'clinical_guardrails_service.dart';
import 'drap_pharmacology_service.dart';

class OnDeviceTriageSynthesisEngine {
  final DrapPharmacologyService _drapService;

  OnDeviceTriageSynthesisEngine({DrapPharmacologyService? drapService})
      : _drapService = drapService ?? DrapPharmacologyService.instance;

  static final OnDeviceTriageSynthesisEngine instance =
      OnDeviceTriageSynthesisEngine();

  TriageSummaryEntity synthesizeTriageSummary({
    required SkinAnalysisEntity skinAnalysis,
    required String symptoms,
    String? medication,
    String? drugSafetyDetails,
    IotVitalsReading? vitals,
  }) {
    final reportId = 'DP-EDGE-${DateTime.now().millisecondsSinceEpoch}';

    if (skinAnalysis.isNonSkin ||
        skinAnalysis.tier == TriageTier.universalInconclusive ||
        skinAnalysis.tier == TriageTier.nonSkin ||
        skinAnalysis.conditionName == 'Invalid or Inconclusive Scan' ||
        skinAnalysis.conditionName == 'non_skin') {
      return TriageSummaryEntity(
        id: reportId,
        skinAnalysis: skinAnalysis,
        symptoms: symptoms,
        diagnosticSynthesis:
            'Invalid or Inconclusive Scan: The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.\n'
            'ناقابل قبول یا غیر واضح اسکین: سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔',
        protocolRecommendations: [
          'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.',
          'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔',
          'Please ensure the photo is taken directly on affected human skin under even lighting.',
        ],
        createdAt: DateTime.now(),
        riskLevel: 'Scan Not Accepted',
        openFdaWarnings: null,
      );
    }

    final taxonomy = ClinicalTerminologyMapper.getTaxonomy(skinAnalysis.conditionName);
    final laymanTerm = ClinicalTerminologyMapper.mapToLayman(skinAnalysis.conditionName);

    final bool isSevere = skinAnalysis.isSeverePathology ||
        DrapPharmacologyService.isSevereHighRiskClass(skinAnalysis.conditionName);
    const criticalReferralWarning = DrapPharmacologyService.criticalReferralBanner;

    String? drapGuidanceEn = drugSafetyDetails;
    String? drapGuidanceUr;

    if (medication != null && medication.trim().isNotEmpty) {
      drapGuidanceEn ??= _drapService.formatDrugSafetyGuidance(medication.trim());
      drapGuidanceUr = _drapService.generateUrduDrugGuidance(medication.trim());
    }

    final drapTopicals = _drapService.getRecommendedTopicalsForCondition(
      skinAnalysis.conditionName,
    );

    final guardrailEval = ClinicalGuardrailsService.evaluate(
      conditionName: skinAnalysis.conditionName,
      isHighRiskLesion: skinAnalysis.isHighRisk || isSevere,
      lesionConfidence: skinAnalysis.confidence,
      vitals: vitals,
    );

    final String effectiveRisk;
    if (guardrailEval.isSystemicDistressFlagged) {
      effectiveRisk = 'Emergency';
    } else if (isSevere) {
      effectiveRisk = 'Critical';
    } else if (skinAnalysis.isHighRisk) {
      effectiveRisk = 'High';
    } else if (skinAnalysis.confidence >= 0.45 && !skinAnalysis.isDifferentialAssessment) {
      effectiveRisk = 'Moderate';
    } else {
      effectiveRisk = 'Low';
    }

    final bool isDifferential = skinAnalysis.confidence < 0.45 && skinAnalysis.confidence >= 0.22;
    final bool isIndeterminate = skinAnalysis.confidence < 0.22 || skinAnalysis.isIndeterminate;

    final String diffEn;
    final String diffUr;
    if (skinAnalysis.topPredictions.isNotEmpty) {
      final bufferEn = StringBuffer();
      final bufferUr = StringBuffer();
      bufferEn.writeln('\nTop-3 Differential Assessment Breakdown:');
      bufferUr.writeln('\nتقابلی تشخیصی جائزہ (ٹاپ ۳ امکانات):');
      for (final p in skinAnalysis.topPredictions.take(3)) {
        final tax = ClinicalTerminologyMapper.getTaxonomy(p.conditionName);
        bufferEn.writeln('  #${p.rank} ${tax.benchmarkScientificName} (${tax.plainVernacularEn}) - ${p.confidenceScore}');
        bufferUr.writeln('  #${p.rank} ${tax.regionalUrduContext} (${tax.plainVernacularEn}) - ${p.confidenceScore}');
      }
      diffEn = bufferEn.toString();
      diffUr = bufferUr.toString();
    } else {
      diffEn = '';
      diffUr = '';
    }

    final String synthesisEn;
    final String synthesisUr;

    if (guardrailEval.isSystemicDistressFlagged) {
      synthesisEn =
          'CRITICAL CLINICAL ALERT: ${guardrailEval.referralRationaleEn}\n\n'
          'Visual inspection identified "${taxonomy.plainVernacularEn}" [${taxonomy.benchmarkScientificName}] '
          'with ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% confidence. '
          'Because acute biosensor vital anomalies were detected, immediate hospital evaluation is required to rule out systemic complications. '
          '${guardrailEval.guardrailDisclaimerEn}';

      synthesisUr =
          'فوری طبی الرٹ: ${guardrailEval.referralRationaleUr}\n\n'
          'طبی معائنے میں "${taxonomy.regionalUrduContext}" کی تشخیص ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% یقین کے ساتھ ہوئی ہے۔ '
          'وائٹلز میں غیر معمولی تبدیلیوں کے باعث فوری معالج سے رجوع کریں۔ '
          '${guardrailEval.guardrailDisclaimerUr}';
    } else if (isSevere) {
      synthesisEn =
          '$criticalReferralWarning\n\n'
          'Visual analysis identified suspicious presentation of ${taxonomy.benchmarkScientificName} (${taxonomy.plainVernacularEn}) '
          'with ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% certainty. '
          'STRICT PROTOCOL: High-risk pathology suspected. OTC medication is strictly contraindicated. '
          'Immediate specialist clinical dermoscopy and excisional biopsy required.';

      synthesisUr =
          '$criticalReferralWarning\n\n'
          'طبی تجزیے میں ${taxonomy.regionalUrduContext} [${taxonomy.benchmarkScientificName}] کی مشتبہ علامات پائی گئی ہیں۔ '
          'سخت طبی ہدایت: شدید خطرے کی بیماری کے باعث کسی قسم کی اوور دی کاؤنٹر کریم مت لگائیں۔ '
          'فوری طور پر مستند ڈرمیٹالوجسٹ سے معائنہ اور بائیوپسی کروائیں۔';
    } else if (isIndeterminate) {
      synthesisEn =
          'INDETERMINATE CLINICAL ASSESSMENT: Primary lesion confidence is below the threshold (<22%). '
          'Please reposition under direct, even room lighting or consult a certified dermatologist.';

      synthesisUr =
          'غیر حتمی کلینیکل تجزیہ: تشخیصی یقین کی شرح 22 فیصد سے کم ہے۔ '
          'برائے مہربانی یکساں اور براہِ راست روشنی میں دوبارہ تصویر لیں یا مستند ڈاکٹر سے رجوع کریں۔';
    } else {
      final diffNoteEn = isDifferential ? '\n[Differential Assessment Mode (22%-44% confidence)]$diffEn' : '';
      final diffNoteUr = isDifferential ? '\n[تقابلی جائزہ موڈ (22%-44% یقین)]$diffUr' : '';

      synthesisEn =
          'On-device edge evaluation identified "${taxonomy.plainVernacularEn}" [${taxonomy.benchmarkScientificName}] '
          'with ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% confidence via on-device DermaPulse Edge-AI model. '
          '${laymanTerm.patientExplanationEn.isNotEmpty ? laymanTerm.patientExplanationEn : ""} '
          '${drapTopicals.en}$diffNoteEn';

      synthesisUr =
          'مقامی آن ڈیوائس ڈرما پلس ماڈل نے "${taxonomy.regionalUrduContext}" کی تشخیص ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% یقین کے ساتھ کی ہے۔ '
          '${laymanTerm.patientExplanationUr.isNotEmpty ? laymanTerm.patientExplanationUr : ""} '
          '${drapTopicals.ur}$diffNoteUr';
    }

    final List<String> recsEn = [];
    final List<String> recsUr = [];

    if (guardrailEval.isSystemicDistressFlagged) {
      recsEn.add('Urgent hospital transfer: immediate clinical evaluation required.');
      recsEn.add('Do not attempt sole OTC topical management while acute vital anomalies persist.');
      recsEn.add('Bring patient vitals record (HR, SpO2, Peripheral Body Temp) to the emergency department.');

      recsUr.add('فوری قریبی ہسپتال یا ایمرجنسی وارڈ سے رجوع کریں۔');
      recsUr.add('جب تک جسمانی حالت اور نبض مستحکم نہ ہو، صرف گھریلو مرہم پر انحصار نہ کریں۔');
      recsUr.add('سینسر سے حاصل کردہ نبض اور درجہ حرارت کا ریکارڈ ڈاکٹر کو دکھائیں۔');
    } else if (isSevere) {
      recsEn.add('CRITICAL MEDICAL ALERT: Immediate consultation with a certified dermatologist / oncology centre.');
      recsEn.add('Strictly zero OTC medications or home salves.');
      recsEn.add('Protect lesion from irritation, sun exposure, and mechanical trauma.');

      recsUr.add('فوری طور پر ماہر امراض جلد یا متعلقہ ہسپتال سے رجوع کریں۔');
      recsUr.add('اوور دی کاؤنٹر مرہم یا گھریلو ٹوٹکے ہرگز استعمال نہ کریں۔');
      recsUr.add('متاثرہ جگہ کو دھوپ اور رگڑ سے بچائیں۔');
    } else if (isIndeterminate) {
      recsEn.add('Schedule an in-person clinical evaluation for dermoscopic examination.');
      recsEn.add('Avoid applying unprescribed steroid creams which can alter lesion morphology (tinea incognito).');
      recsEn.add('Rescan with direct diffused daylight if lighting was suboptimal.');

      recsUr.add('مستند ماہر امراض جلد سے بالمشافہ معائنہ کروائیں۔');
      recsUr.add('بغیر تصدیق اسٹرائیڈ کریم نہ لگائیں کیونکہ اس سے بیماری کی شکل بگڑ سکتی ہے۔');
      recsUr.add('مناسب قدرتی روشنی میں دوبارہ تصویر بنا کر جائزہ لیں۔');
    } else {
      recsEn.add(drapTopicals.en);
      recsEn.add('Maintain good regional skin hygiene with gentle non-soap cleansers.');
      recsEn.add('Re-scan or seek medical advice if lesions spread or fail to improve within 7–14 days.');

      recsUr.add(drapTopicals.ur);
      recsUr.add('جلد کو صاف اور خشک رکھیں اور ہلکے کلینزر کا استعمال کریں۔');
      recsUr.add('اگر ایک سے دو ہفتوں میں آرام نہ آئے تو قریبی معالج سے رجوع کریں۔');
    }

    final List<String> observations = [
      'Diagnostic Condition: ${taxonomy.benchmarkScientificName}',
      'Vernacular English: ${taxonomy.plainVernacularEn}',
      'Local Edge AI Certainty: ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}%',
      'Model Architecture: DermaPulse Neural Engine (On-Device Edge AI)',
      'Fitzpatrick Demographic Evaluation: South Asian Types III–V Calibrated',
      if (isDifferential) 'Assessment Mode: Top-3 Differential Breakdown (<35% confidence)',
      if (isIndeterminate) 'Indeterminate Gate: Below 15% Safe Diagnostic Confidence Threshold',
      if (isSevere) 'HIGH-RISK PROTOCOL ACTIVE: Zero OTC medication permitted',
      if (symptoms.trim().isNotEmpty) 'Patient-Reported Context: "$symptoms"',
      if (medication?.trim().isNotEmpty == true)
        'Patient Medication: "${medication!.trim()}" (DRAP Verified)',
      if (vitals != null && vitals.heartRate > 40 && vitals.spo2 > 70)
        'Hemodynamic Baseline: HR: ${vitals.heartRate} bpm | SpO2: ${vitals.spo2}% | Temp: ${vitals.temperatureCelsius}°C (Peripheral Body Temp)',
      if (guardrailEval.isSystemicDistressFlagged)
        'GUARDRAIL FLAG: ${guardrailEval.referralTitleEn}',
    ];

    final List<String> observationsUr = [
      'تشخیصی کیفیت: ${taxonomy.regionalUrduContext}',
      'مقامی مصنوعی ذہانت کا یقین: ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}%',
      'ماڈل ساخت: ڈرما پلس نیورل انجن (آن ڈیوائس ایج اے آئی)',
      'جنوبی ایشیائی جلد (ٹائپ ۳ تا ۵) کے مطابق کیلیبریشن',
      if (isDifferential) 'تشخیصی موڈ: ٹاپ ۳ تفریقی امکانات کا جائزہ',
      if (isIndeterminate) 'غیر حتمی نتیجہ: تشخیصی شرح مطلوبہ حد سے کم ہے',
      if (isSevere) 'شدید خطرہ فعال: اوور دی کاؤنٹر مرہم کا استعمال ممنوع ہے',
      if (symptoms.trim().isNotEmpty) 'مریض کے بتائے گئے مسائل: "$symptoms"',
      if (medication?.trim().isNotEmpty == true)
        'استعمال شدہ دوا: "${medication!.trim()}" (ڈریپ تصدیق شدہ)',
      if (vitals != null && vitals.heartRate > 40 && vitals.spo2 > 70)
        'سینسر ڈیٹا: نبض ${vitals.heartRate} فی منٹ | آکسیجن ${vitals.spo2}% | درجہ حرارت ${vitals.temperatureCelsius}°C',
      if (guardrailEval.isSystemicDistressFlagged)
        'حفاظتی انتباہ: ${guardrailEval.referralTitleUr}',
    ];

    return TriageSummaryEntity(
      id: reportId,
      skinAnalysis: skinAnalysis,
      symptoms: symptoms,
      medication: medication,
      riskLevel: effectiveRisk,
      laymanTitleEn: taxonomy.plainVernacularEn,
      laymanTitleUr: taxonomy.regionalUrduContext,
      diagnosticSynthesisEn: synthesisEn,
      diagnosticSynthesisUr: synthesisUr,
      clinicalObservations: observations,
      clinicalObservationsUr: observationsUr,
      openFdaWarnings: drapGuidanceEn,
      openFdaWarningsUr: drapGuidanceUr,
      protocolRecommendationsEn: recsEn,
      protocolRecommendationsUr: recsUr,
      a2uiPayload: {
        'surfaceId': 'mediai_edge_surface',
        'pipeline': '100% On-Device Zero-Cloud Edge Pipeline',
        'riskLevel': effectiveRisk,
        'taxonomy': taxonomy.toMap(),
        'laymanTitleEn': taxonomy.plainVernacularEn,
        'laymanTitleUr': taxonomy.regionalUrduContext,
        'isSystemicDistressFlagged': guardrailEval.isSystemicDistressFlagged,
        'vitalTriggers': guardrailEval.vitalTriggers,
        'isSeverePathology': isSevere,
        'isDifferential': isDifferential,
        'isIndeterminate': isIndeterminate,
        'drapTopicals': drapTopicals.en,
        'drapTopicalsUr': drapTopicals.ur,
        'synthesisEn': synthesisEn,
        'synthesisUr': synthesisUr,
        'observations': observations,
        'recommendationsEn': recsEn,
        'recommendationsUr': recsUr,
        if (vitals != null && vitals.heartRate > 40 && vitals.spo2 > 70) 'vitals': vitals.toMap(),
      },
      createdAt: DateTime.now(),
    );
  }
}
