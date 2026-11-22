import 'package:flutter/material.dart';
import 'package:mediscanai/core/services/locale_service.dart';

import '../../domain/domain.dart';

class SingleDiagnosisCard extends StatelessWidget {
  final SkinAnalysisEntity skinAnalysis;
  final bool? isUrdu;
  final VoidCallback? onRetakePhoto;
  final VoidCallback? onLanguageToggle;

  const SingleDiagnosisCard({
    super.key,
    required this.skinAnalysis,
    this.isUrdu,
    this.onRetakePhoto,
    this.onLanguageToggle,
  });

  bool get _isUrdu => isUrdu ?? LocaleService.isUrdu;

  @override
  Widget build(BuildContext context) {

    if (skinAnalysis.isNonSkin ||
        skinAnalysis.tier == TriageTier.universalInconclusive ||
        skinAnalysis.tier == TriageTier.nonSkin ||
        skinAnalysis.conditionName == 'Invalid or Inconclusive Scan' ||
        skinAnalysis.conditionName == 'non_skin' ||
        skinAnalysis.conditionName == 'Non-Skin Surface Detected') {
      return _buildUniversalInconclusiveCard(context);
    }

    if (skinAnalysis.isIndeterminate || skinAnalysis.confidence < 0.20) {
      return _buildIndeterminateGuardrailCard(context);
    }

    if (skinAnalysis.isDifferentialAssessment || skinAnalysis.confidence < 0.32) {
      return _buildDifferentialAssessmentCard(context);
    }

    return _buildHighConfidenceLesionCard(context);
  }

