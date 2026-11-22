import 'package:flutter/material.dart';

import '../../../../core/models/clinic_recommendation_model.dart';

class EmergencyRedFlagBanner extends StatefulWidget {
  final bool isUrdu;
  final VoidCallback? onFindTertiaryHospital;
  final List<ClinicRecommendation> clinics;
  final bool isSystemicDistress;
  final String? systemicDistressTitle;
  final String? systemicDistressRationale;
  final List<String> vitalTriggers;

  const EmergencyRedFlagBanner({
    super.key,
    required this.isUrdu,
    this.onFindTertiaryHospital,
    this.clinics = const [],
    this.isSystemicDistress = false,
    this.systemicDistressTitle,
    this.systemicDistressRationale,
    this.vitalTriggers = const [],
  });

  static bool isHighRiskSeverity({
    required String riskLevel,
    required String conditionName,
    bool isHighRisk = false,
    double confidence = 0.0,
  }) {
    final normalizedRisk = riskLevel.trim().toLowerCase();
    final normalizedCondition = conditionName.trim().toLowerCase();

    if (normalizedRisk == 'high' || normalizedRisk == 'emergency') {
      return true;
    }
    if (isHighRisk) {
      return true;
    }
    if (normalizedCondition.contains('melanoma') ||
        normalizedCondition.contains('squamous cell') ||
        normalizedCondition.contains('basal cell carcinoma') ||
        normalizedCondition.contains('carcinoma')) {
      return confidence > 0.40;
    }
    return false;
  }

  @override
  State<EmergencyRedFlagBanner> createState() => _EmergencyRedFlagBannerState();
}

class _EmergencyRedFlagBannerState extends State<EmergencyRedFlagBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  bool _isClinicsExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;
    final tertiaryClinics = widget.clinics.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF500714), Color(0xFF780A20), Color(0xFF900C27)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF5252), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF900C27).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFCDD2),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFFEB3B),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isSystemicDistress
                            ? (isUrdu
                                ? 'فوری ہسپتال ریفرل: جسمانی نظام میں پیچیدگی کا خطرہ'
                                : 'Urgent Referral: Possible Systemic Distress')
                            : (isUrdu
                                ? 'فوری طبی معائنے کی ضرورت ہے'
                                : 'Urgent Medical Attention Required'),
                        style: TextStyle(
                          fontSize: isUrdu ? 16.5 : 15.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: isUrdu ? 0.0 : 0.3,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isSystemicDistress
                      ? (widget.systemicDistressRationale ??
                          (isUrdu
                              ? 'جلدی زخم کے ساتھ بائیو سینسر وائٹلز میں غیر معمولی تبدیلیاں دیکھی گئی ہیں۔ فوری طور پر ہسپتال سے رجوع کریں۔'
                              : 'Acute vital anomalies co-occur with dermatological presentation. Immediate physician referral required.'))
                      : (isUrdu
                          ? 'اس زخم میں ایسی علامات ہیں جن کے لیے فوری طور پر ماہر امراضِ جلد سے معائنہ یا بایوپسی ضروری ہے۔'
                          : 'This lesion exhibits characteristics that warrant in-person dermatological evaluation or biopsy. Do not delay consultation.'),
                  style: TextStyle(
                    fontSize: isUrdu ? 13 : 12.5,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.vitalTriggers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF8A80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu
                              ? '⚠️ غیر معمولی وائٹلز (طبی سینسرز):'
                              : '⚠️ Hemodynamic Baseline Anomalies:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFEB3B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...widget.vitalTriggers.map(
                          (trigger) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '• $trigger',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF780A20),
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isClinicsExpanded = !_isClinicsExpanded;
                    });
                    widget.onFindTertiaryHospital?.call();
                  },
                  icon: const Icon(
                    Icons.local_hospital_rounded,
                    color: Color(0xFF900C27),
                    size: 20,
                  ),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isUrdu
                              ? 'قریبی بڑا ہسپتال تلاش کریں'
                              : 'Find Nearest Tertiary Hospital',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF780A20),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isClinicsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF780A20),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isClinicsExpanded && tertiaryClinics.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu
                        ? 'قریبی تسلیم شدہ ٹرشری اور ڈرمیٹولوجی سینٹرز:'
                        : 'Nearest Accredited Tertiary & Dermatology Facilities:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade200,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tertiaryClinics.map(
                    (clinic) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.emergency_rounded,
                              color: Color(0xFF900C27),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clinic.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  clinic.address,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (clinic.distanceKm != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${clinic.distanceKm!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
