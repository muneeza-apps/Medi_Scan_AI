import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/iot_vitals_model.dart';
import '../../../../core/models/scan_record_model.dart';
import '../../domain/domain.dart';

class ClinicalPdfGenerator {
  ClinicalPdfGenerator._();

  static const MethodChannel _mediaStoreChannel = MethodChannel(
    'com.mediscanai.app/media_store',
  );

  static Future<Uint8List> generateReportPdf({
    required TriageSummaryEntity summary,
    File? imageFile,
    String language = 'en',
    IotVitalsReading? vitals,
  }) async {
    final pdf = pw.Document(
      title: 'DermEdge Clinical Triage Handover - ${summary.id}',
      author: 'DermEdge Edge-AI Clinical Engine',
    );

    final isUrdu = language == 'ur';

    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    pw.Font? ttfUrdu;
    try {
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      ttfUrdu = pw.Font.ttf(fontData);
    } catch (_) {
      try {
        final fontData = await rootBundle.load(
          'assets/fonts/NotoNastaliqUrdu-Regular.ttf',
        );
        ttfUrdu = pw.Font.ttf(fontData);
      } catch (_) {
        ttfUrdu = null;
      }
    }

    final urduFont = ttfUrdu ?? baseFont;

    final pdfTheme = pw.ThemeData.withFont(
      base: isUrdu && ttfUrdu != null ? ttfUrdu : baseFont,
      bold: isUrdu && ttfUrdu != null ? ttfUrdu : boldFont,
      fontFallback: [?ttfUrdu, baseFont, boldFont],
    );

    Uint8List? imageBytes;
    if (imageFile != null && imageFile.existsSync()) {
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (_) {
        imageBytes = null;
      }
    }

    final caseId = summary.id.isNotEmpty
        ? 'CASE-${summary.id.substring(0, math.min(8, summary.id.length)).toUpperCase()}'
        : 'CASE-DEMO-001';

    final dateStr =
        '${summary.createdAt.year}-${summary.createdAt.month.toString().padLeft(2, '0')}-${summary.createdAt.day.toString().padLeft(2, '0')} '
        '${summary.createdAt.hour.toString().padLeft(2, '0')}:${summary.createdAt.minute.toString().padLeft(2, '0')} UTC';

    final synthesis = isUrdu
        ? (summary.diagnosticSynthesisUr.isNotEmpty
              ? summary.diagnosticSynthesisUr
              : summary.diagnosticSynthesis)
        : summary.diagnosticSynthesis;

    final recommendations = isUrdu
        ? (summary.protocolRecommendationsUr.isNotEmpty
              ? summary.protocolRecommendationsUr
              : summary.protocolRecommendations)
        : summary.protocolRecommendations;

    final drapWarnings = isUrdu
        ? (summary.openFdaWarningsUr ?? summary.openFdaWarnings)
        : summary.openFdaWarnings;

    const primaryTeal = PdfColor.fromInt(0xFF004D40);
    const accentMint = PdfColor.fromInt(0xFF00796B);
    const darkSlate = PdfColor.fromInt(0xFF1E293B);
    const lightSlate = PdfColor.fromInt(0xFF64748B);
    const backgroundGrey = PdfColor.fromInt(0xFFF8FAFC);
    const borderGrey = PdfColor.fromInt(0xFFE2E8F0);

    final (riskBgColor, riskTextColor, riskLabel) = switch (summary.riskLevel
        .toLowerCase()) {
      'emergency' => (
        const PdfColor.fromInt(0xFFFEF2F2),
        const PdfColor.fromInt(0xFFB91C1C),
        isUrdu ? 'فوری ایمرجنسی' : 'EMERGENCY RISK',
      ),
      'high' => (
        const PdfColor.fromInt(0xFFFFF7ED),
        const PdfColor.fromInt(0xFFC2410C),
        isUrdu ? 'اعلیٰ خطرہ' : 'HIGH RISK',
      ),
      'moderate' => (
        const PdfColor.fromInt(0xFFFFFBEB),
        const PdfColor.fromInt(0xFFB45309),
        isUrdu ? 'درمیانہ خطرہ' : 'MODERATE RISK',
      ),
      _ => (
        const PdfColor.fromInt(0xFFECFDF5),
        const PdfColor.fromInt(0xFF047857),
        isUrdu ? 'کم خطرہ یا محفوظ' : 'LOW RISK / BENIGN',
      ),
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pdfTheme,
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: primaryTeal,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MEDISCAN AI // CLINICAL HANDOVER',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      if (isUrdu)
                        buildUrduText(
                          'طبی فیصلے میں معاون نظام برائے جلدی امراض',
                          font: urduFont,
                          fontSize: 8.5,
                          color: const PdfColor.fromInt(0xFFB2DFDB),
                          textAlign: pw.TextAlign.left,
                        )
                      else
                        pw.Text(
                          'Autonomous Dermatological Triage & Decision Support System',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColor.fromInt(0xFFB2DFDB),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFF00796B),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'CONFIDENTIAL // CDS',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 7.5,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Ref: $caseId',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        dateStr,
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColor.fromInt(0xFFB2DFDB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: backgroundGrey,
                border: pw.Border.all(color: borderGrey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (isUrdu)
                          buildUrduText(
                            'مریض کی علامات',
                            font: urduFont,
                            fontSize: 8,
                            color: lightSlate,
                            textAlign: pw.TextAlign.left,
                          )
                        else
                          pw.Text(
                            'PRESENTING SYMPTOMS',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8,
                              color: lightSlate,
                            ),
                          ),
                        pw.SizedBox(height: 2),
                        if (isUrdu)
                          buildUrduText(
                            summary.symptoms.isNotEmpty
                                ? summary.symptoms
                                : 'کوئی مخصوص علامات درج نہیں کی گئیں',
                            font: urduFont,
                            fontSize: 9.5,
                            color: darkSlate,
                            textAlign: pw.TextAlign.left,
                          )
                        else
                          pw.Text(
                            summary.symptoms.isNotEmpty
                                ? summary.symptoms
                                : 'No specific symptoms entered',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 9.5,
                              color: darkSlate,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 28,
                    color: borderGrey,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (isUrdu)
                          buildUrduText(
                            'موجودہ ادویات',
                            font: urduFont,
                            fontSize: 8,
                            color: lightSlate,
                            textAlign: pw.TextAlign.left,
                          )
                        else
                          pw.Text(
                            'ACTIVE MEDICATIONS',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8,
                              color: lightSlate,
                            ),
                          ),
                        pw.SizedBox(height: 2),
                        if (isUrdu)
                          (summary.medication?.isNotEmpty == true
                              ? pw.Text(
                                  summary.medication!,
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 9.5,
                                    color: darkSlate,
                                  ),
                                )
                              : buildUrduText(
                                  'کوئی نہیں',
                                  font: urduFont,
                                  fontSize: 9.5,
                                  color: darkSlate,
                                  textAlign: pw.TextAlign.left,
                                ))
                        else
                          pw.Text(
                            summary.medication?.isNotEmpty == true
                                ? summary.medication!
                                : 'None Reported',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 9.5,
                              color: darkSlate,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 28,
                    color: borderGrey,
                    margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (isUrdu)
                          buildUrduText(
                            'ٹرائیج خطرہ',
                            font: urduFont,
                            fontSize: 8,
                            color: lightSlate,
                            textAlign: pw.TextAlign.left,
                          )
                        else
                          pw.Text(
                            'TRIAGE RISK TIER',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8,
                              color: lightSlate,
                            ),
                          ),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: riskBgColor,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: isUrdu
                              ? buildUrduText(
                                  riskLabel,
                                  font: urduFont,
                                  fontSize: 8.5,
                                  color: riskTextColor,
                                  textAlign: pw.TextAlign.center,
                                )
                              : pw.Text(
                                  riskLabel,
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8.5,
                                    color: riskTextColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 110,
                  height: 110,
                  decoration: pw.BoxDecoration(
                    color: backgroundGrey,
                    border: pw.Border.all(color: borderGrey),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  alignment: pw.Alignment.center,
                  child: imageBytes != null
                      ? pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(
                            pw.MemoryImage(imageBytes),
                            fit: pw.BoxFit.cover,
                            width: 110,
                            height: 110,
                          ),
                        )
                      : pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              '[ LESION IMAGE ]',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8,
                                color: lightSlate,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Standard 224x224 ROI',
                              style: const pw.TextStyle(
                                fontSize: 6.5,
                                color: lightSlate,
                              ),
                            ),
                          ],
                        ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: backgroundGrey,
                      border: pw.Border.all(color: borderGrey),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            if (isUrdu)
                              buildUrduText(
                                summary.skinAnalysis.isIndeterminate
                                    ? 'غیر حتمی تشخیصی جائزہ'
                                    : (summary
                                              .skinAnalysis
                                              .isDifferentialAssessment
                                          ? 'متبادل تفریقی جائزہ (Top-3)'
                                          : 'بنیادی تشخیصی نتیجہ'),
                                font: urduFont,
                                fontSize: 8,
                                color: lightSlate,
                                textAlign: pw.TextAlign.left,
                              )
                            else
                              pw.Text(
                                summary.skinAnalysis.isIndeterminate
                                    ? 'INDETERMINATE OVERLAPPING PATTERNS (<55%)'
                                    : (summary
                                              .skinAnalysis
                                              .isDifferentialAssessment
                                          ? 'TOP-3 DIFFERENTIAL ASSESSMENT (<65%)'
                                          : 'PRIMARY CLINICAL INFERENCE'),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                  color: lightSlate,
                                ),
                              ),
                            pw.Text(
                              '${(summary.skinAnalysis.confidence * 100).toStringAsFixed(1)}% Certainty',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8.5,
                                color: accentMint,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),

