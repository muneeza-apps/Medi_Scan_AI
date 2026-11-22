// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'triage_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TriageState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TriageState()';
}


}

/// @nodoc
class $TriageStateCopyWith<$Res>  {
$TriageStateCopyWith(TriageState _, $Res Function(TriageState) __);
}


/// Adds pattern-matching-related methods to [TriageState].
extension TriageStatePatterns on TriageState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TriageInitial value)?  initial,TResult Function( TriageVerifyingSkin value)?  verifyingSkin,TResult Function( TriageSkinRejected value)?  skinRejected,TResult Function( TriageAnalyzingSkin value)?  analyzingSkin,TResult Function( TriageSkinAnalyzed value)?  skinAnalyzed,TResult Function( TriageGeneratingGenUi value)?  generatingGenUi,TResult Function( TriageSuccess value)?  success,TResult Function( TriageFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TriageInitial() when initial != null:
return initial(_that);case TriageVerifyingSkin() when verifyingSkin != null:
return verifyingSkin(_that);case TriageSkinRejected() when skinRejected != null:
return skinRejected(_that);case TriageAnalyzingSkin() when analyzingSkin != null:
return analyzingSkin(_that);case TriageSkinAnalyzed() when skinAnalyzed != null:
return skinAnalyzed(_that);case TriageGeneratingGenUi() when generatingGenUi != null:
return generatingGenUi(_that);case TriageSuccess() when success != null:
return success(_that);case TriageFailure() when failure != null:
return failure(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TriageInitial value)  initial,required TResult Function( TriageVerifyingSkin value)  verifyingSkin,required TResult Function( TriageSkinRejected value)  skinRejected,required TResult Function( TriageAnalyzingSkin value)  analyzingSkin,required TResult Function( TriageSkinAnalyzed value)  skinAnalyzed,required TResult Function( TriageGeneratingGenUi value)  generatingGenUi,required TResult Function( TriageSuccess value)  success,required TResult Function( TriageFailure value)  failure,}){
final _that = this;
switch (_that) {
case TriageInitial():
return initial(_that);case TriageVerifyingSkin():
return verifyingSkin(_that);case TriageSkinRejected():
return skinRejected(_that);case TriageAnalyzingSkin():
return analyzingSkin(_that);case TriageSkinAnalyzed():
return skinAnalyzed(_that);case TriageGeneratingGenUi():
return generatingGenUi(_that);case TriageSuccess():
return success(_that);case TriageFailure():
return failure(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TriageInitial value)?  initial,TResult? Function( TriageVerifyingSkin value)?  verifyingSkin,TResult? Function( TriageSkinRejected value)?  skinRejected,TResult? Function( TriageAnalyzingSkin value)?  analyzingSkin,TResult? Function( TriageSkinAnalyzed value)?  skinAnalyzed,TResult? Function( TriageGeneratingGenUi value)?  generatingGenUi,TResult? Function( TriageSuccess value)?  success,TResult? Function( TriageFailure value)?  failure,}){
final _that = this;
switch (_that) {
case TriageInitial() when initial != null:
return initial(_that);case TriageVerifyingSkin() when verifyingSkin != null:
return verifyingSkin(_that);case TriageSkinRejected() when skinRejected != null:
return skinRejected(_that);case TriageAnalyzingSkin() when analyzingSkin != null:
return analyzingSkin(_that);case TriageSkinAnalyzed() when skinAnalyzed != null:
return skinAnalyzed(_that);case TriageGeneratingGenUi() when generatingGenUi != null:
return generatingGenUi(_that);case TriageSuccess() when success != null:
return success(_that);case TriageFailure() when failure != null:
return failure(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String imagePath)?  verifyingSkin,TResult Function( String imagePath,  SkinVerificationResult verificationResult)?  skinRejected,TResult Function( String imagePath)?  analyzingSkin,TResult Function( SkinAnalysisEntity skinAnalysis,  SkinVerificationResult? verificationResult)?  skinAnalyzed,TResult Function( SkinAnalysisEntity skinAnalysis)?  generatingGenUi,TResult Function( TriageSummaryEntity summary)?  success,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TriageInitial() when initial != null:
return initial();case TriageVerifyingSkin() when verifyingSkin != null:
return verifyingSkin(_that.imagePath);case TriageSkinRejected() when skinRejected != null:
return skinRejected(_that.imagePath,_that.verificationResult);case TriageAnalyzingSkin() when analyzingSkin != null:
return analyzingSkin(_that.imagePath);case TriageSkinAnalyzed() when skinAnalyzed != null:
return skinAnalyzed(_that.skinAnalysis,_that.verificationResult);case TriageGeneratingGenUi() when generatingGenUi != null:
return generatingGenUi(_that.skinAnalysis);case TriageSuccess() when success != null:
return success(_that.summary);case TriageFailure() when failure != null:
return failure(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String imagePath)  verifyingSkin,required TResult Function( String imagePath,  SkinVerificationResult verificationResult)  skinRejected,required TResult Function( String imagePath)  analyzingSkin,required TResult Function( SkinAnalysisEntity skinAnalysis,  SkinVerificationResult? verificationResult)  skinAnalyzed,required TResult Function( SkinAnalysisEntity skinAnalysis)  generatingGenUi,required TResult Function( TriageSummaryEntity summary)  success,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case TriageInitial():
return initial();case TriageVerifyingSkin():
return verifyingSkin(_that.imagePath);case TriageSkinRejected():
return skinRejected(_that.imagePath,_that.verificationResult);case TriageAnalyzingSkin():
return analyzingSkin(_that.imagePath);case TriageSkinAnalyzed():
return skinAnalyzed(_that.skinAnalysis,_that.verificationResult);case TriageGeneratingGenUi():
return generatingGenUi(_that.skinAnalysis);case TriageSuccess():
return success(_that.summary);case TriageFailure():
return failure(_that.message);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String imagePath)?  verifyingSkin,TResult? Function( String imagePath,  SkinVerificationResult verificationResult)?  skinRejected,TResult? Function( String imagePath)?  analyzingSkin,TResult? Function( SkinAnalysisEntity skinAnalysis,  SkinVerificationResult? verificationResult)?  skinAnalyzed,TResult? Function( SkinAnalysisEntity skinAnalysis)?  generatingGenUi,TResult? Function( TriageSummaryEntity summary)?  success,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case TriageInitial() when initial != null:
return initial();case TriageVerifyingSkin() when verifyingSkin != null:
return verifyingSkin(_that.imagePath);case TriageSkinRejected() when skinRejected != null:
return skinRejected(_that.imagePath,_that.verificationResult);case TriageAnalyzingSkin() when analyzingSkin != null:
return analyzingSkin(_that.imagePath);case TriageSkinAnalyzed() when skinAnalyzed != null:
return skinAnalyzed(_that.skinAnalysis,_that.verificationResult);case TriageGeneratingGenUi() when generatingGenUi != null:
return generatingGenUi(_that.skinAnalysis);case TriageSuccess() when success != null:
return success(_that.summary);case TriageFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class TriageInitial implements TriageState {
  const TriageInitial();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TriageState.initial()';
}


}




