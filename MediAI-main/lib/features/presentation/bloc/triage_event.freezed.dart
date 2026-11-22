// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'triage_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TriageEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TriageEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TriageEvent()';
}


}

/// @nodoc
class $TriageEventCopyWith<$Res>  {
$TriageEventCopyWith(TriageEvent _, $Res Function(TriageEvent) __);
}


/// Adds pattern-matching-related methods to [TriageEvent].
extension TriageEventPatterns on TriageEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PickAndAnalyzeImage value)?  pickAndAnalyzeImage,TResult Function( SubmitFullTriage value)?  submitFullTriage,TResult Function( ResetTriage value)?  resetTriage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PickAndAnalyzeImage() when pickAndAnalyzeImage != null:
return pickAndAnalyzeImage(_that);case SubmitFullTriage() when submitFullTriage != null:
return submitFullTriage(_that);case ResetTriage() when resetTriage != null:
return resetTriage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PickAndAnalyzeImage value)  pickAndAnalyzeImage,required TResult Function( SubmitFullTriage value)  submitFullTriage,required TResult Function( ResetTriage value)  resetTriage,}){
final _that = this;
switch (_that) {
case PickAndAnalyzeImage():
return pickAndAnalyzeImage(_that);case SubmitFullTriage():
return submitFullTriage(_that);case ResetTriage():
return resetTriage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PickAndAnalyzeImage value)?  pickAndAnalyzeImage,TResult? Function( SubmitFullTriage value)?  submitFullTriage,TResult? Function( ResetTriage value)?  resetTriage,}){
final _that = this;
switch (_that) {
case PickAndAnalyzeImage() when pickAndAnalyzeImage != null:
return pickAndAnalyzeImage(_that);case SubmitFullTriage() when submitFullTriage != null:
return submitFullTriage(_that);case ResetTriage() when resetTriage != null:
return resetTriage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String imagePath,  String? anatomicalLocation,  String? lesionTag)?  pickAndAnalyzeImage,TResult Function( String symptoms,  String? medication,  String? anatomicalLocation,  String? lesionTag)?  submitFullTriage,TResult Function()?  resetTriage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PickAndAnalyzeImage() when pickAndAnalyzeImage != null:
return pickAndAnalyzeImage(_that.imagePath,_that.anatomicalLocation,_that.lesionTag);case SubmitFullTriage() when submitFullTriage != null:
return submitFullTriage(_that.symptoms,_that.medication,_that.anatomicalLocation,_that.lesionTag);case ResetTriage() when resetTriage != null:
return resetTriage();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String imagePath,  String? anatomicalLocation,  String? lesionTag)  pickAndAnalyzeImage,required TResult Function( String symptoms,  String? medication,  String? anatomicalLocation,  String? lesionTag)  submitFullTriage,required TResult Function()  resetTriage,}) {final _that = this;
switch (_that) {
case PickAndAnalyzeImage():
return pickAndAnalyzeImage(_that.imagePath,_that.anatomicalLocation,_that.lesionTag);case SubmitFullTriage():
return submitFullTriage(_that.symptoms,_that.medication,_that.anatomicalLocation,_that.lesionTag);case ResetTriage():
return resetTriage();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String imagePath,  String? anatomicalLocation,  String? lesionTag)?  pickAndAnalyzeImage,TResult? Function( String symptoms,  String? medication,  String? anatomicalLocation,  String? lesionTag)?  submitFullTriage,TResult? Function()?  resetTriage,}) {final _that = this;
switch (_that) {
case PickAndAnalyzeImage() when pickAndAnalyzeImage != null:
return pickAndAnalyzeImage(_that.imagePath,_that.anatomicalLocation,_that.lesionTag);case SubmitFullTriage() when submitFullTriage != null:
return submitFullTriage(_that.symptoms,_that.medication,_that.anatomicalLocation,_that.lesionTag);case ResetTriage() when resetTriage != null:
return resetTriage();case _:
  return null;

}
}

}

/// @nodoc


class PickAndAnalyzeImage implements TriageEvent {
  const PickAndAnalyzeImage({required this.imagePath, this.anatomicalLocation, this.lesionTag});
  

 final  String imagePath;
 final  String? anatomicalLocation;
 final  String? lesionTag;

/// Create a copy of TriageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PickAndAnalyzeImageCopyWith<PickAndAnalyzeImage> get copyWith => _$PickAndAnalyzeImageCopyWithImpl<PickAndAnalyzeImage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PickAndAnalyzeImage&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.anatomicalLocation, anatomicalLocation) || other.anatomicalLocation == anatomicalLocation)&&(identical(other.lesionTag, lesionTag) || other.lesionTag == lesionTag));
}


