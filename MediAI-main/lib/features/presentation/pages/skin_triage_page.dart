import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediscanai/core/services/locale_service.dart';

import '../../../core/models/triage_draft_model.dart';
import '../../../core/services/triage_draft_storage.dart';
import '../../domain/domain.dart';
import '../presentation.dart';

class SkinTriagePage extends StatefulWidget {
  const SkinTriagePage({super.key});

  static Future<bool> showClinicalCroppingGuidanceDialog(
    BuildContext context, {
    bool isUrdu = false,
  }) => _SkinTriagePageState.showClinicalCroppingGuidanceDialog(context, isUrdu: isUrdu);

  @override
  State<SkinTriagePage> createState() => _SkinTriagePageState();
}

class _SkinTriagePageState extends State<SkinTriagePage> {
  final TextEditingController _symptomsController = TextEditingController(
    text: '',
  );
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _lesionTagController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  String _selectedLanguage = 'en';
  String? _selectedAnatomicalLocation;
  List<TriageDraft> _localDrafts = const [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final drafts = await TriageDraftStorage.getAllDrafts();
    if (mounted) {
      setState(() {
        _localDrafts = drafts;
      });
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _medicationController.dispose();
    _lesionTagController.dispose();

    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final isUrdu = LocaleService.isUrdu;

      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      if (!mounted) return;

      final proceed = await _showClinicalCroppingGuidanceDialog(
        context,
        isUrdu,
      );
      if (!proceed || !mounted) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        maxWidth: 300,
        maxHeight: 300,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isUrdu
                ? 'جلد کے نشان کا فریم (1:1)'
                : 'Clinical Lesion Cropper (1:1 Square)',
            toolbarColor: const Color(0xFF004D40),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF00796B),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            cropGridColor: const Color(0xFF80CBC4),
            cropFrameColor: const Color(0xFF00796B),
            cropGridRowCount: 2,
            cropGridColumnCount: 2,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: isUrdu
                ? 'جلد کے نشان کا فریم (1:1)'
                : 'Clinical Lesion Cropper (1:1 Square)',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint("Inference Input Path: ${croppedFile.path}");
        setState(() => _selectedImagePath = croppedFile.path);
        if (!mounted) return;
        context.read<TriageBloc>().add(
          PickAndAnalyzeImage(
            imagePath: croppedFile.path,
            anatomicalLocation: _selectedAnatomicalLocation,
            lesionTag: _lesionTagController.text.trim().isEmpty
                ? null
                : _lesionTagController.text.trim(),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu
                  ? 'کراپنگ منسوخ کر دی گئی۔ AI تجزیہ کے لیے تصویر کا فریم بنانا ضروری ہے۔'
                  : 'Cropping canceled. Skin lesion framing is required for AI triage analysis.',
            ),
            backgroundColor: const Color(0xFF004D40),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to acquire lesion image: $e')),
      );
    }
  }

  Future<bool> _showClinicalCroppingGuidanceDialog(
    BuildContext context,
    bool isUrdu,
  ) => showClinicalCroppingGuidanceDialog(context, isUrdu: isUrdu);

  static Future<bool> showClinicalCroppingGuidanceDialog(
    BuildContext context, {
    bool isUrdu = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.crop_square_rounded,
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
                                    ? 'طبی رہنمائی برائے تصویر'
                                    : 'Clinical Framing Guidance',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isUrdu
                                    ? 'درست تشخیص کے لیے صرف داغ کو فریم میں رکھیں'
                                    : 'Target only the lesion for accurate AI triage',
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        children: [
                          _buildInstructionRow(
                            icon: Icons.filter_center_focus_rounded,
                            title: isUrdu
                                ? 'مربع فریم (300x300)'
                                : '1:1 Square Target (300x300)',
                            desc: isUrdu
                                ? 'بہتر نتائج کے لیے داغ کو مربع فریم کے بالکل درمیان میں رکھیں۔'
                                : 'Center the lesion inside a 1:1 square frame for optimal clinical triage.',
                          ),
                          const Divider(height: 16),
                          _buildInstructionRow(
                            icon: Icons.blur_off_rounded,
                            title: isUrdu ? 'صرف داغ کا انتخاب' : 'Isolate Lesion',
                            desc: isUrdu
                                ? 'کپڑے، سایہ اور ارد گرد کی اشیاء فریم سے باہر رکھیں۔'
                                : 'Exclude clothing, shadows, and surrounding background objects.',
                          ),
                          const Divider(height: 16),
                          _buildInstructionRow(
                            icon: Icons.cloud_done_outlined,
                            title: isUrdu ? 'اصل تصویر محفوظ رہے گی' : 'Original Preserved',
                            desc: isUrdu
                                ? 'مکمل تصویر آپ کے میڈیکل ریکارڈ کے لیے محفوظ رہے گی۔'
                                : 'Full-resolution uncropped original is preserved in records.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.crop_rounded),
                      label: Text(
                        isUrdu
                            ? 'داغ کو ایڈجسٹ اور کروپ کریں'
                            : 'Adjust & Crop Lesion',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        isUrdu ? 'منسوخ کریں' : 'Cancel',
                        style: const TextStyle(color: Colors.grey),
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
    return result ?? false;
  }

  static Widget _buildInstructionRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00796B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11.5, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = locale.languageCode == 'ur';
        _selectedLanguage = locale.languageCode;

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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.healing_rounded, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'میڈی اے آئی' : 'MediAI',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isUrdu
                              ? 'ایج-AI جلد کا معائنہ اور بائیو سینسر ٹیلی میٹری'
                              : 'Edge-AI Dermatology & Telemetry',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: isUrdu ? 'ری سیٹ کریں' : 'Reset Triage',
                  onPressed: () {
                    setState(() => _selectedImagePath = null);
                    context.read<TriageBloc>().add(const ResetTriage());
                  },
                ),
              ],
            ),
            body: BlocConsumer<TriageBloc, TriageState>(
              listener: (context, state) {
                if (state is TriageFailure) {
                  _loadDrafts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: state.message.contains('Offline Mode')
                          ? const Color(0xFFD97706)
                          : Colors.red.shade800,
                    ),
                  );
                } else if (state is TriageSkinAnalyzed) {
                  _loadDrafts();
                  final skin = state.skinAnalysis;
                  context.read<ClinicalSessionBloc>().add(
                    AttachSkinScanResult(
                      SkinScanResult(
                        imagePath: skin.imagePath,
                        conditionName: skin.conditionName,
                        confidence: skin.confidence,
                        severity: skin.effectiveRiskLevel,
                        lesionType: skin.taxonomy.plainVernacularEn.isNotEmpty
                            ? skin.taxonomy.plainVernacularEn
                            : skin.conditionName,
                        scannedAt: DateTime.now(),
                        entity: skin,
                      ),
                    ),
                  );
                } else if (state is TriageSuccess) {
                  _loadDrafts();
                  context.read<ClinicalSessionBloc>().add(
                    SynthesizeUnifiedReport(
                      symptoms: state.summary.symptoms,
                      medication: state.summary.medication,
                      triageSummary: state.summary,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isAnalyzing = state is TriageAnalyzingSkin;
                final isGenerating = state is TriageGeneratingGenUi;

                final SkinAnalysisEntity? skinAnalysis = switch (state) {
                  TriageSkinAnalyzed s => s.skinAnalysis,
                  TriageGeneratingGenUi g => g.skinAnalysis,
                  TriageSuccess s => s.summary.skinAnalysis,
                  _ => null,
                };

                final summary = state is TriageSuccess ? state.summary : null;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      BlocBuilder<ClinicalSessionBloc, ClinicalSessionState>(
                        builder: (context, session) {
                          if (session.isVitalsAttached &&
                              session.vitals != null &&
                              session.vitals!.isValid) {
                            final v = session.vitals!;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00382E).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF00BFA5),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF004D40).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF004D40),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.monitor_heart,
                                      color: Color(0xFF64FFDA),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                isUrdu
                                                    ? 'طبی وائٹلز منسلک ہیں'
                                                    : 'Hemodynamic Baseline Attached',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF69F0AE),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF004D40),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: const Color(0xFF00E676),
                                                  width: 0.6,
                                                ),
                                              ),
                                              child: Text(
                                                'Captured ${v.formattedCaptureTime}',
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF69F0AE),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Pulse: ${v.heartRate} BPM • SpO₂: ${v.spo2}% • Temp: ${v.temperature.toStringAsFixed(1)}°C',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFFE0F2F1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      if (_localDrafts.isNotEmpty) ...[
                        _buildOfflineDraftQueueSection(isUrdu),
                        const SizedBox(height: 16),
                      ],
                      _buildLesionCaptureCard(
                        isAnalyzing: isAnalyzing,
                        skinAnalysis: skinAnalysis,
                        isUrdu: isUrdu,
                      ),
                      const SizedBox(height: 16),
                      _buildClinicalInputsCard(
                        isGenerating || summary != null,
                        isUrdu,
                      ),
                      const SizedBox(height: 16),
                      _buildOrchestrationAction(
                        isGenerating,
                        skinAnalysis,
                        summary != null,
                        isUrdu,
                      ),
                      const SizedBox(height: 20),
                      if (summary != null) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF00796B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isUrdu
                                    ? 'کلینیکل ٹرائیج اور مریض کی رہنمائی'
                                    : 'Clinical Triage Synthesis',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GenUiSurfaceView(
                          summary: summary,
                          initialLanguage: _selectedLanguage,
                          imageFile: _selectedImagePath != null
                              ? File(_selectedImagePath!)
                              : null,
                          onLanguageChanged: (lang) {
                            setState(() => _selectedLanguage = lang);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLesionCaptureCard({
    required bool isAnalyzing,
    required SkinAnalysisEntity? skinAnalysis,
    required bool isUrdu,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt_outlined, color: Color(0xFF00796B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu
                        ? 'جلد کے داغ اور تل کا تصویری معائنہ'
                        : 'Dermatological Lesion Analysis',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                    softWrap: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isUrdu ? 'آف لائن' : 'Offline',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImagePath != null &&
                File(_selectedImagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_selectedImagePath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF00796B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu
                                ? 'طبی معائنہ اور فوری درجہ بندی جاری ہے...'
                                : 'Analyzing lesion on-device...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUrdu
                                ? 'محفوظ آف لائن پروسیسنگ'
                                : 'Fast offline clinical triage',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              PreCaptureGuidanceCard(isUrdu: isUrdu),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera, size: 18),
                        label: Text(isUrdu ? 'کیمرا' : 'Camera'),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: Text(isUrdu ? 'گیلری' : 'Gallery'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (skinAnalysis != null) ...[
              const Divider(height: 24),
              _buildSingleDiagnosisCard(skinAnalysis, isUrdu),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleDiagnosisCard(
    SkinAnalysisEntity skinAnalysis,
    bool isUrdu,
  ) {
    return SingleDiagnosisCard(
      skinAnalysis: skinAnalysis,
      isUrdu: isUrdu,
      onRetakePhoto: () => _pickImage(ImageSource.camera),
    );
  }

  Widget _buildClinicalInputsCard(bool isReadOnly, bool isUrdu) {
    const locations = [
      ('Left Arm', 'بایاں بازو'),
      ('Right Arm', 'دایاں بازو'),
      ('Face & Lips', 'چہرہ اور ہونٹ'),
      ('Neck', 'گردن'),
      ('Chest', 'سینہ'),
      ('Back', 'کمر'),
      ('Left Leg', 'بائیں ٹانگ'),
      ('Right Leg', 'دائیں ٹانگ'),
      ('Other Area', 'دیگر حصہ'),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF00796B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu
                      ? 'نشان جسم کے کس حصے پر ہے؟'
                      : 'Where is the spot on your body?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: locations.map((loc) {
                final isSelected = _selectedAnatomicalLocation == loc.$1;
                return ChoiceChip(
                  label: Text(isUrdu ? loc.$2 : loc.$1),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0F5132),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0F5132)
                        : const Color(0xFFD1D5DB),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onSelected: isReadOnly
                      ? null
                      : (selected) {
                          setState(() {
                            _selectedAnatomicalLocation =
                                selected ? loc.$1 : null;
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lesionTagController,
              enabled: !isReadOnly,
              decoration: InputDecoration(
                labelText: isUrdu
                    ? 'نشان کا نام یا یاد دہانی (اختیاری)'
                    : 'Spot Note / Label (Optional)',
                hintText: isUrdu
                    ? 'نشان کا نام یا یاد دہانی درج کریں...'
                    : 'e.g. Arm spot, upper back mole...',
                prefixIcon: const Icon(
                  Icons.label_outline,
                  color: Color(0xFF00796B),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.notes_rounded, color: Color(0xFF00796B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu
                        ? 'علامات اور ادویات'
                        : 'Your Symptoms & Medicines',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _symptomsController,
              maxLines: 3,
              enabled: !isReadOnly,
              decoration: InputDecoration(
                labelText: isUrdu
                    ? 'کیفیت اور علامات'
                    : 'Symptoms',
                hintText: isUrdu
                    ? 'کیفیت لکھیں (مثلاً 3 دن سے شدید خارش، جلن، یا پھیلنا)'
                    : 'Describe what you feel (e.g. severe itching since 3 days, burning, spreading)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _medicationController,
              enabled: !isReadOnly,
              decoration: InputDecoration(
                labelText: isUrdu
                    ? 'فی الوقت استعمال ہونے والی دوائیاں'
                    : 'Any creams or medicines',
                hintText: isUrdu
                    ? 'فی الوقت استعمال ہونے والی کوئی کریم یا دوائی'
                    : 'Any creams or medicines you are using currently',
                prefixIcon: const Icon(Icons.medication_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineDraftQueueSection(bool isUrdu) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isUrdu
                      ? 'آف لائن ڈرافٹ قطار (${_localDrafts.length})'
                      : 'Offline Triage Draft Queue (${_localDrafts.length})',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isUrdu
                ? 'انٹرنیٹ نہ ہونے پر محفوظ کی گئی تصاویر۔ دوبارہ ٹرائیج کے لیے ایک ٹیپ کریں۔'
                : 'Scans captured while offline. Tap to analyze immediately once connected.',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
          ),
          const SizedBox(height: 12),
          ..._localDrafts.map((draft) {
            final hasFile = File(draft.imagePath).existsSync();
            final dateStr =
                '${draft.createdAt.day}/${draft.createdAt.month} ${draft.createdAt.hour.toString().padLeft(2, '0')}:${draft.createdAt.minute.toString().padLeft(2, '0')}';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasFile
                        ? Image.file(
                            File(draft.imagePath),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.lesionTag ??
                              (draft.anatomicalLocation != null
                                  ? draft.anatomicalLocation!
                                  : (isUrdu
                                        ? 'غیر نامزد نشان'
                                        : 'Unlabeled Lesion')),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (draft.anatomicalLocation != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  draft.anatomicalLocation!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF004D40),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 11.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = draft.imagePath;
                        if (draft.anatomicalLocation != null) {
                          _selectedAnatomicalLocation =
                              draft.anatomicalLocation;
                        }
                        if (draft.lesionTag != null) {
                          _lesionTagController.text = draft.lesionTag!;
                        }
                        if (draft.symptoms != null &&
                            draft.symptoms!.isNotEmpty) {
                          _symptomsController.text = draft.symptoms!;
                        }
                        if (draft.medication != null &&
                            draft.medication!.isNotEmpty) {
                          _medicationController.text = draft.medication!;
                        }
                      });
                      context.read<TriageBloc>().add(
                        PickAndAnalyzeImage(
                          imagePath: draft.imagePath,
                          anatomicalLocation: draft.anatomicalLocation,
                          lesionTag: draft.lesionTag,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 14),
                    label: Text(isUrdu ? 'تجزیہ' : 'Analyze'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () async {
                      await TriageDraftStorage.deleteDraft(draft.id);
                      await _loadDrafts();
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrchestrationAction(
    bool isGenerating,
    SkinAnalysisEntity? skinAnalysis,
    bool hasReport,
    bool isUrdu,
  ) {
    final currentAnalysis = skinAnalysis;

    final bool isEligibleTriageState = currentAnalysis != null &&
        !currentAnalysis.isNonSkin &&
        !currentAnalysis.isInconclusive &&
        currentAnalysis.predictedLabel != 'non_skin' &&
        (currentAnalysis.isHighConfidenceLesion ||
            currentAnalysis.isDifferentialAssessment ||
            (currentAnalysis.tier == TriageTier.highConfidenceLesion &&
                currentAnalysis.topPredictions.isNotEmpty));

    final bool isLocationSelected = _selectedAnatomicalLocation != null &&
        _selectedAnatomicalLocation!.trim().isNotEmpty;

    final bool canGenerateReport = isEligibleTriageState && isLocationSelected;
    final bool isActionDisabled = isGenerating || !canGenerateReport;

    final String label = isGenerating
        ? (isUrdu
              ? 'طبی رپورٹ تیار کی جا رہی ہے...'
              : 'Synthesizing Clinical Report...')
        : (currentAnalysis == null
              ? (isUrdu
                    ? 'ٹرائیج شروع کرنے کے لیے تصویر منتخب کریں'
                    : 'Scan Lesion to Enable Triage')
              : (!isEligibleTriageState
                    ? (isUrdu
                          ? 'جلد کی درست اور واضح تصویر درکار ہے (بٹن غیر فعال)'
                          : 'Valid Lesion Scan Required (Button Disabled)')
                    : (!isLocationSelected
                          ? (isUrdu
                                ? 'جسم کا حصہ منتخب کریں'
                                : 'Select Body Location')
                          : (isUrdu
                                ? 'طبی رپورٹ تیار کریں'
                                : 'Generate Skin Summary Report'))));

    final IconData actionIcon = !isEligibleTriageState && currentAnalysis != null
        ? Icons.block
        : Icons.auto_awesome;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActionDisabled && !isGenerating
              ? Colors.grey.shade400
              : const Color(0xFF004D40),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isActionDisabled
            ? null
            : () {
                context.read<TriageBloc>().add(
                  SubmitFullTriage(
                    symptoms: _symptomsController.text.trim(),
                    medication: _medicationController.text.trim(),
                    anatomicalLocation: _selectedAnatomicalLocation,
                    lesionTag: _lesionTagController.text.trim().isEmpty
                        ? null
                        : _lesionTagController.text.trim(),
                  ),
                );
              },
        icon: isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(actionIcon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