/// @nodoc


class TriageVerifyingSkin implements TriageState {
  const TriageVerifyingSkin({required this.imagePath});
  

 final  String imagePath;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageVerifyingSkinCopyWith<TriageVerifyingSkin> get copyWith => _$TriageVerifyingSkinCopyWithImpl<TriageVerifyingSkin>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageVerifyingSkin&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,imagePath);
}

@override
String toString() {
    return 'TriageState.verifyingSkin(imagePath: $imagePath)';
}


}

/// @nodoc
abstract mixin class $TriageVerifyingSkinCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageVerifyingSkinCopyWith(TriageVerifyingSkin value, $Res Function(TriageVerifyingSkin) _then) = _$TriageVerifyingSkinCopyWithImpl;
@useResult
$Res call({
 String imagePath
});




}
/// @nodoc
class _$TriageVerifyingSkinCopyWithImpl<$Res>
    implements $TriageVerifyingSkinCopyWith<$Res> {
  _$TriageVerifyingSkinCopyWithImpl(this._self, this._then);

  final TriageVerifyingSkin _self;
  final $Res Function(TriageVerifyingSkin) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? imagePath = null,}) {
  return _then(TriageVerifyingSkin(
imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TriageSkinRejected implements TriageState {
  const TriageSkinRejected({required this.imagePath, required this.verificationResult});
  

 final  String imagePath;
 final  SkinVerificationResult verificationResult;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageSkinRejectedCopyWith<TriageSkinRejected> get copyWith => _$TriageSkinRejectedCopyWithImpl<TriageSkinRejected>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageSkinRejected&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.verificationResult, verificationResult) || other.verificationResult == verificationResult));
}


