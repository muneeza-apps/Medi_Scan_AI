class SkinVerificationResult {
  final bool isValidSkin;
  final bool isLesionPresent;
  final double confidence;
  final String detectedObject;
  final String? rejectionReasonEn;
  final String? rejectionReasonUr;
  final String? visualDescription;

  const SkinVerificationResult({
    required this.isValidSkin,
    this.isLesionPresent = false,
    this.confidence = 1.0,
    this.detectedObject = 'Human Skin',
    this.rejectionReasonEn,
    this.rejectionReasonUr,
    this.visualDescription,
  });

  factory SkinVerificationResult.validSkin({
    bool isLesionPresent = true,
    double confidence = 0.95,
    String detectedObject = 'Human Skin Lesion',
    String? visualDescription,
  }) {
    return SkinVerificationResult(
      isValidSkin: true,
      isLesionPresent: isLesionPresent,
      confidence: confidence,
      detectedObject: detectedObject,
      visualDescription: visualDescription,
    );
  }

  factory SkinVerificationResult.rejected({
    required String detectedObject,
    required String rejectionReasonEn,
    required String rejectionReasonUr,
    double confidence = 0.95,
    String? visualDescription,
  }) {
    return SkinVerificationResult(
      isValidSkin: false,
      isLesionPresent: false,
      confidence: confidence,
      detectedObject: detectedObject,
      rejectionReasonEn: rejectionReasonEn,
      rejectionReasonUr: rejectionReasonUr,
      visualDescription: visualDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValidSkin': isValidSkin,
      'isLesionPresent': isLesionPresent,
      'confidence': confidence,
      'detectedObject': detectedObject,
      if (rejectionReasonEn != null) 'rejectionReasonEn': rejectionReasonEn,
      if (rejectionReasonUr != null) 'rejectionReasonUr': rejectionReasonUr,
      if (visualDescription != null) 'visualDescription': visualDescription,
    };
  }

  factory SkinVerificationResult.fromJson(Map<String, dynamic> json) {
    return SkinVerificationResult(
      isValidSkin: json['isValidSkin'] as bool? ?? false,
      isLesionPresent: json['isLesionPresent'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      detectedObject: json['detectedObject'] as String? ?? 'Unknown object',
      rejectionReasonEn: json['rejectionReasonEn'] as String?,
      rejectionReasonUr: json['rejectionReasonUr'] as String?,
      visualDescription: json['visualDescription'] as String?,
    );
  }
}
