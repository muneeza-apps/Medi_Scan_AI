import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mediscanai/core/services/locale_service.dart';

import '../bloc/clinical_session/clinical_session_bloc.dart';
import '../bloc/clinical_session/clinical_session_state.dart';
import '../widgets/emergency_red_flag_banner.dart';

class ClinicalReportScreen extends StatelessWidget {
  final VoidCallback? onDone;

  const ClinicalReportScreen({
    super.key,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocaleService.isUrdu;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004D40),
        elevation: 0,
        title: Text(
          isUrdu ? 'جامع طبی تشخیصی رپورٹ' : 'Unified Clinical Diagnostic Report',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: isUrdu ? 'بند کریں' : 'Close',
            onPressed: () {
              if (onDone != null) {
                onDone!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ClinicalSessionBloc, ClinicalSessionState>(
        builder: (context, sessionState) {
          final vitals = sessionState.vitals;
          final skin = sessionState.skinResult;
          final report = sessionState.report;

          final bool hasValidVitals = vitals != null && vitals.bpm > 40 && vitals.spo2 > 70;

          final bool isBradycardia;
          final bool isHypoxia;
          final bool isFever;
          final bool isHypothermia;
          final bool isTachycardia;

          if (hasValidVitals) {

            isBradycardia = vitals.bpm < 50;
            isHypoxia = vitals.spo2 < 90;
            isFever = vitals.temperature > 36.5;
            isHypothermia = vitals.temperature > 25.0 && vitals.temperature < 28.0;
            isTachycardia = vitals.bpm > 115;
          } else {

            isBradycardia = false;
            isHypoxia = false;
            isFever = false;
            isHypothermia = false;
            isTachycardia = false;
          }

          final bool hasHemodynamicEmergency = hasValidVitals &&
              (isHypoxia || (isBradycardia && vitals.bpm < 45) || isHypothermia);
          final bool isHighRiskLesion = skin != null &&
              (skin.severity.toLowerCase() == 'critical' ||
                  skin.severity.toLowerCase() == 'high' ||
                  skin.conditionName.toLowerCase().contains('melanoma') ||
                  skin.conditionName.toLowerCase().contains('carcinoma'));

          final bool shouldShowEmergency = hasHemodynamicEmergency || isHighRiskLesion;

          final List<String> vitalTriggers = [];
          if (hasValidVitals) {
            if (isFever) {
              vitalTriggers.add(
                'Elevated Peripheral Temp / بخار (${vitals.temperature.toStringAsFixed(1)}°C / ${vitals.temperatureFahrenheit.toStringAsFixed(1)}°F)',
              );
            }
            if (isHypothermia) {
              vitalTriggers.add(
                'Severe Peripheral Hypothermia / شدید سرد جسمانی درجہ حرارت (${vitals.temperature.toStringAsFixed(1)}°C)',
              );
            }
            if (isTachycardia) {
              vitalTriggers.add('Severe Tachycardia / تیز نبض (${vitals.bpm} bpm)');
            }
            if (isBradycardia) {
              vitalTriggers.add('Severe Bradycardia / سست نبض (${vitals.bpm} bpm)');
            }
            if (isHypoxia) {
              vitalTriggers.add('Critical Hypoxia / آکسیجن کی شدید کمی (${vitals.spo2}% SpO2)');
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  _buildSessionPill(isUrdu, hasValidVitals, vitals?.formattedCaptureTime),
                  const SizedBox(height: 12),

                  if (shouldShowEmergency)
                    EmergencyRedFlagBanner(
                      isUrdu: isUrdu,
                      isSystemicDistress: hasHemodynamicEmergency,
                      vitalTriggers: vitalTriggers,
                    ),

                  if (skin != null) _buildDermatologyCard(skin, isUrdu),
                  const SizedBox(height: 14),

                  _buildVitalsSummaryCard(
                    vitals: vitals,
                    hasValidVitals: hasValidVitals,
                    isUrdu: isUrdu,
                    isBradycardia: isBradycardia,
                    isHypoxia: isHypoxia,
                    isFever: isFever,
                    isHypothermia: isHypothermia,
                    isTachycardia: isTachycardia,
                  ),
                  const SizedBox(height: 14),

                  if (report != null)
                    _buildReportSynthesisCard(report, isUrdu)
                  else if (skin != null)
                    _buildStandaloneSkinSynthesisCard(skin, isUrdu),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (onDone != null) {
                          onDone!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      child: Text(
                        isUrdu ? 'مکمل کریں' : 'Return to Home',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionPill(bool isUrdu, bool hasValidVitals, String? captureTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasValidVitals ? const Color(0xFFE0F2F1) : const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasValidVitals ? const Color(0xFF80CBC4) : const Color(0xFFCFD8DC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasValidVitals ? Icons.lock_clock_rounded : Icons.info_outline,
            size: 16,
            color: hasValidVitals ? const Color(0xFF00796B) : const Color(0xFF546E7A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasValidVitals
                  ? (isUrdu
                      ? 'وائٹلز سیشن مقفل • $captureTime پر محفوظ'
                      : 'SESSION CAPTURED • LOCKED (Captured at ${captureTime ?? "--"})')
                  : (isUrdu
                      ? 'جلد کا معائنہ موڈ • وائٹلز منسلک نہیں'
                      : 'Standalone Dermatological Evaluation (Vitals Unattached)'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: hasValidVitals ? const Color(0xFF004D40) : const Color(0xFF37474F),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDermatologyCard(dynamic skin, bool isUrdu) {
    final imagePath = skin.imagePath as String? ?? '';
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF00796B), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'جلد کا تشخیصی جائزہ' : 'Dermatological Vision AI Findings',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isUrdu ? 'ڈرما پلس نیورل انجن' : 'DermaPulse Neural Engine',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${((skin.confidence as double) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(imagePath),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (hasImage) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.conditionName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isUrdu ? "شدت" : "Severity"}: ${skin.severity} • ${skin.lesionType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSummaryCard({
    required dynamic vitals,
    required bool hasValidVitals,
    required bool isUrdu,
    required bool isBradycardia,
    required bool isHypoxia,
    required bool isFever,
    required bool isHypothermia,
    required bool isTachycardia,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Color(0xFF00897B), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isUrdu ? 'طبی وائٹلز خلاصہ // ہیوموڈائنامک بیس لائن' : 'Clinical Vitals Summary // Hemodynamic Baseline',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (!hasValidVitals)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sensors_off_rounded, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'اس معائنے کے ساتھ بائیو میٹرک وائٹلز ریکارڈ نہیں کیے گئے ہیں۔ صرف جلد کی تشخیص کا جائزہ لیا جا رہا ہے۔'
                            : 'No biometric vitals were captured for this session. Evaluating dermatological presentation only.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBlock(
                      label: isUrdu ? 'دل کی دھڑکن' : 'Heart Rate',
                      value: '${vitals.bpm}',
                      unit: 'BPM',
                      status: isTachycardia
                          ? 'Tachycardia'
                          : isBradycardia
                              ? 'Bradycardia'
                              : 'Normal Sinus',
                      isAlert: isTachycardia || isBradycardia,
                      themeColor: const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBlock(
                      label: isUrdu ? 'آکسیجن' : 'Oxygen SpO₂',
                      value: '${vitals.spo2}',
                      unit: '%',
                      status: isHypoxia ? 'Sub-optimal' : 'Optimal',
                      isAlert: isHypoxia,
                      themeColor: const Color(0xFF00ACC1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricBlock(
                      label: isUrdu ? 'حرارت' : 'Body Temp',
                      value: vitals.temperature.toStringAsFixed(1),
                      unit: '°C',
                      status: isFever
                          ? 'Febrile'
                          : (isHypothermia ? 'Hypothermia' : 'Normative'),
                      isAlert: isFever || isHypothermia,
                      themeColor: const Color(0xFFFB8C00),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBlock({
    required String label,
    required String value,
    required String unit,
    required String status,
    required bool isAlert,
    required Color themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.shade50 : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert ? Colors.red.shade300 : const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAlert ? Colors.red.shade700 : const Color(0xFF166534),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.red.shade700 : const Color(0xFF15803D),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReportSynthesisCard(dynamic report, bool isUrdu) {

    final String sanitizedSynthesis = (report.clinicalSynthesis as String)
        .replaceAll('local quantized EfficientNetV2-B3 model', 'on-device DermaPulse Edge-AI model')
        .replaceAll('EfficientNetV2-B3', 'DermaPulse')
        .replaceAll('EfficientNet', 'DermaPulse')
        .replaceAll('DermNet Benchmark Dataset', 'DermaPulse Neural Engine')
        .replaceAll('آن ڈیوائس ایفیشنٹ نیٹ ماڈل', 'ڈرما پلس نیورل انجن');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Color(0xFF004D40), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu ? 'مشترکہ کلینیکل تشخیصی تجزیہ' : 'Combined AI Diagnostic Synthesis',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              sanitizedSynthesis,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Color(0xFF1E293B),
              ),
            ),
            if (report.clinicalObservations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                isUrdu ? 'مشاہدات:' : 'Observations:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...report.clinicalObservations.map(
                (rawObs) {

                  final String obs = (rawObs as String)
                      .replaceAll('Quantized EfficientNetV2-B3 (DermNet Benchmark Dataset)',
                          'DermaPulse Neural Engine (On-Device Edge AI)')
                      .replaceAll('آن ڈیوائس ایفیشنٹ نیٹ ماڈل (موبائل ایج)',
                          'ڈرما پلس نیورل انجن (آن ڈیوائس ایج اے آئی)')
                      .replaceAll('EfficientNetV2-B3', 'DermaPulse')
                      .replaceAll('EfficientNet', 'DermaPulse')
                      .replaceAll('DermNet', 'DermaPulse');

                  final splitIndex = obs.indexOf(': ');
                  if (splitIndex != -1) {
                    final title = obs.substring(0, splitIndex);
                    final value = obs.substring(splitIndex + 2);
                    return _buildObservationRow(
                      title: title,
                      value: value,
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 13.5, color: Color(0xFF00796B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            obs,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildObservationRow({
    required String title,
    required String value,
  }) {
    final bool isArchitecture = title.toLowerCase().contains('model architecture') ||
        title.contains('ماڈل ساخت');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isArchitecture ? Icons.memory_rounded : Icons.check_circle_outline,
            size: 13.5,
            color: isArchitecture ? const Color(0xFF004D40) : const Color(0xFF00796B),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF263238)),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: isArchitecture ? const Color(0xFF004D40) : Colors.grey.shade800,
                      fontWeight: isArchitecture ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandaloneSkinSynthesisCard(dynamic skin, bool isUrdu) {
    final confidencePercent = ((skin.confidence as double) * 100).toStringAsFixed(1);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Color(0xFF004D40), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu ? 'تشخیصی تجزیہ' : 'Diagnostic Synthesis',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              isUrdu
                  ? 'مقامی آن ڈیوائس ڈرما پلس ماڈل نے $confidencePercent% یقین کے ساتھ ${skin.conditionName} کی تشخیص کی ہے۔ حتمی ڈرموسکوپی کے لیے مستند ماہر امراض جلد سے رجوع کریں۔'
                  : 'Visual inspection identified ${skin.conditionName} with $confidencePercent% confidence via on-device DermaPulse Edge-AI model. Consult a qualified dermatologist for definitive dermoscopy.',
              style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text(
              isUrdu ? 'مشاہدات:' : 'Observations:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _buildObservationRow(
              title: isUrdu ? "ماڈل ساخت" : "Model Architecture",
              value: isUrdu
                  ? "ڈرما پلس نیورل انجن (آن ڈیوائس ایج اے آئی)"
                  : "DermaPulse Neural Engine (On-Device Edge AI)",
            ),
            _buildObservationRow(
              title: isUrdu ? "مقامی تشخیصی یقین" : "Local Edge AI Certainty",
              value: "$confidencePercent%",
            ),
            _buildObservationRow(
              title: isUrdu ? "تشخیصی کیفیت" : "Diagnostic Condition",
              value: "${skin.conditionName} (${skin.severity})",
            ),
          ],
        ),
      ),
    );
  }
}
