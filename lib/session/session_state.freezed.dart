// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionState {

 bool get isActive; FocusSession? get currentSession; int get elapsedSeconds; int? get remainingSeconds;// null if "No End"
 SessionPhase get phase; SoundscapePreset get selectedPreset; int? get selectedDurationSeconds;// null if "No End"
 bool get pomodoroEnabled;
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateCopyWith<SessionState> get copyWith => _$SessionStateCopyWithImpl<SessionState>(this as SessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.currentSession, currentSession) || other.currentSession == currentSession)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedPreset, selectedPreset) || other.selectedPreset == selectedPreset)&&(identical(other.selectedDurationSeconds, selectedDurationSeconds) || other.selectedDurationSeconds == selectedDurationSeconds)&&(identical(other.pomodoroEnabled, pomodoroEnabled) || other.pomodoroEnabled == pomodoroEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,isActive,currentSession,elapsedSeconds,remainingSeconds,phase,selectedPreset,selectedDurationSeconds,pomodoroEnabled);

@override
String toString() {
  return 'SessionState(isActive: $isActive, currentSession: $currentSession, elapsedSeconds: $elapsedSeconds, remainingSeconds: $remainingSeconds, phase: $phase, selectedPreset: $selectedPreset, selectedDurationSeconds: $selectedDurationSeconds, pomodoroEnabled: $pomodoroEnabled)';
}


}