@override
int get hashCode {
    return Object.hash(runtimeType,imagePath,verificationResult);
}

@override
String toString() {
    return 'TriageState.skinRejected(imagePath: $imagePath, verificationResult: $verificationResult)';
}


}

/// @nodoc
abstract mixin class $TriageSkinRejectedCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageSkinRejectedCopyWith(TriageSkinRejected value, $Res Function(TriageSkinRejected) _then) = _$TriageSkinRejectedCopyWithImpl;
@useResult
$Res call({
 String imagePath, SkinVerificationResult verificationResult
});




}
/// @nodoc
class _$TriageSkinRejectedCopyWithImpl<$Res>
    implements $TriageSkinRejectedCopyWith<$Res> {
  _$TriageSkinRejectedCopyWithImpl(this._self, this._then);

  final TriageSkinRejected _self;
  final $Res Function(TriageSkinRejected) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? imagePath = null,Object? verificationResult = null,}) {
  return _then(TriageSkinRejected(
imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,verificationResult: null == verificationResult ? _self.verificationResult : verificationResult // ignore: cast_nullable_to_non_nullable
as SkinVerificationResult,
  ));
}


}

/// @nodoc


class TriageAnalyzingSkin implements TriageState {
  const TriageAnalyzingSkin({required this.imagePath});
  

 final  String imagePath;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageAnalyzingSkinCopyWith<TriageAnalyzingSkin> get copyWith => _$TriageAnalyzingSkinCopyWithImpl<TriageAnalyzingSkin>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageAnalyzingSkin&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,imagePath);
}

@override
String toString() {
    return 'TriageState.analyzingSkin(imagePath: $imagePath)';
}


}

/// @nodoc
abstract mixin class $TriageAnalyzingSkinCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageAnalyzingSkinCopyWith(TriageAnalyzingSkin value, $Res Function(TriageAnalyzingSkin) _then) = _$TriageAnalyzingSkinCopyWithImpl;
@useResult
$Res call({
 String imagePath
});




}
/// @nodoc
class _$TriageAnalyzingSkinCopyWithImpl<$Res>
    implements $TriageAnalyzingSkinCopyWith<$Res> {
  _$TriageAnalyzingSkinCopyWithImpl(this._self, this._then);

  final TriageAnalyzingSkin _self;
  final $Res Function(TriageAnalyzingSkin) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? imagePath = null,}) {
  return _then(TriageAnalyzingSkin(
imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TriageSkinAnalyzed implements TriageState {
  const TriageSkinAnalyzed({required this.skinAnalysis, this.verificationResult});
  

 final  SkinAnalysisEntity skinAnalysis;
 final  SkinVerificationResult? verificationResult;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageSkinAnalyzedCopyWith<TriageSkinAnalyzed> get copyWith => _$TriageSkinAnalyzedCopyWithImpl<TriageSkinAnalyzed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageSkinAnalyzed&&(identical(other.skinAnalysis, skinAnalysis) || other.skinAnalysis == skinAnalysis)&&(identical(other.verificationResult, verificationResult) || other.verificationResult == verificationResult));
}


@override
int get hashCode {
    return Object.hash(runtimeType,skinAnalysis,verificationResult);
}

@override
String toString() {
    return 'TriageState.skinAnalyzed(skinAnalysis: $skinAnalysis, verificationResult: $verificationResult)';
}


}

/// @nodoc
abstract mixin class $TriageSkinAnalyzedCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageSkinAnalyzedCopyWith(TriageSkinAnalyzed value, $Res Function(TriageSkinAnalyzed) _then) = _$TriageSkinAnalyzedCopyWithImpl;
@useResult
$Res call({
 SkinAnalysisEntity skinAnalysis, SkinVerificationResult? verificationResult
});




}
/// @nodoc
class _$TriageSkinAnalyzedCopyWithImpl<$Res>
    implements $TriageSkinAnalyzedCopyWith<$Res> {
  _$TriageSkinAnalyzedCopyWithImpl(this._self, this._then);

  final TriageSkinAnalyzed _self;
  final $Res Function(TriageSkinAnalyzed) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? skinAnalysis = null,Object? verificationResult = freezed,}) {
  return _then(TriageSkinAnalyzed(
skinAnalysis: null == skinAnalysis ? _self.skinAnalysis : skinAnalysis // ignore: cast_nullable_to_non_nullable
as SkinAnalysisEntity,verificationResult: freezed == verificationResult ? _self.verificationResult : verificationResult // ignore: cast_nullable_to_non_nullable
as SkinVerificationResult?,
  ));
}


}

