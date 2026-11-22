import 'package:freezed_annotation/freezed_annotation.dart';

part 'triage_event.freezed.dart';

@freezed
sealed class TriageEvent with _$TriageEvent {
  const factory TriageEvent.pickAndAnalyzeImage({
    required String imagePath,
    String? anatomicalLocation,
    String? lesionTag,
  }) = PickAndAnalyzeImage;

  const factory TriageEvent.submitFullTriage({
    required String symptoms,
    String? medication,
    String? anatomicalLocation,
    String? lesionTag,
  }) = SubmitFullTriage;

  const factory TriageEvent.resetTriage() = ResetTriage;
}
