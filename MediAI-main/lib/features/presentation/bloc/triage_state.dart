import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/domain.dart';

part 'triage_state.freezed.dart';

@freezed
sealed class TriageState with _$TriageState {
  const factory TriageState.initial() = TriageInitial;

  const factory TriageState.verifyingSkin({required String imagePath}) =
      TriageVerifyingSkin;

  const factory TriageState.skinRejected({
    required String imagePath,
    required SkinVerificationResult verificationResult,
  }) = TriageSkinRejected;

  const factory TriageState.analyzingSkin({required String imagePath}) =
      TriageAnalyzingSkin;

  const factory TriageState.skinAnalyzed({
    required SkinAnalysisEntity skinAnalysis,
    SkinVerificationResult? verificationResult,
  }) = TriageSkinAnalyzed;

  const factory TriageState.generatingGenUi({
    required SkinAnalysisEntity skinAnalysis,
  }) = TriageGeneratingGenUi;

  const factory TriageState.success({required TriageSummaryEntity summary}) =
      TriageSuccess;

  const factory TriageState.failure({required String message}) = TriageFailure;
}
