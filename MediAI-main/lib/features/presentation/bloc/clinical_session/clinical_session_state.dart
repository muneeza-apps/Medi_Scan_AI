import '../../../domain/domain.dart';

class ClinicalSessionState {
  final VitalsSnapshot? vitals;
  final SkinScanResult? skinResult;
  final UnifiedClinicalReport? report;
  final bool isVitalsAttached;
  final bool isSkinScanAttached;
  final SessionStatus status;
  final String? errorMessage;

  const ClinicalSessionState({
    this.vitals,
    this.skinResult,
    this.report,
    this.isVitalsAttached = false,
    this.isSkinScanAttached = false,
    this.status = SessionStatus.idle,
    this.errorMessage,
  });

  bool get isReadyForSynthesis =>
      isVitalsAttached && isSkinScanAttached && status == SessionStatus.readyForSynthesis;

  bool get isCompleted => status == SessionStatus.completed && report != null;

  ClinicalSessionState copyWith({
    VitalsSnapshot? vitals,
    SkinScanResult? skinResult,
    UnifiedClinicalReport? report,
    bool? isVitalsAttached,
    bool? isSkinScanAttached,
    SessionStatus? status,
    String? errorMessage,
    bool clearReport = false,
  }) {
    return ClinicalSessionState(
      vitals: vitals ?? this.vitals,
      skinResult: skinResult ?? this.skinResult,
      report: clearReport ? null : (report ?? this.report),
      isVitalsAttached: isVitalsAttached ?? this.isVitalsAttached,
      isSkinScanAttached: isSkinScanAttached ?? this.isSkinScanAttached,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalSessionState &&
          runtimeType == other.runtimeType &&
          vitals == other.vitals &&
          skinResult == other.skinResult &&
          report == other.report &&
          isVitalsAttached == other.isVitalsAttached &&
          isSkinScanAttached == other.isSkinScanAttached &&
          status == other.status &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        vitals,
        skinResult,
        report,
        isVitalsAttached,
        isSkinScanAttached,
        status,
        errorMessage,
      );
}
