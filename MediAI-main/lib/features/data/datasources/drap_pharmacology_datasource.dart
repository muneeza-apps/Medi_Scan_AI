import '../../../core/services/drap_pharmacology_service.dart';

class DrapPharmacologyDatasource {
  final DrapPharmacologyService _service;

  DrapPharmacologyDatasource({DrapPharmacologyService? service})
      : _service = service ?? DrapPharmacologyService.instance;

  Future<String?> fetchDrugSafetyInfo(String medicationName) async {
    final clean = medicationName.trim();
    if (clean.isEmpty) return null;
    return _service.formatDrugSafetyGuidance(clean);
  }

  String? fetchDrugSafetyUrdu(String medicationName) {
    final clean = medicationName.trim();
    if (clean.isEmpty) return null;
    return _service.generateUrduDrugGuidance(clean);
  }

  ({String en, String ur}) getRecommendedTopicalsForCondition(String conditionName) {
    return _service.getRecommendedTopicalsForCondition(conditionName);
  }

  DrapMedicationItem? findMedication(String name) => _service.findMedicationByName(name);
}