@override
int get hashCode {
    return Object.hash(runtimeType,imagePath,anatomicalLocation,lesionTag);
}

@override
String toString() {
    return 'TriageEvent.pickAndAnalyzeImage(imagePath: $imagePath, anatomicalLocation: $anatomicalLocation, lesionTag: $lesionTag)';
}


}

/// @nodoc
abstract mixin class $PickAndAnalyzeImageCopyWith<$Res> implements $TriageEventCopyWith<$Res> {
  factory $PickAndAnalyzeImageCopyWith(PickAndAnalyzeImage value, $Res Function(PickAndAnalyzeImage) _then) = _$PickAndAnalyzeImageCopyWithImpl;
@useResult
$Res call({
 String imagePath, String? anatomicalLocation, String? lesionTag
});




}
/// @nodoc
class _$PickAndAnalyzeImageCopyWithImpl<$Res>
    implements $PickAndAnalyzeImageCopyWith<$Res> {
  _$PickAndAnalyzeImageCopyWithImpl(this._self, this._then);

  final PickAndAnalyzeImage _self;
  final $Res Function(PickAndAnalyzeImage) _then;

/// Create a copy of TriageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? imagePath = null,Object? anatomicalLocation = freezed,Object? lesionTag = freezed,}) {
  return _then(PickAndAnalyzeImage(
imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,anatomicalLocation: freezed == anatomicalLocation ? _self.anatomicalLocation : anatomicalLocation // ignore: cast_nullable_to_non_nullable
as String?,lesionTag: freezed == lesionTag ? _self.lesionTag : lesionTag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SubmitFullTriage implements TriageEvent {
  const SubmitFullTriage({required this.symptoms, this.medication, this.anatomicalLocation, this.lesionTag});
  

 final  String symptoms;
 final  String? medication;
 final  String? anatomicalLocation;
 final  String? lesionTag;

/// Create a copy of TriageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmitFullTriageCopyWith<SubmitFullTriage> get copyWith => _$SubmitFullTriageCopyWithImpl<SubmitFullTriage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitFullTriage&&(identical(other.symptoms, symptoms) || other.symptoms == symptoms)&&(identical(other.medication, medication) || other.medication == medication)&&(identical(other.anatomicalLocation, anatomicalLocation) || other.anatomicalLocation == anatomicalLocation)&&(identical(other.lesionTag, lesionTag) || other.lesionTag == lesionTag));
}


@override
int get hashCode {
    return Object.hash(runtimeType,symptoms,medication,anatomicalLocation,lesionTag);
}

@override
String toString() {
    return 'TriageEvent.submitFullTriage(symptoms: $symptoms, medication: $medication, anatomicalLocation: $anatomicalLocation, lesionTag: $lesionTag)';
}


}

/// @nodoc
abstract mixin class $SubmitFullTriageCopyWith<$Res> implements $TriageEventCopyWith<$Res> {
  factory $SubmitFullTriageCopyWith(SubmitFullTriage value, $Res Function(SubmitFullTriage) _then) = _$SubmitFullTriageCopyWithImpl;
@useResult
$Res call({
 String symptoms, String? medication, String? anatomicalLocation, String? lesionTag
});




}
/// @nodoc
class _$SubmitFullTriageCopyWithImpl<$Res>
    implements $SubmitFullTriageCopyWith<$Res> {
  _$SubmitFullTriageCopyWithImpl(this._self, this._then);

  final SubmitFullTriage _self;
  final $Res Function(SubmitFullTriage) _then;

/// Create a copy of TriageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? symptoms = null,Object? medication = freezed,Object? anatomicalLocation = freezed,Object? lesionTag = freezed,}) {
  return _then(SubmitFullTriage(
symptoms: null == symptoms ? _self.symptoms : symptoms // ignore: cast_nullable_to_non_nullable
as String,medication: freezed == medication ? _self.medication : medication // ignore: cast_nullable_to_non_nullable
as String?,anatomicalLocation: freezed == anatomicalLocation ? _self.anatomicalLocation : anatomicalLocation // ignore: cast_nullable_to_non_nullable
as String?,lesionTag: freezed == lesionTag ? _self.lesionTag : lesionTag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ResetTriage implements TriageEvent {
  const ResetTriage();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetTriage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TriageEvent.resetTriage()';
}


}




// dart format on
