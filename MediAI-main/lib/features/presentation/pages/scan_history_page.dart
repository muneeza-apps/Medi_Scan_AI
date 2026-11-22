import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/models/clinic_recommendation_model.dart';
import '../../../../core/models/scan_record_model.dart';
import '../../../../core/repositories/scan_repository.dart';
import '../../../../core/services/clinic_locator_service.dart';
import '../../../../core/services/locale_service.dart';
import '../../../../core/services/patient_profile_service.dart';
import '../widgets/emergency_red_flag_banner.dart';
import 'lesion_progression_page.dart';
import 'nearby_clinics_page.dart';

class ScanHistoryPage extends StatefulWidget {
  final VoidCallback? onNavigateToTriage;

  const ScanHistoryPage({super.key, this.onNavigateToTriage});

  @override
  State<ScanHistoryPage> createState() => _ScanHistoryPageState();
}

class _ScanHistoryPageState extends State<ScanHistoryPage> {
  List<ScanRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _records = ScanRepository.instance.scansNotifier.value;
    _isLoading = _records.isEmpty;
    ScanRepository.instance.scansNotifier.addListener(_onScansNotifierChanged);
    _loadRecords();
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

  Future<void> _loadRecords() async {
    final scans = await ScanRepository.instance.getAllScans();
    if (mounted) {
      setState(() {
        _records = scans;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecord(String id) async {
    await ScanRepository.instance.deleteScan(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan record deleted from local cache.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
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
        return const Color(0xFFFFEBEE);
      case 'moderate':
        return const Color(0xFFFFF3E0);
      case 'low':
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes.clamp(1, 59);
      return '$mins min${mins > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  (ScanRecord, ScanRecord)? _findAnatomicalMatch([ScanRecord? focused]) {
    if (focused != null &&
        ((focused.anatomicalLocation?.isNotEmpty ?? false) ||
            (focused.lesionTag?.isNotEmpty ?? false))) {
      for (final r in _records) {
        if (r.id != focused.id) {
          final locMatch = (focused.anatomicalLocation?.isNotEmpty ?? false) &&
              focused.anatomicalLocation == r.anatomicalLocation;
          final tagMatch = (focused.lesionTag?.isNotEmpty ?? false) &&
              focused.lesionTag == r.lesionTag;
          if (locMatch || tagMatch) {
            final baseline =
                focused.dateTime.isBefore(r.dateTime) ? focused : r;
            final followUp =
                focused.dateTime.isAfter(r.dateTime) ? focused : r;
            return (baseline, followUp);
          }
        }
      }
    }

    for (int i = 0; i < _records.length; i++) {
      final r1 = _records[i];
      final loc1 = r1.anatomicalLocation?.trim() ?? '';
      final tag1 = r1.lesionTag?.trim() ?? '';
      for (int j = i + 1; j < _records.length; j++) {
        final r2 = _records[j];
        final loc2 = r2.anatomicalLocation?.trim() ?? '';
        final tag2 = r2.lesionTag?.trim() ?? '';
        final bool matchedByLocation = loc1.isNotEmpty && loc1 == loc2;
        final bool matchedByTag = tag1.isNotEmpty && tag1 == tag2;
        if (matchedByLocation || matchedByTag) {
          final baseline = r1.dateTime.isBefore(r2.dateTime) ? r1 : r2;
          final followUp = r1.dateTime.isAfter(r2.dateTime) ? r1 : r2;
          return (baseline, followUp);
        }
      }
    }
    return null;
  }

  void _openProgressionComparison(bool isUrdu, {ScanRecord? initialBaseline}) {
    if (_records.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? 'موازنے کے لیے کم از کم 2 اسکین ریکارڈز درکار ہیں۔'
                : 'At least 2 scan records are required for timeline progression.',
          ),
          backgroundColor: const Color(0xFF004D40),
        ),
      );
      return;
    }

    final autoMatch = _findAnatomicalMatch(initialBaseline);
    if (autoMatch != null) {
      _showAutoMatchDialog(autoMatch.$1, autoMatch.$2, isUrdu);
    } else {
      _showCustomComparisonPicker(isUrdu, initialBaseline);
    }
  }

  void _showAutoMatchDialog(
    ScanRecord baseline,
    ScanRecord followUp,
    bool isUrdu,
  ) {
    final locationName = baseline.anatomicalLocation ??
        baseline.lesionTag ??
        baseline.lesionName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_mode_rounded,
                        color: Color(0xFF004D40),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu
                                ? 'ایک ہی عضو کے اسکینز ملے'
                                : 'Anatomical Match Detected',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
                            ),
                          ),
                          Text(
                            isUrdu
                                ? '$locationName کے لیے 2 تاریخوں کا ڈیٹا دستیاب ہے'
                                : 'Found recurring scans for "$locationName"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.difference_outlined),
                  label: Text(
                    isUrdu
                        ? 'ان 2 اسکینز کا فوری موازنہ کریں'
                        : 'Compare Matched Scans',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LesionProgressionPage(
                          baselineScan: baseline,
                          followUpScan: followUp,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004D40),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isUrdu
                        ? 'دیگر اسکینز خود منتخب کریں'
                        : 'Choose Different Scans',
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showCustomComparisonPicker(isUrdu, baseline);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomComparisonPicker(
    bool isUrdu, [
    ScanRecord? preselectedBaseline,
  ]) {
    ScanRecord? selectedBaseline = preselectedBaseline ??
        (_records.length > 1 ? _records.last : _records.first);
    ScanRecord? selectedFollowUp =
        _records.first.id != selectedBaseline.id ? _records.first : _records[1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isUrdu
                          ? 'موازنے کے لیے دو اسکینز منتخب کریں'
                          : 'Select 2 Scans to Compare',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUrdu
                          ? 'پہلا اسکین بطور بنیاد (Baseline) اور دوسرا بطور فالو اپ استعمال ہوگا'
                          : 'First serves as baseline reference, second as follow-up evaluation',
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _records[index];
                          final isBaseline = selectedBaseline?.id == item.id;
                          final isFollowUp = selectedFollowUp?.id == item.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isBaseline || isFollowUp
                                  ? const Color(0xFFE0F2F1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isBaseline || isFollowUp
                                    ? const Color(0xFF00796B)
                                    : const Color(0xFFE0E0E0),
                                width: isBaseline || isFollowUp ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.thumbnailPath.isNotEmpty &&
                                        File(item.thumbnailPath).existsSync()
                                    ? Image.file(
                                        File(item.thumbnailPath),
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        color: const Color(0xFFE0F2F1),
                                        child: const Icon(
                                          Icons.healing_rounded,
                                          color: Color(0xFF004D40),
                                          size: 20,
                                        ),
                                      ),
                              ),
                              title: Text(
                                item.lesionName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${item.dateTime.day}/${item.dateTime.month}/${item.dateTime.year} • ${item.anatomicalLocation ?? "Unspecified site"}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ChoiceChip(
                                    label: Text(
                                      isUrdu ? 'بنیاد' : 'Baseline',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isBaseline
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    selected: isBaseline,
                                    selectedColor: const Color(0xFF004D40),
                                    onSelected: (val) {
                                      if (val) {
                                        setModalState(() {
                                          selectedBaseline = item;
                                          if (selectedFollowUp?.id == item.id) {
                                            selectedFollowUp = _records.firstWhere(
                                              (r) => r.id != item.id,
                                              orElse: () => _records.first,
                                            );
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: Text(
                                      isUrdu ? 'فالو اپ' : 'Follow-up',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isFollowUp
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    selected: isFollowUp,
                                    selectedColor: const Color(0xFF00796B),
                                    onSelected: (val) {
                                      if (val) {
                                        setModalState(() {
                                          selectedFollowUp = item;
                                          if (selectedBaseline?.id == item.id) {
                                            selectedBaseline = _records.firstWhere(
                                              (r) => r.id != item.id,
                                              orElse: () => _records.last,
                                            );
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: selectedBaseline != null &&
                              selectedFollowUp != null &&
                              selectedBaseline!.id != selectedFollowUp!.id
                          ? () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LesionProgressionPage(
                                    baselineScan: selectedBaseline!,
                                    followUpScan: selectedFollowUp!,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        isUrdu ? 'موازنہ شروع کریں' : 'Launch Timeline Comparison',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailBottomSheet(ScanRecord record) {
    final riskColor = _getRiskColor(record.riskLevel);
    final riskBgColor = _getRiskBgColor(record.riskLevel);
    final isHighRisk = record.riskLevel.toLowerCase() == 'high';
    final isUrdu = LocaleService.isUrdu;

    final detectedCity = PatientProfileService.profile.city;
    final allClinics = record.recommendedClinics;
    final clinics = allClinics.take(3).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child:
                            record.thumbnailPath.isNotEmpty &&
                                File(record.thumbnailPath).existsSync()
                            ? Image.file(
                                File(record.thumbnailPath),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: const Color(0xFFE0F2F1),
                                child: const Icon(
                                  Icons.healing_rounded,
                                  color: Color(0xFF004D40),
                                  size: 32,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.lesionName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004D40),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Captured ${record.dateTime.day}/${record.dateTime.month}/${record.dateTime.year} • ${(record.confidenceScore * 100).toStringAsFixed(1)}% Confidence',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: riskBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: riskColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '${record.riskLevel} Clinical Risk',
                                style: TextStyle(
                                  color: riskColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (EmergencyRedFlagBanner.isHighRiskSeverity(
                    riskLevel: record.riskLevel,
                    conditionName: record.lesionName,
                    confidence: record.confidenceScore,
                  )) ...[
                    EmergencyRedFlagBanner(
                      isUrdu: isUrdu,
                      clinics: record.recommendedClinics,
                      onFindTertiaryHospital: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NearbyClinicsPage(
                              cityName: detectedCity,
                              clinics: allClinics,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              size: 18,
                              color: Color(0xFF00796B),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ABCDE Clinical Criteria Evaluation',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004D40),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _buildAbcdeRow(
                          'A',
                          'Asymmetry',
                          isHighRisk
                              ? 'Elevated structural variance'
                              : 'Symmetrical borders',
                        ),
                        _buildAbcdeRow(
                          'B',
                          'Border',
                          isHighRisk
                              ? 'Irregular or notched perimeter'
                              : 'Smooth, regular margin',
                        ),
                        _buildAbcdeRow(
                          'C',
                          'Color',
                          isHighRisk
                              ? 'Variegated pigment spectrum'
                              : 'Uniform coloration',
                        ),
                        _buildAbcdeRow(
                          'D',
                          'Diameter',
                          'Target model framing (1:1 square crop)',
                        ),
                        _buildAbcdeRow(
                          'E',
                          'Evolving',
                          'Track progression across sequential scans',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (record.clinicalRecommendations.isNotEmpty) ...[
                    const Text(
                      'Clinical Recommendations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...record.clinicalRecommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                rec,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (clinics.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.local_hospital_rounded,
                          size: 18,
                          color: Color(0xFF00796B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUrdu
                                    ? 'قریبی طبی مراکز'
                                    : 'Nearby Healthcare Facilities',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                              Text(
                                isUrdu
                                    ? '$detectedCity کے قریبی طبی مراکز'
                                    : 'Healthcare Centers Near $detectedCity',
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
                    ...clinics.map(
                      (clinic) => _buildDetailClinicCard(clinic, isUrdu),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF004D40),
                          side: const BorderSide(
                            color: Color(0xFF00796B),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NearbyClinicsPage(
                                cityName: detectedCity,
                                clinics: allClinics,
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
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_records.length >= 2) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF004D40),
                          side: const BorderSide(
                            color: Color(0xFF00796B),
                            width: 1.3,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.difference_outlined, size: 18),
                        label: Text(
                          isUrdu
                              ? 'دوسرے اسکین کے ساتھ ارتقائی موازنہ کریں'
                              : 'Compare Progression with Another Scan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openProgressionComparison(
                            isUrdu,
                            initialBaseline: record,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete Record'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _deleteRecord(record.id);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004D40),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Close'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailClinicCard(ClinicRecommendation clinic, bool isUrdu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF80CBC4), width: 1.2),
      ),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clinic.specialty,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      clinic.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  clinic.address,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
          if (clinic.distanceKm != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.near_me_outlined,
                    size: 11,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isUrdu
                        ? '${clinic.distanceKm!.toStringAsFixed(1)} کلومیٹر دور'
                        : '${clinic.distanceKm!.toStringAsFixed(1)} km away',
                    style: const TextStyle(
                      fontSize: 10,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isUrdu ? 'ماہر امراض جلد (Dermatology)' : 'Dermatology',
                  style: const TextStyle(
                    fontSize: 10,
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
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.phone_outlined, size: 13),
                  label: Text(
                    isUrdu ? 'کال کریں' : 'Call',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      ClinicLocatorService.launchDialer(clinic.contactNumber),
                ),
                const SizedBox(width: 6),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.directions_outlined, size: 13),
                label: Text(
                  isUrdu ? 'راستہ دیکھیں' : 'Get Directions',
                  style: const TextStyle(
                    fontSize: 10.5,
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
    );
  }

  Widget _buildAbcdeRow(String letter, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';

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
                  const Icon(Icons.history_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    isUrdu ? 'اسکین ریکارڈز' : 'Scan Records',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              actions: [
                if (_records.length >= 2)
                  IconButton(
                    icon: const Icon(Icons.difference_outlined),
                    tooltip: isUrdu
                        ? 'ارتقائی موازنہ کریں'
                        : 'Compare Lesion Progression',
                    onPressed: () => _openProgressionComparison(isUrdu),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: isUrdu ? 'تازہ کریں' : 'Refresh Records',
                  onPressed: _loadRecords,
                ),
              ],
            ),
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00796B)),
                  )
                : _records.isEmpty
                ? _buildEmptyState(isUrdu)
                : RefreshIndicator(
                    color: const Color(0xFF00796B),
                    onRefresh: _loadRecords,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: _records.length >= 2
                          ? _records.length + 1
                          : _records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (_records.length >= 2 && index == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF004D40), Color(0xFF00695C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF004D40)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.difference_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUrdu
                                            ? 'زخم کا ارتقائی موازنہ'
                                            : 'Compare Lesion Progression',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isUrdu
                                            ? 'سائز، رنگ اور شکل میں تبدیلیوں کی مانیٹرنگ'
                                            : 'Side-by-side ABCDE comparative timeline',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF004D40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _openProgressionComparison(isUrdu),
                                  child: Text(
                                    isUrdu ? 'موازنہ' : 'Compare',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final record = _records[
                            _records.length >= 2 ? index - 1 : index];
                        final riskColor = _getRiskColor(record.riskLevel);
                        final riskBgColor = _getRiskBgColor(record.riskLevel);

                        return Dismissible(
                          key: Key(record.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          onDismissed: (_) => _deleteRecord(record.id),
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showDetailBottomSheet(record),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          record.thumbnailPath.isNotEmpty &&
                                              File(record.thumbnailPath)
                                                  .existsSync()
                                          ? Image.file(
                                              File(record.thumbnailPath),
                                              width: 58,
                                              height: 58,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 58,
                                              height: 58,
                                              color: const Color(0xFFE0F2F1),
                                              child: const Icon(
                                                Icons.healing_rounded,
                                                color: Color(0xFF004D40),
                                                size: 26,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.lesionName,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF004D40),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatDate(record.dateTime)} • ${(record.confidenceScore * 100).toStringAsFixed(0)}% Match',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (record.anatomicalLocation !=
                                                  null &&
                                              record.anatomicalLocation!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 13,
                                                  color: Color(0xFF00796B),
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    record.anatomicalLocation!,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF00796B),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: riskBgColor,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: riskColor.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            record.riskLevel,
                                            style: TextStyle(
                                              color: riskColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () =>
                                              _showDetailBottomSheet(record),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isUrdu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF80CBC4), width: 1.5),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isUrdu ? 'کوئی ریکارڈ موجود نہیں' : 'No Scan Records Yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUrdu
                  ? 'میڈی اے آئی کے تجزیہ کردہ تمام اسکینز یہاں آپ کی ڈیوائس پر محفوظ ہوں گے۔'
                  : 'Captured skin lesions analyzed by MediAI will be safely archived here on your device.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (widget.onNavigateToTriage != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.photo_camera_rounded, size: 18),
                label: Text(
                  isUrdu ? 'نیا اسکین شروع کریں' : 'Start First Triage Scan',
                ),
                onPressed: widget.onNavigateToTriage,
              ),
          ],
        ),
      ),
    );
  }
}
