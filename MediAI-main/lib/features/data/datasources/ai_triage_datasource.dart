import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
class AiTriageDatasource {
  GenerativeModel? _triageModel;

  GenerativeModel _getTriageModel() {
    return _triageModel ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.8-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'riskLevel': Schema.string(
              description: 'Clinical urgency: Emergency, High, Moderate, Low',
            ),
            'laymanTitleEn': Schema.string(
              description: 'Friendly English title',
            ),
            'laymanTitleUr': Schema.string(description: 'Friendly Urdu title'),
            'diagnosticSynthesisEn': Schema.string(
              description: 'Plain English synthesis',
            ),
            'diagnosticSynthesisUr': Schema.string(
              description: 'Plain Urdu synthesis',
            ),
            'protocolRecommendationsEn': Schema.array(
              description: 'English steps',
              items: Schema.string(),
            ),
            'protocolRecommendationsUr': Schema.array(
              description: 'Urdu steps',
              items: Schema.string(),
            ),
            'clinicalObservations': Schema.array(
              description: 'Clinical observations',
              items: Schema.string(),
            ),
            'openFdaWarnings': Schema.string(
              description: 'FDA warnings in English',
              nullable: true,
            ),
            'openFdaWarningsUr': Schema.string(
              description: 'FDA warnings in Urdu',
              nullable: true,
            ),
          },
          optionalProperties: [
            'clinicalObservations',
            'openFdaWarnings',
            'openFdaWarningsUr',
          ],
        ),
        temperature: 0.2,
      ),
      systemInstruction: Content.system(
        'You are an expert Clinical Dermatologist and Localization Specialist. '
        'Synthesize lesion analysis, symptoms, and drug safety warnings into structured bilingual clinical evaluations in English and natural Urdu.',
      ),
    );
  }

  Future<TriageSummaryEntity> generateTriageSummary({
    required SkinAnalysisEntity skinAnalysis,
    required String symptoms,
    String? medication,
    String? drugSafetyDetails,
  }) async {
    final reportId = 'TR-${DateTime.now().millisecondsSinceEpoch}';
    final laymanTerm = ClinicalTerminologyMapper.mapToLayman(
      skinAnalysis.conditionName,
    );

    final bool isHealthySkin =
        skinAnalysis.conditionName == 'Normal / Healthy Skin Surface' ||
        skinAnalysis.conditionName.contains('Healthy Skin Surface') ||
        skinAnalysis.conditionName.contains('No Clear Lesion Detected');

    if (isHealthySkin) {
      return _buildSummaryEntity(
        reportId: reportId,
        skinAnalysis: skinAnalysis,
        symptoms: symptoms,
        medication: medication,
        riskLevel: 'Low',
        laymanTitleEn: laymanTerm.english,
        laymanTitleUr: laymanTerm.urdu,
        synthesisEn: 'No distinct dermatological lesion or mole detected with clinical certainty.',
        synthesisUr:
            'طبی یقین کے ساتھ جلد پر کوئی نمایاں داغ یا تل نہیں دیکھا گیا۔',
        recommendationsEn: [
          'Continue regular routine skin hydration and sun protection.',
          'Re-scan if any new mole or persistent itching develops.',
        ],
        recommendationsUr: [
          'جلد کو روزانہ موئسچرائز رکھیں اور سن اسکرین کا استعمال جاری رکھیں۔',
          'اگر کوئی نیا تل یا مسلسل خارش پیدا ہو تو دوبارہ اسکین کریں۔',
        ],
        observations: [
          'Dermatological Status: ${skinAnalysis.conditionName}',
          'Certainty Metric: ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}%',
          if (symptoms.trim().isNotEmpty)
            'Patient-Reported Context: "$symptoms"',
        ],
        fdaEn: drugSafetyDetails,
        fdaUr: _generateUrduFdaFallback(drugSafetyDetails, medication),
      );
    }

    final prompt = StringBuffer()
      ..writeln('PATIENT CLINICAL EVALUATION:')
      ..writeln(
        'Condition: ${skinAnalysis.conditionName} (${laymanTerm.english} /${laymanTerm.urdu})',
      )
      ..writeln(
        'Confidence: ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}%',
      )
      ..writeln('High Risk: ${skinAnalysis.isHighRisk}')
      ..writeln('Symptoms: "$symptoms"')
      ..writeln('Medication: ${medication ?? "None"}')
      ..writeln('FDA Warnings: ${drugSafetyDetails ?? "None"}');

    try {
      final response = await _getTriageModel().generateContent([
        Content.text(prompt.toString()),
      ]);
      final responseText = response.text;

      if (responseText != null && responseText.isNotEmpty) {
        final Map<String, dynamic> parsed =
            jsonDecode(responseText) as Map<String, dynamic>;

        return _buildSummaryEntity(
          reportId: reportId,
          skinAnalysis: skinAnalysis,
          symptoms: symptoms,
          medication: medication,
          riskLevel:
              parsed['riskLevel'] as String? ??
              (skinAnalysis.isHighRisk ? 'High' : 'Moderate'),
          laymanTitleEn:
              parsed['laymanTitleEn'] as String? ?? laymanTerm.english,
          laymanTitleUr: parsed['laymanTitleUr'] as String? ?? laymanTerm.urdu,
          synthesisEn: parsed['diagnosticSynthesisEn'] as String? ?? '',
          synthesisUr: parsed['diagnosticSynthesisUr'] as String? ?? '',
          recommendationsEn:
              (parsed['protocolRecommendationsEn'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          recommendationsUr:
              (parsed['protocolRecommendationsUr'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          observations:
              (parsed['clinicalObservations'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          fdaEn: parsed['openFdaWarnings'] as String? ?? drugSafetyDetails,
          fdaUr:
              parsed['openFdaWarningsUr'] as String? ??
              _generateUrduFdaFallback(drugSafetyDetails, medication),
        );
      }
    } catch (e) {
      debugPrint('[AiTriageDatasource] AI synthesis notice: $e');
    }

    return _buildClinicalFallback(
      reportId: reportId,
      skinAnalysis: skinAnalysis,
      symptoms: symptoms,
      medication: medication,
      drugSafetyDetails: drugSafetyDetails,
      laymanTerm: laymanTerm,
    );
  }

  TriageSummaryEntity _buildClinicalFallback({
    required String reportId,
    required SkinAnalysisEntity skinAnalysis,
    required String symptoms,
    required dynamic laymanTerm,
    String? medication,
    String? drugSafetyDetails,
  }) {
    final isMelanoma = skinAnalysis.conditionName.toLowerCase().contains(
      'melanoma',
    );
    final isEmergency = isMelanoma && skinAnalysis.confidence > 0.65;
    final riskLevel = isEmergency
        ? 'Emergency'
        : (skinAnalysis.isHighRisk ? 'High' : 'Moderate');

    return _buildSummaryEntity(
      reportId: reportId,
      skinAnalysis: skinAnalysis,
      symptoms: symptoms,
      medication: medication,
      riskLevel: riskLevel,
      laymanTitleEn: laymanTerm.english,
      laymanTitleUr: laymanTerm.urdu,
      synthesisEn:
          'Evaluation identified "${laymanTerm.english}" (${skinAnalysis.conditionName}) with ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% confidence.',
      synthesisUr:
          'طبی معائنے میں "${laymanTerm.urdu}" کی تشخیص ${(skinAnalysis.confidence * 100).toStringAsFixed(1)}% یقین کے ساتھ سامنے آئی ہے۔',
      recommendationsEn: isEmergency
          ? [
              'Urgent dermatologist consultation within 48 to 72 hours.',
              'Full-thickness excisional biopsy recommended.',
            ]
          : [
              'Schedule routine outpatient skin examination.',
              'Monitor ABCDE criteria.',
            ],
      recommendationsUr: isEmergency
          ? [
              '48 سے 72 گھنٹوں کے اندر ماہر امراض جلد سے فوری رجوع کریں۔',
              'تفصیلی بایوپسی ٹیسٹ کروائیں۔',
            ]
          : [
              'جلد کا معمول کا طبی معائنہ کروائیں۔',
              'تل کی ساخت میں تبدیلی پر نظر رکھیں۔',
            ],
      observations: [
        'Primary Condition: ${skinAnalysis.conditionName}',
        'Layman Classification: ${laymanTerm.english} /${laymanTerm.urdu}',
        'Malignancy Assessment: ${skinAnalysis.isHighRisk ? "Elevated Oncological Risk" : "Benign morphology"}',
        'Clinical Context: "$symptoms"',
      ],
      fdaEn: drugSafetyDetails,
      fdaUr: _generateUrduFdaFallback(drugSafetyDetails, medication),
    );
  }

  TriageSummaryEntity _buildSummaryEntity({
    required String reportId,
    required SkinAnalysisEntity skinAnalysis,
    required String symptoms,
    required String riskLevel,
    required String laymanTitleEn,
    required String laymanTitleUr,
    required String synthesisEn,
    required String synthesisUr,
    required List<String> recommendationsEn,
    required List<String> recommendationsUr,
    required List<String> observations,
    String? medication,
    String? fdaEn,
    String? fdaUr,
  }) {
    return TriageSummaryEntity(
      id: reportId,
      skinAnalysis: skinAnalysis,
      symptoms: symptoms,
      medication: medication,
      riskLevel: riskLevel,
      laymanTitleEn: laymanTitleEn,
      laymanTitleUr: laymanTitleUr,
      diagnosticSynthesisEn: synthesisEn,
      diagnosticSynthesisUr: synthesisUr,
      clinicalObservations: observations,
      openFdaWarnings: fdaEn,
      openFdaWarningsUr: fdaUr,
      protocolRecommendationsEn: recommendationsEn,
      protocolRecommendationsUr: recommendationsUr,
      a2uiPayload: {
        'surfaceId': 'skin_triage_surface',
        'catalogId': 'https://a2ui.org/catalogs/basic',
        'riskLevel': riskLevel,
        'laymanTitleEn': laymanTitleEn,
        'laymanTitleUr': laymanTitleUr,
        'synthesisEn': synthesisEn,
        'synthesisUr': synthesisUr,
        'observations': observations,
        'recommendationsEn': recommendationsEn,
        'recommendationsUr': recommendationsUr,
      },
      createdAt: DateTime.now(),
    );
  }

  String? _generateUrduFdaFallback(
    String? drugSafetyDetails,
    String? medication,
  ) {
    if (drugSafetyDetails == null || drugSafetyDetails.trim().isEmpty) {
      return null;
    }
    final medName = medication?.trim().isNotEmpty == true
        ? medication!.trim()
        : 'اس دوا';
    return 'ادویاتی حفاظتی انتباہ (FDA): $medName کے استعمال سے پہلے معالج سے مشورہ کریں۔';
  }
}

