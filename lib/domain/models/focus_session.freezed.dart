// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FocusSession {

@HiveField(0) String get id;@HiveField(1) DateTime get startedAt;@HiveField(2) int? get durationSeconds;@HiveField(3) SoundscapePreset get preset;@HiveField(4) int get sessionSeed;@HiveField(5) SessionStatus get status;@HiveField(6) bool get isPomodoro;
/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusSessionCopyWith<FocusSession> get copyWith => _$FocusSessionCopyWithImpl<FocusSession>(this as FocusSession, _$identity);

  /// Serializes this FocusSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.sessionSeed, sessionSeed) || other.sessionSeed == sessionSeed)&&(identical(other.status, status) || other.status == status)&&(identical(other.isPomodoro, isPomodoro) || other.isPomodoro == isPomodoro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startedAt,durationSeconds,preset,sessionSeed,status,isPomodoro);

@override
String toString() {
  return 'FocusSession(id: $id, startedAt: $startedAt, durationSeconds: $durationSeconds, preset: $preset, sessionSeed: $sessionSeed, status: $status, isPomodoro: $isPomodoro)';
}


}

/// @nodoc
abstract mixin class $FocusSessionCopyWith<$Res>  {
  factory $FocusSessionCopyWith(FocusSession value, $Res Function(FocusSession) _then) = _$FocusSessionCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) DateTime startedAt,@HiveField(2) int? durationSeconds,@HiveField(3) SoundscapePreset preset,@HiveField(4) int sessionSeed,@HiveField(5) SessionStatus status,@HiveField(6) bool isPomodoro
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? durationSeconds = freezed,Object? preset = null,Object? sessionSeed = null,Object? status = null,Object? isPomodoro = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,sessionSeed: null == sessionSeed ? _self.sessionSeed : sessionSeed // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,isPomodoro: null == isPomodoro ? _self.isPomodoro : isPomodoro // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FocusSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FocusSession value)  $default,){
final _that = this;
switch (_that) {
case _FocusSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FocusSession value)?  $default,){
final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  DateTime startedAt, @HiveField(2)  int? durationSeconds, @HiveField(3)  SoundscapePreset preset, @HiveField(4)  int sessionSeed, @HiveField(5)  SessionStatus status, @HiveField(6)  bool isPomodoro)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
return $default(_that.id,_that.startedAt,_that.durationSeconds,_that.preset,_that.sessionSeed,_that.status,_that.isPomodoro);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  DateTime startedAt, @HiveField(2)  int? durationSeconds, @HiveField(3)  SoundscapePreset preset, @HiveField(4)  int sessionSeed, @HiveField(5)  SessionStatus status, @HiveField(6)  bool isPomodoro)  $default,) {final _that = this;
switch (_that) {
case _FocusSession():
return $default(_that.id,_that.startedAt,_that.durationSeconds,_that.preset,_that.sessionSeed,_that.status,_that.isPomodoro);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  DateTime startedAt, @HiveField(2)  int? durationSeconds, @HiveField(3)  SoundscapePreset preset, @HiveField(4)  int sessionSeed, @HiveField(5)  SessionStatus status, @HiveField(6)  bool isPomodoro)?  $default,) {final _that = this;
switch (_that) {
case _FocusSession() when $default != null:
return $default(_that.id,_that.startedAt,_that.durationSeconds,_that.preset,_that.sessionSeed,_that.status,_that.isPomodoro);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FocusSession implements FocusSession {
  const _FocusSession({@HiveField(0) required this.id, @HiveField(1) required this.startedAt, @HiveField(2) this.durationSeconds, @HiveField(3) required this.preset, @HiveField(4) this.sessionSeed = 12345, @HiveField(5) this.status = SessionStatus.active, @HiveField(6) this.isPomodoro = false});
  factory _FocusSession.fromJson(Map<String, dynamic> json) => _$FocusSessionFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  DateTime startedAt;
@override@HiveField(2) final  int? durationSeconds;
@override@HiveField(3) final  SoundscapePreset preset;
@override@JsonKey()@HiveField(4) final  int sessionSeed;
@override@JsonKey()@HiveField(5) final  SessionStatus status;
@override@JsonKey()@HiveField(6) final  bool isPomodoro;

/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FocusSessionCopyWith<_FocusSession> get copyWith => __$FocusSessionCopyWithImpl<_FocusSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FocusSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FocusSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.sessionSeed, sessionSeed) || other.sessionSeed == sessionSeed)&&(identical(other.status, status) || other.status == status)&&(identical(other.isPomodoro, isPomodoro) || other.isPomodoro == isPomodoro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startedAt,durationSeconds,preset,sessionSeed,status,isPomodoro);

@override
String toString() {
  return 'FocusSession(id: $id, startedAt: $startedAt, durationSeconds: $durationSeconds, preset: $preset, sessionSeed: $sessionSeed, status: $status, isPomodoro: $isPomodoro)';
}


}

/// @nodoc
abstract mixin class _$FocusSessionCopyWith<$Res> implements $FocusSessionCopyWith<$Res> {
  factory _$FocusSessionCopyWith(_FocusSession value, $Res Function(_FocusSession) _then) = __$FocusSessionCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) DateTime startedAt,@HiveField(2) int? durationSeconds,@HiveField(3) SoundscapePreset preset,@HiveField(4) int sessionSeed,@HiveField(5) SessionStatus status,@HiveField(6) bool isPomodoro
});


@override $SoundscapePresetCopyWith<$Res> get preset;

}
/// @nodoc
class __$FocusSessionCopyWithImpl<$Res>
    implements _$FocusSessionCopyWith<$Res> {
  __$FocusSessionCopyWithImpl(this._self, this._then);

  final _FocusSession _self;
  final $Res Function(_FocusSession) _then;

/// Create a copy of FocusSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? durationSeconds = freezed,Object? preset = null,Object? sessionSeed = null,Object? status = null,Object? isPomodoro = null,}) {
  return _then(_FocusSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as SoundscapePreset,sessionSeed: null == sessionSeed ? _self.sessionSeed : sessionSeed // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,isPomodoro: null == isPomodoro ? _self.isPomodoro : isPomodoro // ignore: cast_nullable_to_non_nullable
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

// dart format on
