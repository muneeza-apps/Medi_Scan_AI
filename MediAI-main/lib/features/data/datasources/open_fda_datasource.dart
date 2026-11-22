import '../../../../core/services/drap_pharmacology_service.dart';

class OpenFdaDatasource {
  final DrapPharmacologyService _drapService;

  OpenFdaDatasource({DrapPharmacologyService? drapService})
      : _drapService = drapService ?? DrapPharmacologyService.instance;

  static String sanitizeMedicationName(String raw) {
    var cleaned = raw.trim();
    final noisePatterns = [
      RegExp(
        r'\b(cream|ointments?|gels?|lotions?|foams?|solutions?|topical|sprays?|patch(es)?|capsules?|tablets?|pills?|syrups?|drops?)\b',
        caseSensitive: false,
      ),
      RegExp(r'\d+(\.\d+)?\s*(mg|mcg|g|ml|%)', caseSensitive: false),
      RegExp(r'\b\d+\b'),
    ];
    for (final pattern in noisePatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }
    cleaned = cleaned
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isNotEmpty ? cleaned : raw.trim();
  }

  Future<String?> fetchDrugSafetyInfo(String medicationName) async {
    final cleanName = medicationName.trim();
    if (cleanName.isEmpty) return null;

    final sanitized = sanitizeMedicationName(cleanName);
    return _drapService.formatDrugSafetyGuidance(sanitized);
  }
}
