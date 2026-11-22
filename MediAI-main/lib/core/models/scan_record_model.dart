import 'dart:convert';

import 'clinic_recommendation_model.dart';

class ScanRecord {
  final String id;
  final DateTime dateTime;
  final String lesionName;
  final String riskLevel;
  final double confidenceScore;
  final String thumbnailPath;
  final List<String> clinicalRecommendations;
  final List<ClinicRecommendation> recommendedClinics;
  final String? anatomicalLocation;
  final String? lesionTag;

  const ScanRecord({
    required this.id,
    required this.dateTime,
    required this.lesionName,
    required this.riskLevel,
    required this.confidenceScore,
    required this.thumbnailPath,
    required this.clinicalRecommendations,
    this.recommendedClinics = const [],
    this.anatomicalLocation,
    this.lesionTag,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'lesionName': lesionName,
      'riskLevel': riskLevel,
      'confidenceScore': confidenceScore,
      'thumbnailPath': thumbnailPath,
      'clinicalRecommendations': clinicalRecommendations,
      'recommendedClinics': recommendedClinics.map((c) => c.toMap()).toList(),
      'anatomicalLocation': anatomicalLocation,
      'lesionTag': lesionTag,
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as String? ?? '',
      dateTime: map['dateTime'] != null
          ? DateTime.tryParse(map['dateTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      lesionName: map['lesionName'] as String? ?? 'Unknown Lesion',
      riskLevel: map['riskLevel'] as String? ?? 'Low',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      thumbnailPath: map['thumbnailPath'] as String? ?? '',
      clinicalRecommendations:
          (map['clinicalRecommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendedClinics: (map['recommendedClinics'] as List<dynamic>?)
              ?.map(
                (e) => ClinicRecommendation.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      anatomicalLocation: map['anatomicalLocation'] as String?,
      lesionTag: map['lesionTag'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScanRecord.fromJson(String source) =>
      ScanRecord.fromMap(json.decode(source) as Map<String, dynamic>);

  ScanRecord copyWith({
    String? id,
    DateTime? dateTime,
    String? lesionName,
    String? riskLevel,
    double? confidenceScore,
    String? thumbnailPath,
    List<String>? clinicalRecommendations,
    List<ClinicRecommendation>? recommendedClinics,
    String? anatomicalLocation,
    String? lesionTag,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      lesionName: lesionName ?? this.lesionName,
      riskLevel: riskLevel ?? this.riskLevel,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      clinicalRecommendations:
          clinicalRecommendations ?? this.clinicalRecommendations,
      recommendedClinics: recommendedClinics ?? this.recommendedClinics,
      anatomicalLocation: anatomicalLocation ?? this.anatomicalLocation,
      lesionTag: lesionTag ?? this.lesionTag,
    );
  }
}
