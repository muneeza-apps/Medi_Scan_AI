import 'skin_analysis_entity.dart';
import 'triage_summary_entity.dart';

class VitalsSnapshot {
  final int heartRate;
  final int spo2;
  final double temperature;
  final DateTime capturedAt;
  final bool isLocked;

  const VitalsSnapshot({
    required this.heartRate,
    required this.spo2,
    required this.temperature,
    required this.capturedAt,
    this.isLocked = true,
  });

  int get bpm => heartRate;
  double get temperatureFahrenheit => (temperature * 9.0 / 5.0) + 32.0;

  bool get isValid => heartRate > 40 && spo2 > 70;
  bool get isHypoxic => spo2 > 70 && spo2 < 90;
  bool get isTachycardic => heartRate > 115;
  bool get isBradycardic => heartRate > 40 && heartRate < 50;
  bool get isPeripheralHypothermia => temperature > 25.0 && temperature < 28.0;
  bool get isNormalPeripheralTemp => temperature >= 29.5 && temperature <= 36.2;
  bool get isElevatedPeripheralTemp => temperature > 36.5;
  bool get isFebrile => isElevatedPeripheralTemp;
  bool get isCritical =>
      isValid &&
      (isHypoxic ||
          isTachycardic ||
          isBradycardic ||
          isFebrile ||
          isPeripheralHypothermia);

  String get formattedCaptureTime {
    final h = capturedAt.hour.toString().padLeft(2, '0');
    final m = capturedAt.minute.toString().padLeft(2, '0');
    final s = capturedAt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  VitalsSnapshot copyWith({
    int? heartRate,
    int? spo2,
    double? temperature,
    DateTime? capturedAt,
    bool? isLocked,
  }) {
    return VitalsSnapshot(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      temperature: temperature ?? this.temperature,
      capturedAt: capturedAt ?? this.capturedAt,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'capturedAt': capturedAt.toIso8601String(),
      'isLocked': isLocked,
    };
  }

  factory VitalsSnapshot.fromJson(Map<String, dynamic> json) {
    return VitalsSnapshot(
      heartRate: (json['heartRate'] as num?)?.toInt() ?? 0,
      spo2: (json['spo2'] as num?)?.toInt() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isLocked: json['isLocked'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VitalsSnapshot &&
          runtimeType == other.runtimeType &&
          heartRate == other.heartRate &&
          spo2 == other.spo2 &&
          (temperature - other.temperature).abs() < 0.01 &&
          capturedAt == other.capturedAt &&
          isLocked == other.isLocked;

  @override
  int get hashCode =>
      heartRate.hashCode ^
      spo2.hashCode ^
      temperature.hashCode ^
      capturedAt.hashCode ^
      isLocked.hashCode;

  @override
  String toString() =>
      'VitalsSnapshot($heartRate BPM, $spo2% SpO2, $temperature°C at $formattedCaptureTime)';
}

class SkinScanResult {
  final String imagePath;
  final String conditionName;
  final double confidence;
  final String severity;
  final String lesionType;
  final DateTime scannedAt;
  final SkinAnalysisEntity? entity;

  const SkinScanResult({
    required this.imagePath,
    required this.conditionName,
    required this.confidence,
    required this.severity,
    required this.lesionType,
    required this.scannedAt,
    this.entity,
  });

  SkinScanResult copyWith({
    String? imagePath,
    String? conditionName,
    double? confidence,
    String? severity,
    String? lesionType,
    DateTime? scannedAt,
    SkinAnalysisEntity? entity,
  }) {
    return SkinScanResult(
      imagePath: imagePath ?? this.imagePath,
      conditionName: conditionName ?? this.conditionName,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      lesionType: lesionType ?? this.lesionType,
      scannedAt: scannedAt ?? this.scannedAt,
      entity: entity ?? this.entity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'conditionName': conditionName,
      'confidence': confidence,
      'severity': severity,
      'lesionType': lesionType,
      'scannedAt': scannedAt.toIso8601String(),
      'entity': entity?.toJson(),
    };
  }

  factory SkinScanResult.fromJson(Map<String, dynamic> json) {
    return SkinScanResult(
      imagePath: json['imagePath'] as String? ?? '',
      conditionName: json['conditionName'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'Moderate',
      lesionType: json['lesionType'] as String? ?? 'Skin Lesion',
      scannedAt: json['scannedAt'] != null
          ? DateTime.tryParse(json['scannedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      entity: json['entity'] != null
          ? SkinAnalysisEntity.fromJson(json['entity'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkinScanResult &&
          runtimeType == other.runtimeType &&
          imagePath == other.imagePath &&
          conditionName == other.conditionName &&
          (confidence - other.confidence).abs() < 0.01 &&
          severity == other.severity &&
          lesionType == other.lesionType &&
          scannedAt == other.scannedAt;

  @override
  int get hashCode =>
      imagePath.hashCode ^
      conditionName.hashCode ^
      confidence.hashCode ^
      severity.hashCode ^
      lesionType.hashCode ^
      scannedAt.hashCode;
}

enum SessionStatus {
  idle,
  capturing,
  readyForSynthesis,
  completed,
}

class UnifiedClinicalReport {
  final String reportId;
  final VitalsSnapshot? vitals;
  final SkinScanResult? skinResult;
  final TriageSummaryEntity? triageSummary;
  final String clinicalSynthesis;
  final List<String> clinicalObservations;
  final List<String> protocolRecommendations;
  final String riskLevel;
  final DateTime synthesizedAt;

  const UnifiedClinicalReport({
    required this.reportId,
    this.vitals,
    this.skinResult,
    this.triageSummary,
    required this.clinicalSynthesis,
    this.clinicalObservations = const [],
    this.protocolRecommendations = const [],
    required this.riskLevel,
    required this.synthesizedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'vitals': vitals?.toJson(),
      'skinResult': skinResult?.toJson(),
      'triageSummary': triageSummary?.toJson(),
      'clinicalSynthesis': clinicalSynthesis,
      'clinicalObservations': clinicalObservations,
      'protocolRecommendations': protocolRecommendations,
      'riskLevel': riskLevel,
      'synthesizedAt': synthesizedAt.toIso8601String(),
    };
  }

  factory UnifiedClinicalReport.fromJson(Map<String, dynamic> json) {
    return UnifiedClinicalReport(
      reportId: json['reportId'] as String? ?? '',
      vitals: json['vitals'] != null
          ? VitalsSnapshot.fromJson(json['vitals'] as Map<String, dynamic>)
          : null,
      skinResult: json['skinResult'] != null
          ? SkinScanResult.fromJson(json['skinResult'] as Map<String, dynamic>)
          : null,
      triageSummary: json['triageSummary'] != null
          ? TriageSummaryEntity.fromJson(
              json['triageSummary'] as Map<String, dynamic>,
            )
          : null,
      clinicalSynthesis: json['clinicalSynthesis'] as String? ?? '',
      clinicalObservations:
          (json['clinicalObservations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      protocolRecommendations:
          (json['protocolRecommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      riskLevel: json['riskLevel'] as String? ?? 'Moderate',
      synthesizedAt: json['synthesizedAt'] != null
          ? DateTime.tryParse(json['synthesizedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