/// @nodoc


class TriageGeneratingGenUi implements TriageState {
  const TriageGeneratingGenUi({required this.skinAnalysis});
  

 final  SkinAnalysisEntity skinAnalysis;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageGeneratingGenUiCopyWith<TriageGeneratingGenUi> get copyWith => _$TriageGeneratingGenUiCopyWithImpl<TriageGeneratingGenUi>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageGeneratingGenUi&&(identical(other.skinAnalysis, skinAnalysis) || other.skinAnalysis == skinAnalysis));
}


@override
int get hashCode {
    return Object.hash(runtimeType,skinAnalysis);
}

@override
String toString() {
    return 'TriageState.generatingGenUi(skinAnalysis: $skinAnalysis)';
}


}

/// @nodoc
abstract mixin class $TriageGeneratingGenUiCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageGeneratingGenUiCopyWith(TriageGeneratingGenUi value, $Res Function(TriageGeneratingGenUi) _then) = _$TriageGeneratingGenUiCopyWithImpl;
@useResult
$Res call({
 SkinAnalysisEntity skinAnalysis
});




}
/// @nodoc
class _$TriageGeneratingGenUiCopyWithImpl<$Res>
    implements $TriageGeneratingGenUiCopyWith<$Res> {
  _$TriageGeneratingGenUiCopyWithImpl(this._self, this._then);

  final TriageGeneratingGenUi _self;
  final $Res Function(TriageGeneratingGenUi) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? skinAnalysis = null,}) {
  return _then(TriageGeneratingGenUi(
skinAnalysis: null == skinAnalysis ? _self.skinAnalysis : skinAnalysis // ignore: cast_nullable_to_non_nullable
as SkinAnalysisEntity,
  ));
}


}

/// @nodoc


class TriageSuccess implements TriageState {
  const TriageSuccess({required this.summary});
  

 final  TriageSummaryEntity summary;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageSuccessCopyWith<TriageSuccess> get copyWith => _$TriageSuccessCopyWithImpl<TriageSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageSuccess&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode {
    return Object.hash(runtimeType,summary);
}

@override
String toString() {
    return 'TriageState.success(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $TriageSuccessCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageSuccessCopyWith(TriageSuccess value, $Res Function(TriageSuccess) _then) = _$TriageSuccessCopyWithImpl;
@useResult
$Res call({
 TriageSummaryEntity summary
});




}
/// @nodoc
class _$TriageSuccessCopyWithImpl<$Res>
    implements $TriageSuccessCopyWith<$Res> {
  _$TriageSuccessCopyWithImpl(this._self, this._then);

  final TriageSuccess _self;
  final $Res Function(TriageSuccess) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(TriageSuccess(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TriageSummaryEntity,
  ));
}


}

/// @nodoc


class TriageFailure implements TriageState {
  const TriageFailure({required this.message});
  

 final  String message;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TriageFailureCopyWith<TriageFailure> get copyWith => _$TriageFailureCopyWithImpl<TriageFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'TriageState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $TriageFailureCopyWith<$Res> implements $TriageStateCopyWith<$Res> {
  factory $TriageFailureCopyWith(TriageFailure value, $Res Function(TriageFailure) _then) = _$TriageFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$TriageFailureCopyWithImpl<$Res>
    implements $TriageFailureCopyWith<$Res> {
  _$TriageFailureCopyWithImpl(this._self, this._then);

  final TriageFailure _self;
  final $Res Function(TriageFailure) _then;

/// Create a copy of TriageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(TriageFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
