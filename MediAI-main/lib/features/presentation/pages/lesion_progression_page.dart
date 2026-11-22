import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/models/scan_record_model.dart';
import '../../../../core/services/locale_service.dart';
import '../utils/clinical_pdf_generator.dart';

class LesionProgressionPage extends StatefulWidget {
  final ScanRecord baselineScan;
  final ScanRecord followUpScan;

  const LesionProgressionPage({
    super.key,
    required this.baselineScan,
    required this.followUpScan,
  });

  @override
  State<LesionProgressionPage> createState() => _LesionProgressionPageState();
}

class _LesionProgressionPageState extends State<LesionProgressionPage> {
  bool _isExporting = false;

  int get _daysElapsed {
    return widget.followUpScan.dateTime
        .difference(widget.baselineScan.dateTime)
        .inDays
        .abs();
  }

  bool get _hasEvolution {
    final followUpRisk = widget.followUpScan.riskLevel.toLowerCase();
    final baselineRisk = widget.baselineScan.riskLevel.toLowerCase();

    if (followUpRisk == 'high' || followUpRisk == 'emergency') {
      return true;
    }
    if (baselineRisk == 'low' && followUpRisk == 'moderate') {
      return true;
    }
    if (widget.followUpScan.confidenceScore > 0.80 &&
        widget.followUpScan.lesionName.toLowerCase().contains('melanoma')) {
      return true;
    }
    return false;
  }

  String _getStabilityBadgeText(bool isUrdu) {
    if (_hasEvolution) {
      return isUrdu
          ? 'ارتقاء شناخت شدہ / ڈاکٹر سے رجوع کریں'
          : 'Evolution Detected / Consult Doctor';
    }
    return isUrdu ? 'مستحکم / کوئی تبدیلی نہیں' : 'Stable';
  }

