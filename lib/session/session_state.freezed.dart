// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionState {

 bool get isActive; bool get isPaused; bool get isLoading; FocusSession? get currentSession; int get elapsedSeconds; int? get remainingSeconds; SessionPhase get phase; SoundscapePreset get selectedPreset; int? get selectedDurationSeconds; bool get pomodoroEnabled; bool get completionCueEnabled;
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateCopyWith<SessionState> get copyWith => _$SessionStateCopyWithImpl<SessionState>(this as SessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.isPaused, _this.isPaused) || other.isPaused == _this.isPaused)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.currentSession, _this.currentSession) || other.currentSession == _this.currentSession)&&(identical(other.elapsedSeconds, _this.elapsedSeconds) || other.elapsedSeconds == _this.elapsedSeconds)&&(identical(other.remainingSeconds, _this.remainingSeconds) || other.remainingSeconds == _this.remainingSeconds)&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.selectedPreset, _this.selectedPreset) || other.selectedPreset == _this.selectedPreset)&&(identical(other.selectedDurationSeconds, _this.selectedDurationSeconds) || other.selectedDurationSeconds == _this.selectedDurationSeconds)&&(identical(other.pomodoroEnabled, _this.pomodoroEnabled) || other.pomodoroEnabled == _this.pomodoroEnabled)&&(identical(other.completionCueEnabled, _this.completionCueEnabled) || other.completionCueEnabled == _this.completionCueEnabled));
}


@override
int get hashCode {
  final _this = this as SessionState;
  return Object.hash(runtimeType,_this.isActive,_this.isPaused,_this.isLoading,_this.currentSession,_this.elapsedSeconds,_this.remainingSeconds,_this.phase,_this.selectedPreset,_this.selectedDurationSeconds,_this.pomodoroEnabled,_this.completionCueEnabled);
}

@override
String toString() {
  final _this = this as SessionState;
  return 'SessionState(isActive: ${_this.isActive}, isPaused: ${_this.isPaused}, isLoading: ${_this.isLoading}, currentSession: ${_this.currentSession}, elapsedSeconds: ${_this.elapsedSeconds}, remainingSeconds: ${_this.remainingSeconds}, phase: ${_this.phase}, selectedPreset: ${_this.selectedPreset}, selectedDurationSeconds: ${_this.selectedDurationSeconds}, pomodoroEnabled: ${_this.pomodoroEnabled}, completionCueEnabled: ${_this.completionCueEnabled})';
}


}

