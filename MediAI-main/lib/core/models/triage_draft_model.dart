import 'dart:convert';

class TriageDraft {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  final String? symptoms;
  final String? medication;
  final String? anatomicalLocation;
  final String? lesionTag;

  const TriageDraft({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    this.symptoms,
    this.medication,
    this.anatomicalLocation,
    this.lesionTag,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'symptoms': symptoms,
      'medication': medication,
      'anatomicalLocation': anatomicalLocation,
      'lesionTag': lesionTag,
    };
  }

  factory TriageDraft.fromMap(Map<String, dynamic> map) {
    return TriageDraft(
      id: map['id'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      symptoms: map['symptoms'] as String?,
      medication: map['medication'] as String?,
      anatomicalLocation: map['anatomicalLocation'] as String?,
      lesionTag: map['lesionTag'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory TriageDraft.fromJson(String source) =>
      TriageDraft.fromMap(json.decode(source) as Map<String, dynamic>);

  TriageDraft copyWith({
    String? id,
    String? imagePath,
    DateTime? createdAt,
    String? symptoms,
    String? medication,
    String? anatomicalLocation,
    String? lesionTag,
  }) {
    return TriageDraft(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      symptoms: symptoms ?? this.symptoms,
      medication: medication ?? this.medication,
      anatomicalLocation: anatomicalLocation ?? this.anatomicalLocation,
      lesionTag: lesionTag ?? this.lesionTag,
    );
  }
}