/// @nodoc
abstract mixin class $SessionStateCopyWith<$Res>  {
  factory $SessionStateCopyWith(SessionState value, $Res Function(SessionState) _then) = _$SessionStateCopyWithImpl;
@useResult
$Res call({
 bool isActive, FocusSession? currentSession, int elapsedSeconds, int? remainingSeconds, SessionPhase phase, SoundscapePreset selectedPreset, int? selectedDurationSeconds, bool pomodoroEnabled
});


$FocusSessionCopyWith<$Res>? get currentSession;$SoundscapePresetCopyWith<$Res> get selectedPreset;

}
/// @nodoc
class _$SessionStateCopyWithImpl<$Res>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._self, this._then);

  final SessionState _self;
  final $Res Function(SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActive = null,Object? currentSession = freezed,Object? elapsedSeconds = null,Object? remainingSeconds = freezed,Object? phase = null,Object? selectedPreset = null,Object? selectedDurationSeconds = freezed,Object? pomodoroEnabled = null,}) {
  return _then(_self.copyWith(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,currentSession: freezed == currentSession ? _self.currentSession : currentSession // ignore: cast_nullable_to_non_nullable
as FocusSession?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: freezed == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SessionPhase,selectedPreset: null == selectedPreset ? _self.selectedPreset : selectedPreset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,selectedDurationSeconds: freezed == selectedDurationSeconds ? _self.selectedDurationSeconds : selectedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,pomodoroEnabled: null == pomodoroEnabled ? _self.pomodoroEnabled : pomodoroEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FocusSessionCopyWith<$Res>? get currentSession {
    if (_self.currentSession == null) {
    return null;
  }

  return $FocusSessionCopyWith<$Res>(_self.currentSession!, (value) {
    return _then(_self.copyWith(currentSession: value));
  });
}/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SoundscapePresetCopyWith<$Res> get selectedPreset {
  
  return $SoundscapePresetCopyWith<$Res>(_self.selectedPreset, (value) {
    return _then(_self.copyWith(selectedPreset: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionState value)  $default,){
final _that = this;
switch (_that) {
case _SessionState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActive,  FocusSession? currentSession,  int elapsedSeconds,  int? remainingSeconds,  SessionPhase phase,  SoundscapePreset selectedPreset,  int? selectedDurationSeconds,  bool pomodoroEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.isActive,_that.currentSession,_that.elapsedSeconds,_that.remainingSeconds,_that.phase,_that.selectedPreset,_that.selectedDurationSeconds,_that.pomodoroEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActive,  FocusSession? currentSession,  int elapsedSeconds,  int? remainingSeconds,  SessionPhase phase,  SoundscapePreset selectedPreset,  int? selectedDurationSeconds,  bool pomodoroEnabled)  $default,) {final _that = this;
switch (_that) {
case _SessionState():
return $default(_that.isActive,_that.currentSession,_that.elapsedSeconds,_that.remainingSeconds,_that.phase,_that.selectedPreset,_that.selectedDurationSeconds,_that.pomodoroEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActive,  FocusSession? currentSession,  int elapsedSeconds,  int? remainingSeconds,  SessionPhase phase,  SoundscapePreset selectedPreset,  int? selectedDurationSeconds,  bool pomodoroEnabled)?  $default,) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.isActive,_that.currentSession,_that.elapsedSeconds,_that.remainingSeconds,_that.phase,_that.selectedPreset,_that.selectedDurationSeconds,_that.pomodoroEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _SessionState implements SessionState {
  const _SessionState({this.isActive = false, this.currentSession, this.elapsedSeconds = 0, this.remainingSeconds, this.phase = SessionPhase.settling, required this.selectedPreset, this.selectedDurationSeconds, this.pomodoroEnabled = false});
  

@override@JsonKey() final  bool isActive;
@override final  FocusSession? currentSession;
@override@JsonKey() final  int elapsedSeconds;
@override final  int? remainingSeconds;
// null if "No End"
@override@JsonKey() final  SessionPhase phase;
@override final  SoundscapePreset selectedPreset;
@override final  int? selectedDurationSeconds;
// null if "No End"
@override@JsonKey() final  bool pomodoroEnabled;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStateCopyWith<_SessionState> get copyWith => __$SessionStateCopyWithImpl<_SessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.currentSession, currentSession) || other.currentSession == currentSession)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedPreset, selectedPreset) || other.selectedPreset == selectedPreset)&&(identical(other.selectedDurationSeconds, selectedDurationSeconds) || other.selectedDurationSeconds == selectedDurationSeconds)&&(identical(other.pomodoroEnabled, pomodoroEnabled) || other.pomodoroEnabled == pomodoroEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,isActive,currentSession,elapsedSeconds,remainingSeconds,phase,selectedPreset,selectedDurationSeconds,pomodoroEnabled);

@override
String toString() {
  return 'SessionState(isActive: $isActive, currentSession: $currentSession, elapsedSeconds: $elapsedSeconds, remainingSeconds: $remainingSeconds, phase: $phase, selectedPreset: $selectedPreset, selectedDurationSeconds: $selectedDurationSeconds, pomodoroEnabled: $pomodoroEnabled)';
}


}

/// @nodoc
abstract mixin class _$SessionStateCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory _$SessionStateCopyWith(_SessionState value, $Res Function(_SessionState) _then) = __$SessionStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActive, FocusSession? currentSession, int elapsedSeconds, int? remainingSeconds, SessionPhase phase, SoundscapePreset selectedPreset, int? selectedDurationSeconds, bool pomodoroEnabled
});


@override $FocusSessionCopyWith<$Res>? get currentSession;@override $SoundscapePresetCopyWith<$Res> get selectedPreset;

}
/// @nodoc
class __$SessionStateCopyWithImpl<$Res>
    implements _$SessionStateCopyWith<$Res> {
  __$SessionStateCopyWithImpl(this._self, this._then);

  final _SessionState _self;
  final $Res Function(_SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActive = null,Object? currentSession = freezed,Object? elapsedSeconds = null,Object? remainingSeconds = freezed,Object? phase = null,Object? selectedPreset = null,Object? selectedDurationSeconds = freezed,Object? pomodoroEnabled = null,}) {
  return _then(_SessionState(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,currentSession: freezed == currentSession ? _self.currentSession : currentSession // ignore: cast_nullable_to_non_nullable
as FocusSession?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: freezed == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SessionPhase,selectedPreset: null == selectedPreset ? _self.selectedPreset : selectedPreset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,selectedDurationSeconds: freezed == selectedDurationSeconds ? _self.selectedDurationSeconds : selectedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,pomodoroEnabled: null == pomodoroEnabled ? _self.pomodoroEnabled : pomodoroEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FocusSessionCopyWith<$Res>? get currentSession {
    if (_self.currentSession == null) {
    return null;
  }

  return $FocusSessionCopyWith<$Res>(_self.currentSession!, (value) {
    return _then(_self.copyWith(currentSession: value));
  });
}/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SoundscapePresetCopyWith<$Res> get selectedPreset {
  
  return $SoundscapePresetCopyWith<$Res>(_self.selectedPreset, (value) {
    return _then(_self.copyWith(selectedPreset: value));
  });
}
}

// dart format on
