import '../models/iot_vitals_model.dart';

class SystemicDistressEvaluation {

  final bool isSystemicDistressFlagged;

  final String referralTitleEn;

  final String referralTitleUr;

  final String referralRationaleEn;

  final String referralRationaleUr;

  final List<String> vitalTriggers;

  final List<String> dermatologicalRiskFactors;

  final String guardrailDisclaimerEn;
  final String guardrailDisclaimerUr;

  const SystemicDistressEvaluation({
    required this.isSystemicDistressFlagged,
    required this.referralTitleEn,
    required this.referralTitleUr,
    required this.referralRationaleEn,
    required this.referralRationaleUr,
    required this.vitalTriggers,
    required this.dermatologicalRiskFactors,
    this.guardrailDisclaimerEn =
        'SAFE CLINICAL GUARDRAIL: DermEdge does not diagnose systemic conditions (e.g. sepsis or anaphylaxis). '
        'Visual lesion severity cross-referenced with acute vital anomalies strictly flags possible systemic distress for immediate hospital/physician referral.',
    this.guardrailDisclaimerUr =
        'طبی حفاظتی رہنمائی: ڈرم ایج نظامی بیماریوں (جیسے سیپسس یا اینافلیکسس) کی تشخیص نہیں کرتا، بلکہ '
        'جلدی زخم کے ساتھ جسمانی وائٹلز کی سنگین خرابی پر صرف فوری ہسپتال ریفرل تجویز کرتا ہے۔',
  });

  static const SystemicDistressEvaluation normal = SystemicDistressEvaluation(
    isSystemicDistressFlagged: false,
    referralTitleEn: 'Vitals Stable / Low Systemic Risk',
    referralTitleUr: 'جسمانی کیفیات معمول کے مطابق',
    referralRationaleEn:
        'Biosensor vitals are within safe homeostatic ranges for localized dermatological presentation.',
    referralRationaleUr:
        'بائیو سینسر وائٹلز محفوظ حدود میں ہیں اور کسی فوری خطرے کی نشاندہی نہیں کرتے۔',
    vitalTriggers: [],
    dermatologicalRiskFactors: [],
  );
}

class ClinicalGuardrailsService {
  ClinicalGuardrailsService._();

  static const double peripheralFeverThresholdCelsius = 36.5;
  static const double peripheralHypothermiaThresholdCelsius = 28.0;
  static const double minValidPeripheralTempCelsius = 25.0;
  static const int tachycardiaThresholdBpm = 115;
  static const int bradycardiaThresholdBpm = 50;
  static const int hypoxiaThresholdSpo2 = 92;

  static bool isPeripheralHypothermia(double temp) =>
      temp > minValidPeripheralTempCelsius && temp < peripheralHypothermiaThresholdCelsius;
  static bool isNormalPeripheralTemp(double temp) =>
      temp >= 29.5 && temp <= 36.2;
  static bool isElevatedPeripheralTemp(double temp) =>
      temp > peripheralFeverThresholdCelsius;

  static const List<String> _severeLesionKeywords = [
    'cellulitis',
    'bacterial infection',
    'impetigo',
    'bullous',
    'blister',
    'exanthems',
    'drug eruptions',
    'systemic disease',
    'vasculitis',
    'purpura',
    'purpuric',
    'lupus',
    'melanoma',
    'malignant',
  ];

  static SystemicDistressEvaluation evaluate({
    required String conditionName,
    required bool isHighRiskLesion,
    double lesionConfidence = 0.5,
    IotVitalsReading? vitals,
  }) {
    if (vitals == null) {
      return SystemicDistressEvaluation.normal;
    }

    final bool hasValidVitals = vitals.heartRate > 40 && vitals.spo2 > 70;
    if (!hasValidVitals) {
      return SystemicDistressEvaluation.normal;
    }

    final List<String> vitalTriggers = [];
    final List<String> dermRisks = [];

    final temp = vitals.temperatureCelsius;
    if (isElevatedPeripheralTemp(temp)) {
      vitalTriggers.add(
        'Elevated Peripheral Temp / بخار (${temp.toStringAsFixed(1)}°C / ${vitals.temperatureFahrenheit.toStringAsFixed(1)}°F)',
      );
    } else if (isPeripheralHypothermia(temp)) {
      vitalTriggers.add(
        'Severe Peripheral Hypothermia / شدید سرد جسمانی درجہ حرارت (${temp.toStringAsFixed(1)}°C)',
      );
    }

    final hr = vitals.heartRate;
    if (hr >= tachycardiaThresholdBpm) {
      vitalTriggers.add(
        'Severe Tachycardia / تیز نبض ($hr bpm)',
      );
    } else if (hr < bradycardiaThresholdBpm) {
      vitalTriggers.add(
        'Severe Bradycardia / سست نبض ($hr bpm)',
      );
    }

    final spo2 = vitals.spo2;
    if (spo2 < 90) {
      vitalTriggers.add(
        'Critical Hypoxia / آکسیجن کی شدید کمی ($spo2% SpO2)',
      );
    }

    final condLower = conditionName.toLowerCase();
    bool hasSevereDermRisk = isHighRiskLesion;
    for (final kw in _severeLesionKeywords) {
      if (condLower.contains(kw)) {
        hasSevereDermRisk = true;
        dermRisks.add(conditionName);
        break;
      }
    }

    final bool hasAcuteVitals = vitalTriggers.isNotEmpty;
    final bool shouldFlag = hasAcuteVitals &&
        (hasSevereDermRisk || vitalTriggers.length >= 2 || spo2 <= hypoxiaThresholdSpo2);

    if (!shouldFlag) {
      return SystemicDistressEvaluation.normal;
    }

    const referralTitleEn =
        'Possible Systemic Distress Flagged (Urgent Hospital Referral Required)';
    const referralTitleUr =
        'ممکنہ جسمانی خرابی (فوری طور پر ہسپتال سے رجوع کریں)';

    final bufferEn = StringBuffer()
      ..writeln('Systemic distress guardrail triggered due to acute biosensor telemetry anomalies co-occurring with dermatological presentation:')
      ..writeln('• Lesion Presentation: $conditionName (Confidence: ${(lesionConfidence * 100).toStringAsFixed(1)}%)')
      ..writeln('• Hemodynamic Anomalies: ${vitalTriggers.join(", ")}')
      ..writeln('Action Required: Do not rely solely on topical treatment. Transfer patient for prompt hospital/physician evaluation to assess potential systemic compromise.');

    final bufferUr = StringBuffer()
      ..writeln('بائیو سینسر وائٹلز میں غیر معمولی تبدیلیوں اور جلدی زخم کی علامات کے ملاپ پر الرٹ:')
      ..writeln('• جلدی کیفیت: $conditionName')
      ..writeln('• غیر معمولی وائٹلز: ${vitalTriggers.join("، ")}')
      ..writeln('فوری اقدام: صرف مرہم یا گھریلو علاج پر انحصار نہ کریں۔ مریض کو فوری طور پر قریبی ہسپتال یا معالج کے پاس لے جائیں۔');

    return SystemicDistressEvaluation(
      isSystemicDistressFlagged: true,
      referralTitleEn: referralTitleEn,
      referralTitleUr: referralTitleUr,
      referralRationaleEn: bufferEn.toString().trim(),
      referralRationaleUr: bufferUr.toString().trim(),
      vitalTriggers: vitalTriggers,
      dermatologicalRiskFactors: dermRisks.isEmpty ? [conditionName] : dermRisks,
    );
  }
}
