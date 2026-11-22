class SkinRiskClassifier {
  SkinRiskClassifier._();

  static String determineRiskLevel(String conditionName) {
    final lower = conditionName.toLowerCase().trim();

    if (lower.contains('melanoma') ||
        lower.contains('carcinoma') ||
        lower.contains('malignant') ||
        lower.contains('actinic keratosis') ||
        lower.contains('systemic disease') ||
        lower.contains('vasculitis')) {
      return 'High';
    }

    if (lower.contains('cellulitis') ||
        lower.contains('impetigo') ||
        lower.contains('bacterial') ||
        lower.contains('bullous') ||
        lower.contains('lupus') ||
        lower.contains('connective tissue') ||
        lower.contains('drug eruption') ||
        lower.contains('exanthem') ||
        lower.contains('herpes') ||
        lower.contains('std') ||
        lower.contains('scabies') ||
        lower.contains('lyme') ||
        lower.contains('vascular tumor')) {
      return 'Medium';
    }

    return 'Low';
  }
}

class SkinPrediction {
  final String conditionName;
  final double rawScore;
  final double confidencePercentage;
  final String confidenceScore;
  final String riskLevel;
  final int rank;

  const SkinPrediction({
    required this.conditionName,
    required this.rawScore,
    required this.confidencePercentage,
    required this.confidenceScore,
    required this.riskLevel,
    this.rank = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'conditionName': conditionName,
      'rawScore': rawScore,
      'confidencePercentage': confidencePercentage,
      'confidenceScore': confidenceScore,
      'riskLevel': riskLevel,
      'rank': rank,
    };
  }

  factory SkinPrediction.fromJson(Map<String, dynamic> json) {
    return SkinPrediction(
      conditionName: json['conditionName'] as String? ?? 'Unknown',
      rawScore: (json['rawScore'] as num?)?.toDouble() ?? 0.0,
      confidencePercentage:
          (json['confidencePercentage'] as num?)?.toDouble() ?? 0.0,
      confidenceScore: json['confidenceScore'] as String? ?? '0.0%',
      riskLevel: json['riskLevel'] as String? ?? 'Low',
      rank: (json['rank'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  String toString() =>
      'SkinPrediction(rank: $rank, conditionName: $conditionName, confidenceScore: $confidenceScore, riskLevel: $riskLevel)';
}
