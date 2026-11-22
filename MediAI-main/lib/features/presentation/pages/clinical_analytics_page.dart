import 'package:flutter/material.dart';

import '../../../../core/models/patient_profile_model.dart';
import '../../../../core/models/scan_record_model.dart';
import '../../../../core/repositories/scan_repository.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/patient_profile_service.dart';

class ClinicalAnalyticsPage extends StatefulWidget {
  const ClinicalAnalyticsPage({super.key});

  @override
  State<ClinicalAnalyticsPage> createState() => _ClinicalAnalyticsPageState();
}

class _ClinicalAnalyticsPageState extends State<ClinicalAnalyticsPage> {
  List<ScanRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _records = ScanRepository.instance.scansNotifier.value;
    _isLoading = _records.isEmpty;
    ScanRepository.instance.scansNotifier.addListener(_onScansNotifierChanged);
    _loadData();
  }

  @override
  void dispose() {
    ScanRepository.instance.scansNotifier.removeListener(_onScansNotifierChanged);
    super.dispose();
  }

  void _onScansNotifierChanged() {
    if (mounted) {
      setState(() {
        _records = ScanRepository.instance.scansNotifier.value;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    final scans = await ScanRepository.instance.getAllScans();
    if (mounted) {
      setState(() {
        _records = scans;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';

        final totalScans = _records.length;
        final lowCount = _records
            .where((r) => r.riskLevel.toLowerCase() == 'low')
            .length;
        final modCount = _records
            .where((r) => r.riskLevel.toLowerCase() == 'moderate')
            .length;
        final highCount = _records
            .where((r) => r.riskLevel.toLowerCase() == 'high')
            .length;

        final lowPct = totalScans > 0 ? (lowCount / totalScans) : 0.0;
        final modPct = totalScans > 0 ? (modCount / totalScans) : 0.0;
        final highPct = totalScans > 0 ? (highCount / totalScans) : 0.0;

        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final recentHighRiskCount = _records
            .where(
              (r) =>
                  r.dateTime.isAfter(thirtyDaysAgo) &&
                  r.riskLevel.toLowerCase() == 'high',
            )
            .length;

        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F9FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.insights_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isUrdu ? 'طبی تجزیات' : 'Clinical Analytics',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: isUrdu ? 'تازہ کریں' : 'Refresh Analytics',
                  onPressed: _loadData,
                ),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00796B)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF00796B),
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ValueListenableBuilder<PatientProfile>(
                            valueListenable:
                                PatientProfileService.currentProfile,
                            builder: (context, profile, _) {
                                    final rawName = profile.name;
                                    final displayName = isUrdu &&
                                            (rawName == 'Clinical Patient' ||
                                                rawName.isEmpty)
                                        ? 'طبی مریض'
                                        : (rawName.isEmpty ? 'Clinical Patient' : rawName);
                                    final rawCity = profile.city;
                                    final displayCity = isUrdu && rawCity == 'Faisalabad'
                                        ? 'فیصل آباد'
                                        : rawCity;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE0E0E0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Color(0xFF004D40),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  displayName,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF004D40),
                                                  ),
                                                ),
                                                Text(
                                                  '${isUrdu ? "عمر" : "Age"}: ${profile.age} • ${profile.fitzpatrickType}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2F1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 12,
                                                  color: Color(0xFF004D40),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  displayCity,
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF004D40),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        title: isUrdu ? 'کل اسکینز' : 'Total Scans',
                                        value: '$totalScans',
                                        icon: Icons.biotech_rounded,
                                        accentColor: const Color(0xFF00796B),
                                        bgColor: const Color(0xFFE0F2F1),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMetricTile(
                                        title: isUrdu ? 'زیادہ خطرہ' : 'High Risk',
                                        value: '$highCount',
                                        icon: Icons.warning_amber_rounded,
                                        accentColor: const Color(0xFFC62828),
                                        bgColor: const Color(0xFFFFEBEE),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        title: isUrdu
                                            ? 'بے ضرر (کم)'
                                            : 'Benign (Low)',
                                        value: '$lowCount',
                                        icon: Icons.verified_user_outlined,
                                        accentColor: const Color(0xFF2E7D32),
                                        bgColor: const Color(0xFFE8F5E9),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMetricTile(
                                        title: isUrdu
                                            ? 'متوسط الرٹ'
                                            : 'Moderate Alert',
                                        value: '$modCount',
                                        icon: Icons.sync_problem_rounded,
                                        accentColor: const Color(0xFFEF6C00),
                                        bgColor: const Color(0xFFFFF3E0),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.pie_chart_outline_rounded,
                                              color: Color(0xFF00796B),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isUrdu
                                                  ? 'خطرے کی شرح اور تقسیم'
                                                  : 'Risk Profile Distribution',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF004D40),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isUrdu
                                              ? 'تمام محفوظ شدہ جلدی معائنوں کی تفصیلی شرح'
                                              : 'Proportional breakdown across all locally recorded dermatological assessments.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        if (totalScans == 0)
                                          Container(
                                            height: 16,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                isUrdu
                                                    ? 'گراف کے لیے کوئی ریکارڈ موجود نہیں ہے'
                                                    : 'No records to graph',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: SizedBox(
                                              height: 18,
                                              child: Row(
                                                children: [
                                                  if (lowPct > 0)
                                                    Flexible(
                                                      flex: (lowPct * 100)
                                                          .toInt()
                                                          .clamp(1, 100),
                                                      child: Container(
                                                        color: const Color(
                                                          0xFF2E7D32,
                                                        ),
                                                      ),
                                                    ),
                                                  if (modPct > 0)
                                                    Flexible(
                                                      flex: (modPct * 100)
                                                          .toInt()
                                                          .clamp(1, 100),
                                                      child: Container(
                                                        color: const Color(
                                                          0xFFEF6C00,
                                                        ),
                                                      ),
                                                    ),
                                                  if (highPct > 0)
                                                    Flexible(
                                                      flex: (highPct * 100)
                                                          .toInt()
                                                          .clamp(1, 100),
                                                      child: Container(
                                                        color: const Color(
                                                          0xFFC62828,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 16),
                                        _buildRiskLegendRow(
                                          isUrdu
                                              ? 'بے ضرر / کم خطرہ'
                                              : 'Benign / Low Risk',
                                          '${(lowPct * 100).toStringAsFixed(1)}%',
                                          '$lowCount ${isUrdu ? "اسکینز" : "scans"}',
                                          const Color(0xFF2E7D32),
                                        ),
                                        const Divider(height: 12),
                                        _buildRiskLegendRow(
                                          isUrdu
                                              ? 'طبی معائنے کی ضرورت (متوسط)'
                                              : 'Needs Clinical Attention (Moderate)',
                                          '${(modPct * 100).toStringAsFixed(1)}%',
                                          '$modCount ${isUrdu ? "اسکینز" : "scans"}',
                                          const Color(0xFFEF6C00),
                                        ),
                                        const Divider(height: 12),
                                        _buildRiskLegendRow(
                                          isUrdu
                                              ? 'زیادہ خطرہ (فوری توجہ درکار)'
                                              : 'High Risk (Suspected Malignancy)',
                                          '${(highPct * 100).toStringAsFixed(1)}%',
                                          '$highCount ${isUrdu ? "اسکینز" : "scans"}',
                                          const Color(0xFFC62828),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.timeline_rounded,
                                              color: Color(0xFF00796B),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isUrdu
                                                  ? 'نشانات کا 30 روزہ ریکارڈ'
                                                  : 'Lesion Stability Tracker (30 Days)',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF004D40),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: recentHighRiskCount == 0
                                                ? const Color(0xFFE8F5E9)
                                                : const Color(0xFFFFEBEE),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: recentHighRiskCount == 0
                                                  ? const Color(0xFFA5D6A7)
                                                  : const Color(0xFFEF9A9A),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                recentHighRiskCount == 0
                                                    ? Icons.verified_rounded
                                                    : Icons
                                                        .notification_important_rounded,
                                                color: recentHighRiskCount == 0
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFC62828),
                                                size: 28,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      recentHighRiskCount == 0
                                                          ? (isUrdu
                                                              ? 'مستحکم اور معمول کے مطابق نشانات'
                                                              : 'Stable Lesion Trajectory')
                                                          : (isUrdu
                                                              ? 'اہم انتباہ: فوری معائنہ تجویز کیا گیا ہے'
                                                              : '$recentHighRiskCount High-Risk Event(s) Detected'),
                                                      style: TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.bold,
                                                        color:
                                                            recentHighRiskCount == 0
                                                            ? const Color(0xFF1B5E20)
                                                            : const Color(0xFFB71C1C),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      recentHighRiskCount == 0
                                                          ? (isUrdu
                                                              ? 'گزشتہ 30 دنوں میں کوئی خطرناک تبدیلیاں نوٹ نہیں ہوئیں۔'
                                                              : 'No high-risk progression or acute transformation detected in the past 30 days.')
                                                          : (isUrdu
                                                              ? 'حالیہ اسکینز میں اہم علامات پائی گئیں۔ مستند معالج سے رجوع میں تاخیر نہ کریں۔'
                                                              : 'Recent high-risk signals captured. Do not delay professional consultation.'),
                                                      style: const TextStyle(
                                                        fontSize: 11.5,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE0F2F1),
                                          Color(0xFFF7F9FA),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.medical_services_outlined,
                                              color: Color(0xFF004D40),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isUrdu
                                                  ? 'جلدی صحت کے لیے مفید مشورے'
                                                  : 'Dermatological Best Practices',
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF004D40),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildBullet(
                                          isUrdu
                                              ? 'نئے یا تیزی سے بدلتے ہوئے تل اور نشانات کے لیے ماہانہ خود معائنہ کریں۔'
                                              : 'Conduct monthly visual full-body checks for new or rapidly changing spots.',
                                        ),
                                        _buildBullet(
                                          isUrdu
                                              ? 'مستقل قدرتی یا نیوٹرل روشنی میں 2 سے 3 سینٹی میٹر کی میکرو دوری سے تصویر لیں۔'
                                              : 'Photograph lesions from a constant 2–3 cm macro distance in consistent neutral lighting.',
                                        ),
                                        _buildBullet(
                                          isUrdu
                                              ? 'مستند ڈرمیٹالوجسٹ سے سالانہ جامع معائنہ لازماً کروائیں۔'
                                              : 'Schedule comprehensive annual in-person skin examinations with a certified dermatologist.',
                                        ),
                                        _buildBullet(
                                          isUrdu
                                              ? 'اگر کسی تل سے خون بہے، مسلسل خارش ہو یا غیر متناسب بڑھے تو فوری معالج سے رجوع کریں۔'
                                              : 'If any spot bleeds, itches persistently, or exhibits asymmetrical growth, seek clinical evaluation immediately.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLegendRow(
    String label,
    String percentage,
    String count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF004D40),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