                        pw.Text(
                          summary
                                  .skinAnalysis
                                  .taxonomy
                                  .benchmarkScientificName
                                  .isNotEmpty
                              ? summary
                                    .skinAnalysis
                                    .taxonomy
                                    .benchmarkScientificName
                              : summary.skinAnalysis.conditionName,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: darkSlate,
                          ),
                        ),
                        pw.SizedBox(height: 2),

                        pw.Text(
                          'Plain Vernacular: ${summary.skinAnalysis.taxonomy.plainVernacularEn}',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 9,
                            color: accentMint,
                          ),
                        ),
                        pw.SizedBox(height: 2),

                        buildUrduText(
                          summary.skinAnalysis.taxonomy.regionalUrduContext,
                          font: urduFont,
                          fontSize: 9.5,
                          color: const PdfColor.fromInt(0xFF0F766E),
                          textAlign: pw.TextAlign.left,
                        ),
                        if (summary.skinAnalysis.isSeverePathology ||
                            summary.skinAnalysis.criticalReferralWarningEn !=
                                null) ...[
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFFEF2F2),
                              border: pw.Border.all(
                                color: const PdfColor.fromInt(0xFFDC2626),
                                width: 1,
                              ),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Critical Medical Alert: Consult a Certified Dermatologist / Hospital Immediately',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 7.5,
                                    color: const PdfColor.fromInt(0xFFB91C1C),
                                  ),
                                ),
                                pw.SizedBox(height: 1),
                                buildUrduText(
                                  'فوری طور پر ماہر امراض جلد سے رجوع کریں (لازمی طبی ہدایت)',
                                  font: urduFont,
                                  fontSize: 7.5,
                                  color: const PdfColor.fromInt(0xFFB91C1C),
                                  textAlign: pw.TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Stack(
                          children: [
                            pw.Container(
                              height: 6,
                              decoration: pw.BoxDecoration(
                                color: borderGrey,
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                            pw.Container(
                              height: 6,
                              width:
                                  320 *
                                  summary.skinAnalysis.confidence.clamp(
                                    0.0,
                                    1.0,
                                  ),
                              decoration: pw.BoxDecoration(
                                color: summary.skinAnalysis.confidence >= 0.75
                                    ? accentMint
                                    : const PdfColor.fromInt(0xFFD97706),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        if (summary.skinAnalysis.explanation != null)
                          if (isUrdu)
                            buildUrduText(
                              summary.skinAnalysis.explanation!,
                              font: urduFont,
                              fontSize: 7.5,
                              color: lightSlate,
                              textAlign: pw.TextAlign.left,
                            )
                          else
                            pw.Text(
                              summary.skinAnalysis.explanation!,
                              style: const pw.TextStyle(
                                fontSize: 7.5,
                                color: lightSlate,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            if (summary.skinAnalysis.differentialDiagnoses.isNotEmpty) ...[
              if (isUrdu)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    buildUrduText(
                      'متبادل تفریقی تشخیصات',
                      font: urduFont,
                      fontSize: 8.5,
                      color: darkSlate,
                    ),
                    pw.Text(
                      'DIFFERENTIAL DIAGNOSES (MEDISCAN AI)',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 7.5,
                        color: lightSlate,
                      ),
                    ),
                  ],
                )
              else
                pw.Text(
                  'DIFFERENTIAL DIAGNOSIS BREAKDOWN (MEDISCAN AI SKIN TAXONOMY)',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8.5,
                    color: darkSlate,
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: borderGrey, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE2E8F0),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '#',
                          style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Condition / Morphological Pattern',
                          style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: isUrdu
                            ? pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Layman Nomenclature',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
                                  ),
                                  buildUrduText(
                                    'عام فہم نام',
                                    font: urduFont,
                                    fontSize: 7,
                                    color: darkSlate,
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ],
                              )
                            : pw.Text(
                                'Layman Nomenclature',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 7.5,
                                ),
                              ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Probability',
                          style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                        ),
                      ),
                    ],
                  ),
                  ...summary.skinAnalysis.differentialDiagnoses.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key + 1;
                        final item = entry.value;
                        final layName = ClinicalTerminologyMapper.mapToLayman(
                          item.key,
                        );
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: index.isEven
                                ? const PdfColor.fromInt(0xFFFAFAFA)
                                : PdfColors.white,
                          ),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text(
                                '$index',
                                style: const pw.TextStyle(fontSize: 7.5),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text(
                                item.key,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 7.5,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: isUrdu
                                  ? pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        buildUrduText(
                                          layName.urdu,
                                          font: urduFont,
                                          fontSize: 7.5,
                                          color: darkSlate,
                                          textAlign: pw.TextAlign.left,
                                        ),
                                        pw.Text(
                                          layName.english,
                                          style: const pw.TextStyle(
                                            fontSize: 6.5,
                                            color: lightSlate,
                                          ),
                                        ),
                                      ],
                                    )
                                  : pw.Text(
                                      layName.english,
                                      style: const pw.TextStyle(fontSize: 7.5),
                                    ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3.5),
                              child: pw.Text(
                                '${(item.value * 100).toStringAsFixed(1)}%',
                                style: const pw.TextStyle(fontSize: 7.5),
                              ),
                            ),
                          ],
                        );
                      }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: backgroundGrey,
                border: pw.Border.all(color: borderGrey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CLINICAL VITALS SUMMARY // HEMODYNAMIC BASELINE',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 7.5,
                          color: accentMint,
                        ),
                      ),
                      pw.Text(
                        vitals != null && vitals.isValid
                            ? 'BIOMETRIC RECORD LINKED'
                            : 'STANDALONE / NOMINAL READINGS',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 7,
                          color: vitals != null && vitals.isValid ? accentMint : lightSlate,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildVitalBlock(
                        label: 'Oxygen Saturation (SpO₂)',
                        value: vitals != null && vitals.isValid
                            ? '${vitals.spo2}% (${vitals.isHypoxic ? "Hypoxic" : "Normal"})'
                            : (summary.a2uiPayload?['spo2']?.toString() ??
                                  '98% (Normative)'),
                        status: vitals != null && vitals.isValid
                            ? (vitals.isHypoxic ? 'Hypoxic' : 'Normal')
                            : 'Normal',
                        boldFont: boldFont,
                      ),
                      pw.Container(width: 1, height: 22, color: borderGrey),
                      _buildVitalBlock(
                        label: 'Heart Rate (Pulse)',
                        value: vitals != null && vitals.isValid
                            ? '${vitals.heartRate} BPM (${vitals.isTachycardic ? "Tachycardia" : (vitals.isBradycardic ? "Bradycardia" : "Sinus")})'
                            : (summary.a2uiPayload?['heart_rate']?.toString() ??
                                  '74 BPM (Sinus)'),
                        status: vitals != null && vitals.isValid
                            ? (vitals.isTachycardic ? 'Elevated' : (vitals.isBradycardic ? 'Slow' : 'Stable'))
                            : 'Stable',
                        boldFont: boldFont,
                      ),
                      pw.Container(width: 1, height: 22, color: borderGrey),
                      _buildVitalBlock(
                        label: 'Peripheral Body Temperature',
                        value: vitals != null && vitals.isValid
                            ? '${vitals.skinTemperature.toStringAsFixed(1)}°C (${vitals.isFebrile ? "Febrile" : "Afebrile"})'
                            : (summary.a2uiPayload?['body_temp']?.toString() ??
                                  '36.8°C (Afebrile)'),
                        status: vitals != null && vitals.isValid
                            ? (vitals.isFebrile ? 'Febrile' : 'Optimal')
                            : 'Optimal',
                        boldFont: boldFont,
                      ),
                    ],
                  ),
                  if (vitals != null &&
                      vitals.isValid &&
                      vitals.isCriticalVitals) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFEF2F2),
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFFDC2626),
                          width: 0.8,
                        ),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            'SYSTEMIC DISTRESS ALERT: Possible Systemic Distress Flagged (Urgent Hospital Referral Required)',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 6.5,
                              color: const PdfColor.fromInt(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            if (synthesis.isNotEmpty ||
                summary.clinicalObservations.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: backgroundGrey,
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (isUrdu)
                      buildUrduText(
                        'کلینیکل مشاہدات اور تفصیلی جائزہ',
                        font: urduFont,
                        fontSize: 8.5,
                        color: darkSlate,
                        textAlign: pw.TextAlign.left,
                      )
                    else
                      pw.Text(
                        'CLINICAL OBSERVATIONS & DIAGNOSTIC SYNTHESIS',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: darkSlate,
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    if (synthesis.isNotEmpty) ...[
                      if (isUrdu)
                        buildUrduText(
                          synthesis,
                          font: urduFont,
                          fontSize: 8,
                          color: darkSlate,
                          textAlign: pw.TextAlign.left,
                        )
                      else
                        pw.Text(
                          synthesis,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: darkSlate,
                            lineSpacing: 1.5,
                          ),
                        ),
                      pw.SizedBox(height: 6),
                    ],
                    if (summary.clinicalObservations.isNotEmpty) ...[
                      ...summary.clinicalObservations.map((obs) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                width: 3.5,
                                height: 3.5,
                                margin: const pw.EdgeInsets.only(
                                  top: 3.5,
                                  right: 5,
                                ),
                                decoration: const pw.BoxDecoration(
                                  color: accentMint,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.Expanded(
                                child: isUrdu
                                    ? buildUrduText(
                                        obs,
                                        font: urduFont,
                                        fontSize: 7.5,
                                        color: darkSlate,
                                        textAlign: pw.TextAlign.left,
                                      )
                                    : pw.Text(
                                        obs,
                                        style: const pw.TextStyle(
                                          fontSize: 7.5,
                                          color: darkSlate,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],
            if (summary.skinAnalysis.isSeverePathology) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFEF2F2),
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFDC2626),
                    width: 1.2,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CRITICAL MEDICAL PROTOCOL: OTC MEDICATIONS STRICTLY WITHHELD',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: const PdfColor.fromInt(0xFF991B1B),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Critical Medical Alert: Consult a Certified Dermatologist / Hospital Immediately. High-risk lesion detected; no self-care topical medications permitted.',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColor.fromInt(0xFF7F1D1D),
                        lineSpacing: 1.4,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    buildUrduText(
                      'فوری طور پر ماہر امراض جلد سے رجوع کریں - کسی قسم کی خود ساختہ ادویات استعمال نہ کریں',
                      font: urduFont,
                      fontSize: 8,
                      color: const PdfColor.fromInt(0xFF991B1B),
                      textAlign: pw.TextAlign.left,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ] else if (drapWarnings != null && drapWarnings.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: backgroundGrey,
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (isUrdu)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          buildUrduText(
                            'ڈریپ (DRAP) تصدیق شدہ ادویاتی معلومات اور حفاظتی انتباہ',
                            font: urduFont,
                            fontSize: 8.5,
                            color: primaryTeal,
                          ),
                          pw.Text(
                            'DRAP OTC PHARMACOLOGY',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 7,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      )
                    else
                      pw.Text(
                        'DRAP (PAKISTAN) FORMULARY & PHARMACOVIGILANCE GUIDANCE',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: primaryTeal,
                        ),
                      ),
                    pw.SizedBox(height: 3),
                    if (isUrdu)
                      buildUrduText(
                        drapWarnings,
                        font: urduFont,
                        fontSize: 7.5,
                        color: darkSlate,
                        textAlign: pw.TextAlign.left,
                      )
                    else
                      pw.Text(
                        drapWarnings,
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: darkSlate,
                          lineSpacing: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],
            if (recommendations.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: backgroundGrey,
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (isUrdu)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          buildUrduText(
                            'مریض اور معالج کے لیے ضروری اقدامات',
                            font: urduFont,
                            fontSize: 8.5,
                            color: darkSlate,
                          ),
                          pw.Text(
                            'CLINICAL PROTOCOL',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 7,
                              color: lightSlate,
                            ),
                          ),
                        ],
                      )
                    else
                      pw.Text(
                        'ACTIONABLE CLINICAL RECOMMENDATIONS',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: darkSlate,
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    ...recommendations.asMap().entries.map((e) {
                      final idx = e.key + 1;
                      final rec = e.value;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 12,
                              height: 12,
                              decoration: const pw.BoxDecoration(
                                color: accentMint,
                                shape: pw.BoxShape.circle,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '$idx',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  font: boldFont,
                                  fontSize: 6.5,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Expanded(
                              child: isUrdu
                                  ? buildUrduText(
                                      rec,
                                      font: urduFont,
                                      fontSize: 7.5,
                                      color: darkSlate,
                                      textAlign: pw.TextAlign.left,
                                    )
                                  : pw.Text(
                                      rec,
                                      style: const pw.TextStyle(
                                        fontSize: 7.5,
                                        color: darkSlate,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderGrey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (isUrdu)
                    buildUrduText(
                      'طبی حفاظتی نوٹس اور قانونی انتباہ',
                      font: urduFont,
                      fontSize: 6.5,
                      color: lightSlate,
                      textAlign: pw.TextAlign.left,
                    )
                  else
                    pw.Text(
                      'REGULATORY & CLINICAL SAFETY NOTICE:',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 6.5,
                        color: lightSlate,
                      ),
                    ),
                  pw.SizedBox(height: 2),
                  if (isUrdu)
                    buildUrduText(
                      'میڈی اسکین خودکار طور پر جلدی امراض کی ابتدائی اسکریننگ فراہم کرتا ہے۔ یہ دستاویز معالجاتی کام میں معاونت کے لیے ہے اور کسی مستند ڈاکٹر کے باضابطہ معائنے یا بائیوپسی کا نعم البدل نہیں ہے۔ تمام معالجاتی اقدامات کسی لائسنس یافتہ ڈاکٹر کی تصدیق کے بعد ہی کیے جانے چاہئیں۔',
                      font: urduFont,
                      fontSize: 6,
                      color: lightSlate,
                      textAlign: pw.TextAlign.left,
                    )
                  else
                    pw.Text(
                      'MediScan AI provides automated screening and risk triage based on deep convolutional neural networks and clinical guidelines. '
                      'This document is designed exclusively to augment clinical workflow and does not supersede professional in-person dermoscopy, '
                      'histopathology, or specialist consultation. All medical interventions must be sanctioned by a licensed physician.',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: lightSlate,
                        lineSpacing: 1.3,
                      ),
                    ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 170, height: 1, color: darkSlate),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Attending Physician / Specialist Reviewer',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 7,
                              color: darkSlate,
                            ),
                          ),
                          if (isUrdu)
                            buildUrduText(
                              'معالج یا ماہر امراض جلد کے دستخط',
                              font: urduFont,
                              fontSize: 6.5,
                              color: darkSlate,
                              textAlign: pw.TextAlign.left,
                            ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 100, height: 1, color: darkSlate),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Date & Timestamp',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 7,
                              color: darkSlate,
                            ),
                          ),
                          if (isUrdu)
                            buildUrduText(
                              'تاریخ اور وقت',
                              font: urduFont,
                              fontSize: 6.5,
                              color: darkSlate,
                              textAlign: pw.TextAlign.left,
                            ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 110, height: 1, color: darkSlate),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Medical License / Registration #',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 7,
                              color: darkSlate,
                            ),
                          ),
                          if (isUrdu)
                            buildUrduText(
                              'میڈیکل لائسنس یا رجسٹریشن نمبر',
                              font: urduFont,
                              fontSize: 6.5,
                              color: darkSlate,
                              textAlign: pw.TextAlign.left,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget buildUrduText(
    String text, {
    required pw.Font font,
    double fontSize = 9,
    PdfColor? color,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    final cleanText = text
        .replaceAll('/', ' ')
        .replaceAll(':', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .trim();

    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        cleanText,
        textAlign: textAlign,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color,
          lineSpacing: 2.0,
        ),
      ),
    );
  }

  static pw.Widget _buildVitalBlock({
    required String label,
    required String value,
    required String status,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 6.5,
            color: PdfColor.fromInt(0xFF64748B),
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 8.5,
            color: const PdfColor.fromInt(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  static Future<Uint8List> generateLesionProgressionPdf({
    required ScanRecord baseline,
    required ScanRecord followUp,
    required String stabilityStatus,
    required Map<String, String> abcdeDelta,
    String language = 'en',
  }) async {
    final pdf = pw.Document(
      title:
          'MediScan AI Lesion Progression Analysis - ${baseline.id} vs ${followUp.id}',
      author: 'MediScan AI Clinical Engine',
    );

    final isUrdu = language == 'ur';
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    pw.Font? ttfUrdu;
    try {
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      ttfUrdu = pw.Font.ttf(fontData);
    } catch (_) {
      try {
        final fontData = await rootBundle.load(
          'assets/fonts/NotoNastaliqUrdu-Regular.ttf',
        );
        ttfUrdu = pw.Font.ttf(fontData);
      } catch (_) {
        ttfUrdu = null;
      }
    }

    final pdfTheme = pw.ThemeData.withFont(
      base: isUrdu && ttfUrdu != null ? ttfUrdu : baseFont,
      bold: isUrdu && ttfUrdu != null ? ttfUrdu : boldFont,
      fontFallback: [?ttfUrdu, baseFont, boldFont],
    );

    Uint8List? baselineImage;
    if (baseline.thumbnailPath.isNotEmpty &&
        File(baseline.thumbnailPath).existsSync()) {
      try {
        baselineImage = await File(baseline.thumbnailPath).readAsBytes();
      } catch (_) {}
    }

    Uint8List? followUpImage;
    if (followUp.thumbnailPath.isNotEmpty &&
        File(followUp.thumbnailPath).existsSync()) {
      try {
        followUpImage = await File(followUp.thumbnailPath).readAsBytes();
      } catch (_) {}
    }

    final daysDiff = followUp.dateTime
        .difference(baseline.dateTime)
        .inDays
        .abs();
    const primaryTeal = PdfColor.fromInt(0xFF004D40);
    const accentMint = PdfColor.fromInt(0xFF00796B);
    const darkSlate = PdfColor.fromInt(0xFF1E293B);
    const lightSlate = PdfColor.fromInt(0xFF64748B);
    const borderGrey = PdfColor.fromInt(0xFFE2E8F0);

    final isEvolution =
        stabilityStatus.toLowerCase().contains('evolution') ||
        followUp.riskLevel.toLowerCase() == 'high';

    final stabilityBg = isEvolution
        ? const PdfColor.fromInt(0xFFFEF2F2)
        : const PdfColor.fromInt(0xFFF0FDF4);
    final stabilityText = isEvolution
        ? const PdfColor.fromInt(0xFFB91C1C)
        : const PdfColor.fromInt(0xFF15803D);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pdfTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const pw.BoxDecoration(
                  color: primaryTeal,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isUrdu ? 'میڈی اسکین AI: تقابلی ارتقائی تجزیہ' : 'MEDISCAN AI: LESION PROGRESSION & TIMELINE COMPARISON',
                          style: pw.TextStyle(
                            font: boldFont,
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          isUrdu ? 'ڈرمیٹولوجیکل موازنہ برائے معالج' : 'Dermatological Comparative Handover for Attending Physician',
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFFB2DFDB),
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: accentMint,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Text(
                        isUrdu
                            ? '$daysDiff دن کا وقفہ'
                            : '$daysDiff Days Elapsed',
                        style: pw.TextStyle(
                          font: boldFont,
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: stabilityBg,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                  border: pw.Border.all(color: stabilityText, width: 1.2),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isUrdu
                          ? 'ارتقائی استحکام کا درجہ:'
                          : 'Clinical Progression Status:',
                      style: pw.TextStyle(
                        font: boldFont,
                        color: darkSlate,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      stabilityStatus,
                      style: pw.TextStyle(
                        font: boldFont,
                        color: stabilityText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                        border: pw.Border.all(color: borderGrey),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isUrdu
                                ? 'بنیادی اسکین (Baseline)'
                                : 'BASELINE SCAN (INITIAL)',
                            style: pw.TextStyle(
                              font: boldFont,
                              color: primaryTeal,
                              fontSize: 9.5,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          if (baselineImage != null)
                            pw.Center(
                              child: pw.Container(
                                height: 90,
                                width: 90,
                                decoration: const pw.BoxDecoration(
                                  borderRadius: pw.BorderRadius.all(
                                    pw.Radius.circular(6),
                                  ),
                                ),
                                child: pw.Image(
                                  pw.MemoryImage(baselineImage),
                                  fit: pw.BoxFit.cover,
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            '${isUrdu ? "تاریخ: " : "Date: "} ${baseline.dateTime.day}/${baseline.dateTime.month}/${baseline.dateTime.year}',
                          ),
                          pw.Text(
                            '${isUrdu ? "تشخیص: " : "Diagnosis: "} ${baseline.lesionName}',
                          ),
                          pw.Text(
                            '${isUrdu ? "مقام: " : "Site: "} ${baseline.anatomicalLocation ?? "Not specified"}',
                          ),
                          pw.Text(
                            '${isUrdu ? "خطرے کی سطح: " : "Risk Level: "} ${baseline.riskLevel}',
                          ),
                          pw.Text(
                            '${isUrdu ? "یقین: " : "Certainty: "} ${(baseline.confidenceScore * 100).toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                        border: pw.Border.all(color: borderGrey),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            isUrdu
                                ? 'فالو اپ اسکین (Follow-up)'
                                : 'FOLLOW-UP SCAN (CURRENT)',
                            style: pw.TextStyle(
                              font: boldFont,
                              color: accentMint,
                              fontSize: 9.5,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          if (followUpImage != null)
                            pw.Center(
                              child: pw.Container(
                                height: 90,
                                width: 90,
                                decoration: const pw.BoxDecoration(
                                  borderRadius: pw.BorderRadius.all(
                                    pw.Radius.circular(6),
                                  ),
                                ),
                                child: pw.Image(
                                  pw.MemoryImage(followUpImage),
                                  fit: pw.BoxFit.cover,
                                ),
                              ),
                            ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            '${isUrdu ? "تاریخ: " : "Date: "} ${followUp.dateTime.day}/${followUp.dateTime.month}/${followUp.dateTime.year}',
                          ),
                          pw.Text(
                            '${isUrdu ? "تشخیص: " : "Diagnosis: "} ${followUp.lesionName}',
                          ),
                          pw.Text(
                            '${isUrdu ? "مقام: " : "Site: "} ${followUp.anatomicalLocation ?? "Not specified"}',
                          ),
                          pw.Text(
                            '${isUrdu ? "خطرے کی سطح: " : "Risk Level: "} ${followUp.riskLevel}',
                          ),
                          pw.Text(
                            '${isUrdu ? "یقین: " : "Certainty: "} ${(followUp.confidenceScore * 100).toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                isUrdu
                    ? 'ABCDE کلینیکل موازنہ اور مشاہدات:'
                    : 'ABCDE CLINICAL EVOLUTION DELTA:',
                style: pw.TextStyle(
                  font: boldFont,
                  color: darkSlate,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGrey),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Column(
                  children: abcdeDelta.entries.map((entry) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: borderGrey, width: 0.5),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 140,
                            child: pw.Text(
                              entry.key,
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 8.5,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              entry.value,
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: darkSlate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  isUrdu
                      ? 'نوٹ: یہ تقابلی رپورٹ خودکار الگورتھم کی مدد سے تیار کی گئی ہے۔ حتمی تشخیص اور بایوپسی کے فیصلے کے لیے معالج کا ذاتی معائنہ ضروری ہے۔'
                      : 'Clinical Notice: This comparative progression summary evaluates objective morphology changes between two capture intervals. Definitive diagnosis requires in-person clinical dermoscopy and histopathological biopsy where indicated.',
                  style: const pw.TextStyle(fontSize: 7.5, color: lightSlate),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static Future<({String path, String? uri, String fileName})> savePdf({
    required Uint8List pdfBytes,
    required String fileName,
    Directory? targetDirectory,
  }) async {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fullFileName = sanitizedName.endsWith('.pdf')
        ? sanitizedName
        : '$sanitizedName.pdf';

    if (Platform.isAndroid && targetDirectory == null) {
      try {
        final result = await _mediaStoreChannel
            .invokeMapMethod<String, dynamic>('saveToDownloads', {
              'fileName': sanitizedName,
              'bytes': pdfBytes,
            });
        if (result != null) {
          return (
            path: result['path'] as String? ?? 'Downloads/$fullFileName',
            uri: result['uri'] as String?,
            fileName: result['fileName'] as String? ?? fullFileName,
          );
        }
      } catch (_) {}
    }

    Directory dir;
    if (targetDirectory != null) {
      dir = targetDirectory;
    } else {
      try {
        if (Platform.isAndroid) {
          dir =
              (await getExternalStorageDirectory()) ??
              await getApplicationDocumentsDirectory();
        } else {
          dir =
              (await getDownloadsDirectory()) ??
              await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        dir = Directory.systemTemp;
      }
    }

    final file = File('${dir.path}/$fullFileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return (
      path: file.path,
      uri: Uri.file(file.path).toString(),
      fileName: fullFileName,
    );
  }

  static Future<void> openPdf(String uriOrPath) async {
    if (Platform.isAndroid) {
      try {
        await _mediaStoreChannel.invokeMethod('openPdf', {'uri': uriOrPath});
      } catch (_) {}
    }
  }

  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    Directory tempDir;
    try {
      tempDir = await getTemporaryDirectory();
    } catch (_) {
      tempDir = Directory.systemTemp;
    }
    final file = File('${tempDir.path}/$sanitizedName.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'MediScan AI Clinical Triage Handover',
      ),
    );
  }
}
