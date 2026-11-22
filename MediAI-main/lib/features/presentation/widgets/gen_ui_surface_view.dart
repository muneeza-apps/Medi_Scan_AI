import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/models/clinic_recommendation_model.dart';
import '../../../../core/services/clinic_locator_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/patient_profile_service.dart';
import '../../domain/domain.dart';
import '../pages/nearby_clinics_page.dart';
import '../utils/clinical_pdf_generator.dart';
import 'emergency_red_flag_banner.dart';

class GenUiSurfaceView extends StatefulWidget {
  final TriageSummaryEntity summary;
  final String initialLanguage;
  final ValueChanged<String>? onLanguageChanged;
  final File? imageFile;

  const GenUiSurfaceView({
    super.key,
    required this.summary,
    this.initialLanguage = 'en',
    this.onLanguageChanged,
    this.imageFile,
  });

  @override
  State<GenUiSurfaceView> createState() => _GenUiSurfaceViewState();
}

class _GenUiSurfaceViewState extends State<GenUiSurfaceView> {
  late final SurfaceController _surfaceController;
  late final SurfaceContext _surfaceContext;
  static const String _surfaceId = 'skin_triage_surface';

  late String _language;
  bool _isGeneratingPdf = false;
  String? _pdfActionLoadingMessage;
  String? _detectedCity;
  Position? _currentPosition;
  List<ClinicRecommendation>? _nearbyClinics;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _surfaceController = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );
    _surfaceContext = _surfaceController.contextFor(_surfaceId);
    _resolveLocationAndClinics();
  }

  Future<void> _resolveLocationAndClinics() async {
    try {
      final pos = await LocationService.instance.getCurrentCoordinates();
      String area = PatientProfileService.profile.city;
      List<ClinicRecommendation> clinics = [];
      if (pos != null) {
        final resolved = await LocationService.instance.resolveDistrictOrTown(
          pos.latitude,
          pos.longitude,
        );
        if (resolved.isNotEmpty) {
          area = resolved;
        }
        clinics = await ClinicLocatorService.getNearbyClinics(
          pos.latitude,
          pos.longitude,
        );
      } else {
        clinics = ClinicLocatorService.getOfflineCachedClinics(31.4239, 73.0845);
      }
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _detectedCity = area;
          _nearbyClinics = clinics.isNotEmpty ? clinics : widget.summary.recommendedClinics;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearbyClinics = ClinicLocatorService.getOfflineCachedClinics(31.4239, 73.0845);
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant GenUiSurfaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLanguage != oldWidget.initialLanguage) {
      _language = widget.initialLanguage;
    }
  }

  @override
  void dispose() {
    _surfaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final riskLevel = summary.riskLevel.toLowerCase();
    final isUrdu = _language == 'ur';

    final (
      Color primaryColor,
      Color bgColor,
      Color borderColor,
      IconData icon,
    ) = switch (riskLevel) {
      'emergency' => (
        Colors.red.shade900,
        Colors.red.shade50,
        Colors.red.shade400,
        Icons.emergency_rounded,
      ),
      'high' => (
        Colors.deepOrange.shade900,
        Colors.deepOrange.shade50,
        Colors.deepOrange.shade300,
        Icons.warning_amber_rounded,
      ),
      'moderate' => (
        Colors.amber.shade900,
        Colors.amber.shade50,
        Colors.amber.shade300,
        Icons.health_and_safety_outlined,
      ),
      _ => (
        const Color(0xFF004D40),
        const Color(0xFFE0F2F1),
        const Color(0xFF80CBC4),
        Icons.verified_rounded,
      ),
    };

    final payload = summary.a2uiPayload;
    final bool isSystemicDistress =
        payload?['isSystemicDistressFlagged'] as bool? ?? false;
    final List<String> vitalTriggers =
        (payload?['vitalTriggers'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    final isHighRiskOutcome = EmergencyRedFlagBanner.isHighRiskSeverity(
      riskLevel: summary.riskLevel,
      conditionName: summary.skinAnalysis.conditionName,
      isHighRisk: summary.skinAnalysis.isHighRisk,
      confidence: summary.skinAnalysis.confidence,
    );

    final bool shouldShowBanner = isHighRiskOutcome || isSystemicDistress;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shouldShowBanner)
            EmergencyRedFlagBanner(
              isUrdu: isUrdu,
              clinics: _nearbyClinics ?? widget.summary.recommendedClinics,
              isSystemicDistress: isSystemicDistress,
              vitalTriggers: vitalTriggers,
              onFindTertiaryHospital: () {
                final detectedArea =
                    _detectedCity ?? PatientProfileService.profile.city;
                final allClinics =
                    _nearbyClinics ?? widget.summary.recommendedClinics;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NearbyClinicsPage(
                      cityName: detectedArea,
                      clinics: allClinics,
                      position: _currentPosition,
                    ),
                  ),
                );
              },
            ),
          _buildRiskLevelCard(primaryColor, bgColor, borderColor, icon, isUrdu),
          const SizedBox(height: 12),
          _buildClinicalObservationsCard(isUrdu),
          const SizedBox(height: 12),
          _buildRecommendedClinicsSection(isUrdu),
          const SizedBox(height: 12),
          _buildRedFlagsCard(isUrdu),
          const SizedBox(height: 12),
          _buildActionsCard(isUrdu),
          const SizedBox(height: 16),
          _buildExportAndShareActions(isUrdu),
          const SizedBox(height: 14),
          Surface(
            surfaceContext: _surfaceContext,
            defaultBuilder: (context) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelCard(
    Color primaryColor,
    Color bgColor,
    Color borderColor,
    IconData icon,
    bool isUrdu,
  ) {
    final summary = widget.summary;
    final laymanTerm = ClinicalTerminologyMapper.mapToLayman(
      summary.skinAnalysis.conditionName,
    );

    final title = isUrdu
        ? (summary.laymanTitleUr.isNotEmpty
              ? summary.laymanTitleUr
              : laymanTerm.urdu)
        : (summary.laymanTitleEn.isNotEmpty
              ? summary.laymanTitleEn
              : laymanTerm.english);

    final riskBadgeText = switch (summary.riskLevel.toLowerCase()) {
      'emergency' => isUrdu ? 'فوری ایمرجنسی' : 'EMERGENCY',
      'high' => isUrdu ? 'اعلیٰ خطرہ' : 'HIGH RISK',
      'moderate' => isUrdu ? 'درمیانہ خطرہ' : 'MODERATE RISK',
      _ => isUrdu ? 'کم خطرہ / بے ضرر' : 'LOW RISK',
    };

    final headerText = isUrdu
        ? 'مریض کے لیے آسان فہم تشخیص'
        : 'PATIENT-FRIENDLY EVALUATION';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerText,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: isUrdu ? 0.0 : 1.1,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isUrdu ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        height: 1.25,
                      ),
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    if (!isUrdu) ...[
                      Text(
                        'Scientific: ${summary.skinAnalysis.conditionName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  riskBadgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isUrdu) ...[
            Row(
              children: [
                Text(
                  'رپورٹ ٹریکنگ نمبر: ',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '#${summary.id}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Report Tracking ID: #${summary.id}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicalObservationsCard(bool isUrdu) {
    final laymanTerm = ClinicalTerminologyMapper.mapToLayman(
      widget.summary.skinAnalysis.conditionName,
    );

    final synthesis = isUrdu
        ? (widget.summary.diagnosticSynthesisUr.isNotEmpty
              ? widget.summary.diagnosticSynthesisUr
              : (laymanTerm.patientNoteUr ??
                    'جلد کے معائنے میں معمول کے خلیات کا مشاہدہ کیا گیا ہے۔'))
        : (widget.summary.diagnosticSynthesisEn.isNotEmpty
              ? widget.summary.diagnosticSynthesisEn
              : widget.summary.diagnosticSynthesis);

    final cardTitle = isUrdu
        ? 'آسان فہم طبی تشریح اور اہم نکات'
        : 'Plain-Language Explanation & Observations';

    final obsTitle = isUrdu
        ? 'کلینیکل مشاہدات اور نشانیاں:'
        : 'Clinical Observations:';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.biotech_rounded,
                    color: Color(0xFF00796B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cardTitle,
                    style: TextStyle(
                      fontSize: isUrdu ? 14 : 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Text(
              synthesis,
              style: TextStyle(
                fontSize: isUrdu ? 13 : 12.5,
                height: isUrdu ? 1.6 : 1.5,
                color: Colors.grey.shade900,
              ),
              softWrap: true,
            ),
            if (isUrdu) ...[
              if (widget.summary.clinicalObservationsUr.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  obsTitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                ...widget.summary.clinicalObservationsUr.map(
                  (obs) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Color(0xFF00796B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildUrduObservationRow(obs),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else ...[
              if (widget.summary.clinicalObservations.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  obsTitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                ...widget.summary.clinicalObservations.map(
                  (obs) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Color(0xFF00796B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            obs,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrduObservationRow(String rawObs) {
    if (rawObs.startsWith('Primary Condition:')) {
      final val = rawObs.replaceFirst('Primary Condition:', '').trim();
      return Row(
        children: [
          const Text('بنیادی کیفیت: ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                val,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }
    if (rawObs.startsWith('Malignancy Assessment:')) {
      final val = rawObs.replaceFirst('Malignancy Assessment:', '').trim();
      final isHigh =
          val.toLowerCase().contains('elevated') ||
          val.toLowerCase().contains('high');
      return Text(
        isHigh
            ? 'خطرے کا تخمینہ: فوری توجہ طلب جلدی تبدیلی'
            : 'خطرے کا تخمینہ: بے ضرر خلیاتی ساخت',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHigh ? FontWeight.bold : FontWeight.normal,
          color: isHigh ? Colors.red.shade800 : Colors.grey.shade800,
        ),
        softWrap: true,
      );
    }
    if (rawObs.startsWith('Dermatological Status:')) {
      return const Text(
        'جلد کی حالت: بالکل صاف اور ہموار سطح',
        style: TextStyle(fontSize: 12),
        softWrap: true,
      );
    }
    if (rawObs.startsWith('Cutaneous Morphology:')) {
      return const Text(
        'جلد کی ظاہری ساخت: کوئی غیر معمولی داغ یا خامی نہیں',
        style: TextStyle(fontSize: 12),
        softWrap: true,
      );
    }

    return Text(
      rawObs,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
      softWrap: true,
    );
  }

  Widget _buildRecommendedClinicsSection(bool isUrdu) {
    final detectedArea = _detectedCity ?? PatientProfileService.profile.city;
    final allClinics = _nearbyClinics ?? widget.summary.recommendedClinics;

    final previewClinics = allClinics.take(3).toList();
    if (previewClinics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Color(0xFF00796B),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUrdu
                        ? 'قریبی طبی مراکز'
                        : 'Nearby Healthcare Facilities',
                    style: TextStyle(
                      fontSize: isUrdu ? 14.5 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                  Text(
                    isUrdu
                        ? '$detectedArea کے قریبی طبی مراکز'
                        : 'Healthcare Centers Near $detectedArea',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...previewClinics.map((clinic) => _buildClinicCard(clinic, isUrdu)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF004D40),
              side: const BorderSide(color: Color(0xFF00796B), width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NearbyClinicsPage(
                    cityName: detectedArea,
                    clinics: allClinics,
                    position: _currentPosition,
                  ),
                ),
              );
            },
            child: Text(
              isUrdu
                  ? 'تمام قریبی کلینکس دیکھیں'
                  : 'View All Clinics Nearby (${allClinics.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicCard(ClinicRecommendation clinic, bool isUrdu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade100, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clinic.specialty,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF80CBC4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        clinic.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    clinic.address,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (clinic.distanceKm != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 12,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrdu
                          ? '${clinic.distanceKm!.toStringAsFixed(1)} کلومیٹر دور'
                          : '${clinic.distanceKm!.toStringAsFixed(1)} km away',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D40).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isUrdu ? 'ماہر امراضِ جلد' : 'Dermatology',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ),
                const Spacer(),
                if (clinic.contactNumber.trim().isNotEmpty) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF004D40),
                      side: const BorderSide(color: Color(0xFF00796B)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 14),
                    label: Text(
                      isUrdu ? 'کال کریں' : 'Call',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        ClinicLocatorService.launchDialer(clinic.contactNumber),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.directions_outlined, size: 14),
                  label: Text(
                    isUrdu ? 'راستہ دیکھیں' : 'Get Directions',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => ClinicLocatorService.launchDirections(
                    latitude: clinic.latitude,
                    longitude: clinic.longitude,
                    clinicName: clinic.name,
                    mapsUrl: clinic.mapsUrl,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedFlagsCard(bool isUrdu) {
    final hasEnglishFdaWarnings =
        widget.summary.openFdaWarnings != null &&
        widget.summary.openFdaWarnings!.trim().isNotEmpty;
    final hasUrduFdaWarnings =
        widget.summary.openFdaWarningsUr != null &&
        widget.summary.openFdaWarningsUr!.trim().isNotEmpty;
    final hasFdaWarnings = isUrdu
        ? (hasUrduFdaWarnings || hasEnglishFdaWarnings)
        : (hasEnglishFdaWarnings || hasUrduFdaWarnings);

    final isMelanoma = widget.summary.skinAnalysis.conditionName
        .toLowerCase()
        .contains('melanoma');

    if (!hasFdaWarnings &&
        !isMelanoma &&
        !widget.summary.skinAnalysis.isHighRisk) {
      return const SizedBox.shrink();
    }

    final cardTitle = isUrdu
        ? 'اہم طبی انتباہ اور حفاظتی تدابیر'
        : 'Clinical Red Flags & Safety Alerts';
    final badgeText = isUrdu ? 'حفاظتی انتباہ' : 'SAFETY';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFE65100),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cardTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                  softWrap: true,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isMelanoma) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: Color(0xFFE65100),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: isUrdu
                      ? const Text(
                          'خطرناک جلدی تل (میلانوما) کے امکان کے پیش نظر جلد از جلد ماہر امراض جلد سے بائیوپسی ٹیسٹ کروائیں۔ بغیر تصدیق کے خود سے کوئی مرہم نہ لگائیں۔',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBF360C),
                          ),
                          softWrap: true,
                        )
                      : const Text(
                          'High probability of cutaneous melanoma requires expedited excisional biopsy. Do not treat topically.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBF360C),
                          ),
                          softWrap: true,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (hasFdaWarnings) ...[
            if (isUrdu) ...[
              const Text(
                'ادویاتی حفاظتی انتباہ و احتیاط:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBF360C),
                ),
              ),
              const SizedBox(height: 4),
              if (hasUrduFdaWarnings)
                Text(
                  widget.summary.openFdaWarningsUr!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.brown.shade900,
                  ),
                  softWrap: true,
                )
              else if (hasEnglishFdaWarnings)
                Text(
                  widget.summary.openFdaWarningsUr ?? 'ادویات کے متعلق مستند فارماسسٹ یا معالج سے مشورہ کریں۔',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.brown.shade900,
                  ),
                  softWrap: true,
                ),
            ] else ...[
              const Text(
                'Pharmacotherapy Safety Warning (FDA):',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBF360C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasEnglishFdaWarnings
                    ? widget.summary.openFdaWarnings!
                    : widget.summary.openFdaWarningsUr!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Colors.brown.shade900,
                ),
                softWrap: true,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool isUrdu) {
    final recs = isUrdu
        ? (widget.summary.protocolRecommendationsUr.isNotEmpty
              ? widget.summary.protocolRecommendationsUr
              : const [
                  '1. جلد کے معائنے کے لیے ماہر امراض جلد سے وقت لیں۔',
                  '2. دھوپ سے بچاؤ کے لیے سن بلاک کا باقاعدہ استعمال کریں۔',
                  '3. تل کے پھیلاؤ، خارش یا رنگ میں تبدیلی پر نظر رکھیں۔',
                ])
        : (widget.summary.protocolRecommendationsEn.isNotEmpty
              ? widget.summary.protocolRecommendationsEn
              : widget.summary.protocolRecommendations);

    final cardTitle = isUrdu
        ? 'تجویز کردہ طبی اقدامات اور ہدایات'
        : 'Recommended Actions & Next Steps';

    final subtitleText = isUrdu
        ? '${recs.length} ضروری طبی اقدامات'
        : '${recs.length} recommended action items';

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.teal.shade50.withValues(alpha: 0.5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00796B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.playlist_add_check_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          cardTitle,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
          ),
          softWrap: true,
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: recs
            .map(
              (rec) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.lightGreen.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isUrdu
                          ? Icons.arrow_circle_left
                          : Icons.arrow_circle_right,
                      color: const Color(0xFF2E7D32),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: isUrdu ? 12.5 : 12,
                          fontWeight: FontWeight.w500,
                          height: isUrdu ? 1.45 : 1.35,
                          color: const Color(0xFF1B5E20),
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _handleSavePdf() async {
    if (_isGeneratingPdf) return;
    setState(() {
      _isGeneratingPdf = true;
      _pdfActionLoadingMessage = _language == 'ur'
          ? 'پی ڈی ایف رپورٹ محفوظ کی جا رہی ہے...'
          : 'Saving Clinical PDF Report...';
    });

    try {
      final file =
          widget.imageFile ??
          (widget.summary.skinAnalysis.imagePath.isNotEmpty
              ? File(widget.summary.skinAnalysis.imagePath)
              : null);

      final pdfBytes = await ClinicalPdfGenerator.generateReportPdf(
        summary: widget.summary,
        imageFile: file,
        language: _language,
      );

      final caseRef = widget.summary.id.isNotEmpty
          ? 'MediScan_Report_${widget.summary.id.substring(0, math.min(6, widget.summary.id.length))}'
          : 'MediScan_Clinical_Report';

      final savedResult = await ClinicalPdfGenerator.savePdf(
        pdfBytes: pdfBytes,
        fileName: caseRef,
      );

      if (mounted) {
        final targetToOpen = savedResult.uri ?? savedResult.path;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _language == 'ur'
                        ? 'رپورٹ ڈاؤن لوڈز میں کامیابی سے محفوظ ہو گئی / ${savedResult.fileName}'
                        : 'Report saved successfully to Downloads / ${savedResult.fileName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF004D40),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: _language == 'ur' ? 'کھولیں (Open)' : 'Open',
              textColor: Colors.tealAccent,
              onPressed: () => ClinicalPdfGenerator.openPdf(targetToOpen),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == 'ur'
                  ? 'پی ڈی ایف محفوظ کرنے میں خرابی پیش آگئی: $e'
                  : 'Failed to save clinical PDF: $e',
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _pdfActionLoadingMessage = null;
        });
      }
    }
  }

  Future<void> _handleSharePdf() async {
    if (_isGeneratingPdf) return;
    setState(() {
      _isGeneratingPdf = true;
      _pdfActionLoadingMessage = _language == 'ur'
          ? 'پی ڈی ایف شیئر کرنے کے لیے تیار کی جا رہی ہے...'
          : 'Preparing PDF for Sharing...';
    });

    try {
      final file =
          widget.imageFile ??
          (widget.summary.skinAnalysis.imagePath.isNotEmpty
              ? File(widget.summary.skinAnalysis.imagePath)
              : null);

      final pdfBytes = await ClinicalPdfGenerator.generateReportPdf(
        summary: widget.summary,
        imageFile: file,
        language: _language,
      );

      final caseRef = widget.summary.id.isNotEmpty
          ? 'MediScan_Report_${widget.summary.id.substring(0, math.min(6, widget.summary.id.length))}'
          : 'MediScan_Clinical_Report';

      await ClinicalPdfGenerator.sharePdf(
        pdfBytes: pdfBytes,
        fileName: caseRef,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == 'ur'
                  ? 'رپورٹ شیئر کرنے میں خرابی پیش آگئی: $e'
                  : 'Failed to share clinical handover: $e',
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _pdfActionLoadingMessage = null;
        });
      }
    }
  }

  Widget _buildExportAndShareActions(bool isUrdu) {
    if (_isGeneratingPdf) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.teal.shade50.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _pdfActionLoadingMessage ??
                    (isUrdu
                        ? 'کلینیکل پی ڈی ایف تیار کی جا رہی ہے...'
                        : 'Preparing Clinical Handover PDF...'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              label: Text(
                isUrdu ? 'محفوظ کریں (Save)' : 'Save PDF',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF004D40),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF004D40), width: 1.5),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleSavePdf,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(
                isUrdu ? 'شیئر کریں (Share)' : 'Share Report',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF004D40),
                elevation: 1,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handleSharePdf,
            ),
          ),
        ],
      ),
    );
  }
}