/// @nodoc
abstract mixin class $SessionStateCopyWith<$Res>  {
  factory $SessionStateCopyWith(SessionState value, $Res Function(SessionState) _then) = _$SessionStateCopyWithImpl;
@useResult
$Res call({
 bool isActive, bool isPaused, bool isLoading, FocusSession? currentSession, int elapsedSeconds, int? remainingSeconds, SessionPhase phase, SoundscapePreset selectedPreset, int? selectedDurationSeconds, bool pomodoroEnabled, bool completionCueEnabled
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
@pragma('vm:prefer-inline') @override $Res call({Object? isActive = null,Object? isPaused = null,Object? isLoading = null,Object? currentSession = freezed,Object? elapsedSeconds = null,Object? remainingSeconds = freezed,Object? phase = null,Object? selectedPreset = null,Object? selectedDurationSeconds = freezed,Object? pomodoroEnabled = null,Object? completionCueEnabled = null,}) {
  return _then(SessionState(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,currentSession: freezed == currentSession ? _self.currentSession : currentSession // ignore: cast_nullable_to_non_nullable
as FocusSession?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: freezed == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SessionPhase,selectedPreset: null == selectedPreset ? _self.selectedPreset : selectedPreset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,selectedDurationSeconds: freezed == selectedDurationSeconds ? _self.selectedDurationSeconds : selectedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,pomodoroEnabled: null == pomodoroEnabled ? _self.pomodoroEnabled : pomodoroEnabled // ignore: cast_nullable_to_non_nullable
as bool,completionCueEnabled: null == completionCueEnabled ? _self.completionCueEnabled : completionCueEnabled // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActive,  bool isPaused,  bool isLoading,  FocusSession? currentSession,  int elapsedSeconds,  int? remainingSeconds,  SessionPhase phase,  SoundscapePreset selectedPreset,  int? selectedDurationSeconds,  bool pomodoroEnabled,  bool completionCueEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.isActive,_that.isPaused,_that.isLoading,_that.currentSession,_that.elapsedSeconds,_that.remainingSeconds,_that.phase,_that.selectedPreset,_that.selectedDurationSeconds,_that.pomodoroEnabled,_that.completionCueEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActive,  bool isPaused,  bool isLoading,  FocusSession? currentSession,  int elapsedSeconds,  int? remainingSeconds,  SessionPhase phase,  SoundscapePreset selectedPreset,  int? selectedDurationSeconds,  bool pomodoroEnabled,  bool completionCueEnabled)  $default,) {final _that = this;
switch (_that) {
case _SessionState():
return $default(_that.isActive,_that.isPaused,_that.isLoading,_that.currentSession,_that.elapsedSeconds,_that.remainingSeconds,_that.phase,_that.selectedPreset,_that.selectedDurationSeconds,_that.pomodoroEnabled,_that.completionCueEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActive,  bool isPaused,  bool isLoading,  FocusSession? currentSession,  int elapsedSeconds,  int? remainingSeconds,  SessionPhase phase,  SoundscapePreset selectedPreset,  int? selectedDurationSeconds,  bool pomodoroEnabled,  bool completionCueEnabled)?  $default,) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.isActive,_that.isPaused,_that.isLoading,_that.currentSession,_that.elapsedSeconds,_that.remainingSeconds,_that.phase,_that.selectedPreset,_that.selectedDurationSeconds,_that.pomodoroEnabled,_that.completionCueEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _SessionState implements SessionState {
  const _SessionState({this.isActive = false, this.isPaused = false, this.isLoading = false, this.currentSession, this.elapsedSeconds = 0, this.remainingSeconds, this.phase = SessionPhase.settling, required this.selectedPreset, this.selectedDurationSeconds, this.pomodoroEnabled = false, this.completionCueEnabled = true});
  

@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isPaused;
@override@JsonKey() final  bool isLoading;
@override final  FocusSession? currentSession;
@override@JsonKey() final  int elapsedSeconds;
@override final  int? remainingSeconds;
@override@JsonKey() final  SessionPhase phase;
@override final  SoundscapePreset selectedPreset;
@override final  int? selectedDurationSeconds;
@override@JsonKey() final  bool pomodoroEnabled;
@override@JsonKey() final  bool completionCueEnabled;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStateCopyWith<_SessionState> get copyWith => __$SessionStateCopyWithImpl<_SessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isPaused, isPaused) || other.isPaused == isPaused)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.currentSession, currentSession) || other.currentSession == currentSession)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.selectedPreset, selectedPreset) || other.selectedPreset == selectedPreset)&&(identical(other.selectedDurationSeconds, selectedDurationSeconds) || other.selectedDurationSeconds == selectedDurationSeconds)&&(identical(other.pomodoroEnabled, pomodoroEnabled) || other.pomodoroEnabled == pomodoroEnabled)&&(identical(other.completionCueEnabled, completionCueEnabled) || other.completionCueEnabled == completionCueEnabled));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isActive,isPaused,isLoading,currentSession,elapsedSeconds,remainingSeconds,phase,selectedPreset,selectedDurationSeconds,pomodoroEnabled,completionCueEnabled);
}

@override
String toString() {
    return 'SessionState(isActive: $isActive, isPaused: $isPaused, isLoading: $isLoading, currentSession: $currentSession, elapsedSeconds: $elapsedSeconds, remainingSeconds: $remainingSeconds, phase: $phase, selectedPreset: $selectedPreset, selectedDurationSeconds: $selectedDurationSeconds, pomodoroEnabled: $pomodoroEnabled, completionCueEnabled: $completionCueEnabled)';
}


}

/// @nodoc
abstract mixin class _$SessionStateCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory _$SessionStateCopyWith(_SessionState value, $Res Function(_SessionState) _then) = __$SessionStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActive, bool isPaused, bool isLoading, FocusSession? currentSession, int elapsedSeconds, int? remainingSeconds, SessionPhase phase, SoundscapePreset selectedPreset, int? selectedDurationSeconds, bool pomodoroEnabled, bool completionCueEnabled
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
@override @pragma('vm:prefer-inline') $Res call({Object? isActive = null,Object? isPaused = null,Object? isLoading = null,Object? currentSession = freezed,Object? elapsedSeconds = null,Object? remainingSeconds = freezed,Object? phase = null,Object? selectedPreset = null,Object? selectedDurationSeconds = freezed,Object? pomodoroEnabled = null,Object? completionCueEnabled = null,}) {
  return _then(_SessionState(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isPaused: null == isPaused ? _self.isPaused : isPaused // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,currentSession: freezed == currentSession ? _self.currentSession : currentSession // ignore: cast_nullable_to_non_nullable
as FocusSession?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: freezed == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int?,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SessionPhase,selectedPreset: null == selectedPreset ? _self.selectedPreset : selectedPreset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,selectedDurationSeconds: freezed == selectedDurationSeconds ? _self.selectedDurationSeconds : selectedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,pomodoroEnabled: null == pomodoroEnabled ? _self.pomodoroEnabled : pomodoroEnabled // ignore: cast_nullable_to_non_nullable
as bool,completionCueEnabled: null == completionCueEnabled ? _self.completionCueEnabled : completionCueEnabled // ignore: cast_nullable_to_non_nullable
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