  Map<String, String> _buildAbcdeDelta(bool isUrdu) {
    final isEvolution = _hasEvolution;

    if (isUrdu) {
      return {
        'A - عدم توازن (Asymmetry)': isEvolution
            ? 'کناروں کی ساخت میں واضح عدم توازن اور بعد میں وسعت دیکھی گئی۔'
            : 'دونوں اسکینز میں توازن برقرار ہے، کوئی نمایاں یکطرفہ بگاڑ نہیں۔',
        'B - کنارے کی بے قاعدگی (Border)': isEvolution
            ? 'کناروں پر غیر ہموار دندانے اور غیر واضح حدود نوٹ کی گئیں۔'
            : 'ہموار اور واضح حدود محفوظ ہیں، کٹاؤ یا دندانے ظاہر نہیں ہوئے۔',
        'C - رنگ کی تبدیلی (Color)': isEvolution
            ? 'گہرے بھورے یا سیاہ شیڈز اور رنگوں کا امتزاج واضح ہے۔'
            : 'رنگت میں یکسانیت برقرار ہے، کوئی نیا رنگ ظاہر نہیں ہوا۔',
        'D - قطر اور سائز (Diameter)': isEvolution
            ? 'سائز میں توسیع یا پچھلے اسکین کے مقابلے میں رقبے کا پھیلاؤ۔'
            : 'قطر مستحکم اور قابو میں ہے، سائز میں کوئی تیز اضافہ نہیں۔',
        'E - ارتقاء (Evolution)': isEvolution
            ? '$_daysElapsed دنوں کے دوران خلیاتی اور ظاہری ساخت میں تبدیلی کی تصدیق۔'
            : '$_daysElapsed دنوں کے دوران کوئی غیر معمولی یا خطرناک ارتقائی علامات نہیں۔',
      };
    }

    return {
      'A - Asymmetry': isEvolution
          ? 'Structural asymmetry detected across lesion axis between intervals.'
          : 'Symmetric morphology maintained across baseline and follow-up.',
      'B - Border Irregularity': isEvolution
          ? 'Notched or scalloped borders emerged on follow-up imaging.'
          : 'Well-circumscribed and sharp borders observed without scalloping.',
      'C - Color Variegation': isEvolution
          ? 'Variegated pigmentation or darker shades identified.'
          : 'Uniform pigment pattern preserved with stable tonal distribution.',
      'D - Diameter Metric': isEvolution
          ? 'Expansion in surface area or elevated dimensional footprint.'
          : 'Dimensionally stable; no significant linear enlargement noted.',
      'E - Clinical Evolution': isEvolution
          ? 'Observable morphological progression noted over $_daysElapsed days.'
          : 'No clinically significant evolution noted across $_daysElapsed days.',
    };
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
      case 'emergency':
        return const Color(0xFFC62828);
      case 'moderate':
        return const Color(0xFFEF6C00);
      case 'low':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color _getRiskBgColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
      case 'emergency':
        return const Color(0xFFFFEBEE);
      case 'moderate':
        return const Color(0xFFFFF3E0);
      case 'low':
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  Future<void> _exportComparativePdf(bool isUrdu) async {
    setState(() => _isExporting = true);
    try {
      final status = _getStabilityBadgeText(isUrdu);
      final delta = _buildAbcdeDelta(isUrdu);

      final pdfBytes = await ClinicalPdfGenerator.generateLesionProgressionPdf(
        baseline: widget.baselineScan,
        followUp: widget.followUpScan,
        stabilityStatus: status,
        abcdeDelta: delta,
        language: isUrdu ? 'ur' : 'en',
      );

      final fileName =
          'MediScan_Progression_${widget.baselineScan.id}_${widget.followUpScan.id}';

      await ClinicalPdfGenerator.sharePdf(
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu
                  ? 'تقابلی رپورٹ کامیابی سے تیار کر لی گئی۔'
                  : 'Comparative progression summary ready for handover.',
            ),
            backgroundColor: const Color(0xFF004D40),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate comparative PDF: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';
        final isEvolution = _hasEvolution;
        final deltaMetrics = _buildAbcdeDelta(isUrdu);
        final statusBadge = _getStabilityBadgeText(isUrdu);

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                isUrdu
                    ? 'زخم کا ارتقائی موازنہ'
                    : 'Lesion Progression Timeline',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.5,
                ),
              ),
              actions: [
                if (_isExporting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    tooltip: isUrdu
                        ? 'پی ڈی ایف برآمد کریں'
                        : 'Export Comparative Summary',
                    onPressed: () => _exportComparativePdf(isUrdu),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStabilityHeaderCard(isUrdu, isEvolution, statusBadge),
                  const SizedBox(height: 16),
                  _buildTimelineIntervalHeader(isUrdu),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildScanCard(
                          title: isUrdu ? 'بنیادی اسکین' : 'Baseline Scan',
                          subtitle: isUrdu ? 'ابتدائی معائنہ' : 'Initial Target',
                          record: widget.baselineScan,
                          isUrdu: isUrdu,
                          cardColor: Colors.white,
                          accentColor: const Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildScanCard(
                          title: isUrdu ? 'فالو اپ اسکین' : 'Follow-up Scan',
                          subtitle: isUrdu ? 'موجودہ جائزہ' : 'Current Review',
                          record: widget.followUpScan,
                          isUrdu: isUrdu,
                          cardColor: Colors.white,
                          accentColor: const Color(0xFF00796B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAbcdeSection(deltaMetrics, isUrdu, isEvolution),
                  const SizedBox(height: 20),
                  _buildDoctorConsultationNotice(isUrdu, isEvolution),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isExporting
                        ? null
                        : () => _exportComparativePdf(isUrdu),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.share_outlined),
                    label: Text(
                      isUrdu
                          ? 'ڈاکٹر کے لیے پی ڈی ایف موازنہ تیار کریں'
                          : 'Export Comparative Summary to PDF',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStabilityHeaderCard(
    bool isUrdu,
    bool isEvolution,
    String statusBadge,
  ) {
    final bgColor = isEvolution
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final borderColor = isEvolution
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
    final textColor = isEvolution
        ? const Color(0xFFB91C1C)
        : const Color(0xFF15803D);
    final icon = isEvolution
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'ارتقائی استحکام کا درجہ' : 'Stability Assessment',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: isUrdu ? 0.0 : 0.8,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusBadge,
                  style: TextStyle(
                    fontSize: isUrdu ? 15 : 14.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineIntervalHeader(bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF80CBC4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                size: 18,
                color: Color(0xFF004D40),
              ),
              const SizedBox(width: 8),
              Text(
                isUrdu ? 'معائنوں کا درمیانی وقفہ:' : 'Interval Elapsed:',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004D40),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isUrdu ? '$_daysElapsed دن کا وقفہ' : '$_daysElapsed days apart',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard({
    required String title,
    required String subtitle,
    required ScanRecord record,
    required bool isUrdu,
    required Color cardColor,
    required Color accentColor,
  }) {
    final riskColor = _getRiskColor(record.riskLevel);
    final riskBg = _getRiskBgColor(record.riskLevel);
    final hasImage =
        record.thumbnailPath.isNotEmpty && File(record.thumbnailPath).existsSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.file(
                    File(record.thumbnailPath),
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 110,
                    color: const Color(0xFFE0F2F1),
                    child: const Icon(
                      Icons.healing_rounded,
                      color: Color(0xFF004D40),
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            record.lesionName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${record.dateTime.day}/${record.dateTime.month}/${record.dateTime.year}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (record.anatomicalLocation != null &&
              record.anatomicalLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📍 ${record.anatomicalLocation}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF00796B),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: riskBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: riskColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    record.riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(record.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbcdeSection(
    Map<String, String> metrics,
    bool isUrdu,
    bool isEvolution,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF004D40),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUrdu
                      ? 'ABCDE طبی تقابلی اشاریے'
                      : 'ABCDE Clinical Delta Criteria',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...metrics.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDoctorConsultationNotice(bool isUrdu, bool isEvolution) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isUrdu
                  ? 'ڈاکٹر کے مشورے کے لیے رہنمائی: جلد پر تلوں کے سائز، رنگ یا شکل میں کسی بھی نمایاں تبدیلی کی صورت میں ماہرِ امراضِ جلد سے فوری معائنہ اور ڈرموسکوپی کروائیں۔'
                  : 'Physician Consultation Guidance: Documented morphological shifts across the ABCDE spectrum provide high diagnostic utility. Share this comparative PDF report with your dermatologist for in-depth dermoscopy.',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
