import '../../../domain/domain.dart';

sealed class ClinicalSessionEvent {
  const ClinicalSessionEvent();
}

class AttachVitalsSnapshot extends ClinicalSessionEvent {
  final VitalsSnapshot vitals;
  const AttachVitalsSnapshot(this.vitals);
}

class AttachSkinScanResult extends ClinicalSessionEvent {
  final SkinScanResult skinResult;
  const AttachSkinScanResult(this.skinResult);
}

class SynthesizeUnifiedReport extends ClinicalSessionEvent {
  final String? symptoms;
  final String? medication;
  final TriageSummaryEntity? triageSummary;

  const SynthesizeUnifiedReport({
    this.symptoms,
    this.medication,
    this.triageSummary,
  });
}

class ResetClinicalSession extends ClinicalSessionEvent {
  const ResetClinicalSession();
}