  Widget _buildUniversalInconclusiveCard(BuildContext context) {
    final urduName = skinAnalysis.friendlyNameUr.isNotEmpty
        ? skinAnalysis.friendlyNameUr
        : 'ناقابل قبول یا غیر واضح اسکین';
    final enName = skinAnalysis.friendlyNameEn.isNotEmpty
        ? skinAnalysis.friendlyNameEn
        : 'Invalid or Inconclusive Scan';
    final title = _isUrdu ? urduName : enName;
    final badge = _isUrdu ? 'نامنظور' : 'Scan Not Accepted';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isUrdu ? 'کیفیتِ اسکین' : 'Scan Status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: _isUrdu ? 17 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF92400E),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isUrdu
                            ? (skinAnalysis.instructionUr.isNotEmpty
                                ? skinAnalysis.instructionUr
                                : 'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔')
                            : (skinAnalysis.instructionEn.isNotEmpty
                                ? skinAnalysis.instructionEn
                                : 'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isUrdu
                            ? (skinAnalysis.instructionEn.isNotEmpty
                                ? skinAnalysis.instructionEn
                                : 'The system could not detect valid human skin. Electronics, dark gadgets, and synthetic objects are rejected.')
                            : (skinAnalysis.instructionUr.isNotEmpty
                                ? skinAnalysis.instructionUr
                                : 'سسٹم انسانی جلد کی تصدیق نہیں کر سکا۔ الیکٹرانکس، سیاہ آلات اور مصنوعی اشیاء مسترد کی جاتی ہیں۔'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isUrdu
                ? 'یہ اسکین قبول نہیں کیے جاتے:'
                : 'What We Do NOT Accept:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              children: [
                _buildChecklistItem(
                  titleEn: 'Non-skin objects (Electronics, clothing, pets, papers, furniture)',
                  titleUr: 'غیر جلدی اشیاء (گیجٹس، کپڑے، کاغذ یا فرنیچر)',
                ),
                const Divider(height: 12, color: Color(0xFFFEF3C7)),
                _buildChecklistItem(
                  titleEn: 'Full body / Distant photos',
                  titleUr: 'دور سے لی گئی تصویر جہاں داغ واضح نہ ہو',
                ),
                const Divider(height: 12, color: Color(0xFFFEF3C7)),
                _buildChecklistItem(
                  titleEn: 'Blurry, dark, or shaded images',
                  titleUr: 'دھندلی، اندھیرے یا سائے میں لی گئی تصاویر',
                ),
                const Divider(height: 12, color: Color(0xFFFEF3C7)),
                _buildChecklistItem(
                  titleEn: 'Completely clean skin with no visible marks',
                  titleUr: 'بغیر کسی نشان یا الرجی والی بالکل صاف جلد',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String titleEn,
    required String titleUr,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('❌', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isUrdu ? titleUr : titleEn,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndeterminateGuardrailCard(BuildContext context) {
    final title = _isUrdu ? 'غیر حتمی اسکین' : 'Indeterminate Scan';

    final topList = skinAnalysis.topPredictions.isNotEmpty
        ? skinAnalysis.topPredictions.take(3).toList()
        : <SkinPrediction>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isUrdu ? 'حفاظتی گارڈ ریل' : 'Clinical Safety Guardrail',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Text(
                  '< 22% Confidence',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: _isUrdu ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF78350F),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isUrdu
                        ? 'ماڈل کا تشخیصی یقین محفوظ حد (<22%) سے کم ہے۔ غلط تشخیص سے بچاؤ کے لیے کلینیکل گارڈ ریل کے تحت قطعی نتیجہ روک دیا گیا ہے۔ برائے مہربانی یکساں اور براہِ راست روشنی میں دوبارہ تصویر لیں یا مستند ماہر امراض جلد سے رجوع کریں۔'
                        : 'Top inference confidence is below the threshold (<22%). Under DermEdge clinical safety guardrails, singular diagnostic assertions are strictly withheld to prevent misclassification. Please reposition under direct, even room lighting or consult a certified dermatologist.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF78350F),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (topList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _isUrdu
                  ? 'امکانی تفریقی صورتیں:'
                  : 'Top-3 Differential Classes:',
              style: TextStyle(
                fontSize: _isUrdu ? 13.5 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 8),
            ...topList.map((pred) {
              final taxonomy = ClinicalTerminologyMapper.getTaxonomy(pred.conditionName);
              final scoreText = '${(pred.confidencePercentage).toStringAsFixed(1)}%';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${pred.rank}. ${taxonomy.benchmarkScientificName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF78350F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            scoreText,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      taxonomy.plainVernacularEn,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      taxonomy.regionalUrduContext,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF92400E),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              );
            }),
          ],
          if (onRetakePhoto != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetakePhoto,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(_isUrdu ? 'دوبارہ تصویر لیں' : 'Retake Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDifferentialAssessmentCard(BuildContext context) {
    final topList = skinAnalysis.topPredictions.isNotEmpty
        ? skinAnalysis.topPredictions.take(3).toList()
        : [
            SkinPrediction(
              conditionName: skinAnalysis.conditionName,
              rawScore: skinAnalysis.confidence,
              confidencePercentage: skinAnalysis.confidence * 100,
              confidenceScore: skinAnalysis.formattedConfidenceScore,
              riskLevel: skinAnalysis.effectiveRiskLevel,
              rank: 1,
            )
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  size: 18,
                  color: Color(0xFF6D28D9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isUrdu ? 'تفریقی جائزہ' : 'Differential Assessment',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B21B6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: const Text(
                  'Differential (22-44%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isUrdu
                ? 'پرائمری میچ اور تفریقی جائزہ (22% - 44%)'
                : 'Primary Match & Top-3 Differential Assessment (22% - 44%)',
            style: TextStyle(
              fontSize: _isUrdu ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isUrdu
                ? 'تشخیصی یقین 22% اور 44% کے درمیان ہے (${skinAnalysis.formattedConfidenceScore})۔ پرائمری میچ کے ساتھ ٹاپ 3 تفریقی امکانات:'
                : 'Confidence is between 22% and 44% (${skinAnalysis.formattedConfidenceScore}). Displaying primary match alongside Top-3 differential options:',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...topList.map((pred) {
            final taxonomy = ClinicalTerminologyMapper.getTaxonomy(pred.conditionName);
            final scoreText = '${(pred.confidencePercentage).toStringAsFixed(1)}%';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${pred.rank}. ${taxonomy.benchmarkScientificName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          scoreText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    taxonomy.plainVernacularEn,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    taxonomy.regionalUrduContext,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF581C87),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHighConfidenceLesionCard(BuildContext context) {
    final bool isUrgent = skinAnalysis.isHighRisk || skinAnalysis.isSeverePathology;
    final taxonomy = skinAnalysis.taxonomy;
    final primaryTitle =
        _isUrdu ? skinAnalysis.friendlyNameUr : skinAnalysis.friendlyNameEn;
    final urgencyText =
        _isUrdu ? skinAnalysis.urgencyTagUr : skinAnalysis.urgencyTagEn;
    final instruction =
        _isUrdu ? skinAnalysis.instructionUr : skinAnalysis.instructionEn;

    final Color borderColor =
        isUrgent ? const Color(0xFFEF5350) : const Color(0xFF80CBC4);
    final Color badgeBg =
        isUrgent ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1);
    final Color badgeBorder =
        isUrgent ? const Color(0xFFEF9A9A) : const Color(0xFF80CBC4);
    final Color badgeText =
        isUrgent ? const Color(0xFFC62828) : const Color(0xFF004D40);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (skinAnalysis.isSeverePathology) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.emergency_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isUrdu
                          ? 'فوری طبی انتباہ: فوراً مستند ماہر امراض جلد یا اسپتال سے رجوع کریں (OTC ادویات سختی سے منع ہیں)'
                          : 'Critical Medical Alert: Consult a Certified Dermatologist / Hospital Immediately',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUrgent
                      ? Icons.medical_services_outlined
                      : Icons.health_and_safety_outlined,
                  size: 18,
                  color: badgeText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isUrdu ? 'ابتدائی تشخیص' : 'Primary Diagnosis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUrgent
                        ? const Color(0xFFC62828)
                        : const Color(0xFF00796B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  urgencyText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: badgeText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            primaryTitle,
            style: TextStyle(
              fontSize: _isUrdu ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scientific: ${taxonomy.benchmarkScientificName}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vernacular: ${taxonomy.plainVernacularEn}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'اردو: ${taxonomy.regionalUrduContext}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF047857),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          if (instruction.isNotEmpty && !skinAnalysis.isSeverePathology) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFFFF5F5)
                    : const Color(0xFFF7FBFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isUrgent
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFE0F2F1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isUrgent
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: isUrgent
                        ? const Color(0xFFC62828)
                        : const Color(0xFF00796B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isUrgent
                            ? const Color(0xFF7F1D1D)
                            : const Color(0xFF134E4A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PreCaptureGuidanceCard extends StatefulWidget {
  final bool? isUrdu;
  final bool initialExpanded;

  const PreCaptureGuidanceCard({
    super.key,
    this.isUrdu,
    this.initialExpanded = true,
  });

  @override
  State<PreCaptureGuidanceCard> createState() => _PreCaptureGuidanceCardState();
}

class _PreCaptureGuidanceCardState extends State<PreCaptureGuidanceCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  bool get _isUrdu => widget.isUrdu ?? LocaleService.isUrdu;

  @override
  Widget build(BuildContext context) {
    final title = _isUrdu
        ? '📸 درست اسکین کا طریقہ'
        : '📸 How to get an accurate scan';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF00796B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF00796B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFA7F3D0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuidanceRow(
                    icon: Icons.filter_center_focus_rounded,
                    textEn:
                        'Focus directly on the affected skin spot (10–15 cm distance).',
                    textUr:
                        'متاثرہ جلد کے داغ پر 10 سے 15 سینٹی میٹر کے فاصلے سے فوکس کریں۔',
                  ),
                  const SizedBox(height: 8),
                  _buildGuidanceRow(
                    icon: Icons.wb_sunny_outlined,
                    textEn:
                        'Use bright, natural, or direct room light without shadows.',
                    textUr:
                        'بغیر سائے کے روشن اور براہ راست روشنی استعمال کریں۔',
                  ),
                  const SizedBox(height: 8),
                  _buildGuidanceRow(
                    icon: Icons.motion_photos_off_outlined,
                    textEn: 'Keep the camera still to avoid motion blur.',
                    textUr:
                        'دھندلا پن روکنے کے لیے کیمرے کو بالکل ساکت رکھیں۔',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidanceRow({
    required IconData icon,
    required String textEn,
    required String textUr,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00796B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isUrdu ? textUr : textEn,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF004D40),
            ),
          ),
        ),
      ],
    );
  }
}
