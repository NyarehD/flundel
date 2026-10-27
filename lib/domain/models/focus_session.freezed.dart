// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FocusSession {


/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusSessionCopyWith<FocusSession> get copyWith => _$FocusSessionCopyWithImpl<FocusSession>(this as FocusSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FocusSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.durationSeconds, _this.durationSeconds) || other.durationSeconds == _this.durationSeconds)&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&(identical(other.sessionSeed, _this.sessionSeed) || other.sessionSeed == _this.sessionSeed)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isPomodoro, _this.isPomodoro) || other.isPomodoro == _this.isPomodoro)&&(identical(other.pausedAt, _this.pausedAt) || other.pausedAt == _this.pausedAt)&&(identical(other.totalPausedSeconds, _this.totalPausedSeconds) || other.totalPausedSeconds == _this.totalPausedSeconds)&&(identical(other.completionCueEnabled, _this.completionCueEnabled) || other.completionCueEnabled == _this.completionCueEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FocusSession;
  return Object.hash(runtimeType,_this.id,_this.startedAt,_this.durationSeconds,_this.preset,_this.sessionSeed,_this.status,_this.isPomodoro,_this.pausedAt,_this.totalPausedSeconds,_this.completionCueEnabled);
}

@override
String toString() {
  final _this = this as FocusSession;
  return 'FocusSession(id: ${_this.id}, startedAt: ${_this.startedAt}, durationSeconds: ${_this.durationSeconds}, preset: ${_this.preset}, sessionSeed: ${_this.sessionSeed}, status: ${_this.status}, isPomodoro: ${_this.isPomodoro}, pausedAt: ${_this.pausedAt}, totalPausedSeconds: ${_this.totalPausedSeconds}, completionCueEnabled: ${_this.completionCueEnabled})';
}


}

/// @nodoc
abstract mixin class $FocusSessionCopyWith<$Res>  {
  factory $FocusSessionCopyWith(FocusSession value, $Res Function(FocusSession) _then) = _$FocusSessionCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) DateTime startedAt,@HiveField(2) int? durationSeconds,@HiveField(3) SoundscapePreset preset,@HiveField(4) int sessionSeed,@HiveField(5) SessionStatus status,@HiveField(6) bool isPomodoro,@HiveField(7) DateTime? pausedAt,@HiveField(8) int totalPausedSeconds,@HiveField(9) bool completionCueEnabled
});


$SoundscapePresetCopyWith<$Res> get preset;

}
/// @nodoc
class _$FocusSessionCopyWithImpl<$Res>
    implements $FocusSessionCopyWith<$Res> {
  _$FocusSessionCopyWithImpl(this._self, this._then);

  final FocusSession _self;
  final $Res Function(FocusSession) _then;

/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? durationSeconds = freezed,Object? preset = null,Object? sessionSeed = null,Object? status = null,Object? isPomodoro = null,Object? pausedAt = freezed,Object? totalPausedSeconds = null,Object? completionCueEnabled = null,}) {
  return _then(FocusSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,sessionSeed: null == sessionSeed ? _self.sessionSeed : sessionSeed // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,isPomodoro: null == isPomodoro ? _self.isPomodoro : isPomodoro // ignore: cast_nullable_to_non_nullable
as bool,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totalPausedSeconds: null == totalPausedSeconds ? _self.totalPausedSeconds : totalPausedSeconds // ignore: cast_nullable_to_non_nullable
as int,completionCueEnabled: null == completionCueEnabled ? _self.completionCueEnabled : completionCueEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SoundscapePresetCopyWith<$Res> get preset {
  
  return $SoundscapePresetCopyWith<$Res>(_self.preset, (value) {
    return _then(_self.copyWith(preset: value));
  });
}
}


/// Adds pattern-matching-related methods to [FocusSession].
extension FocusSessionPatterns on FocusSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
