// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'soundscape_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SoundscapeConfig {

@HiveField(0) double get intensity;@HiveField(1) double get warmth;@HiveField(2) double get complexity;@HiveField(3) double get piano;@HiveField(4) double get noise;@HiveField(5) double get pad;@HiveField(6) double get nature;@HiveField(7) double get binaural;@HiveField(8) double get beats;@HiveField(9) double get bass;@HiveField(10) int get beatsBpm;
/// Create a copy of SoundscapeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SoundscapeConfigCopyWith<SoundscapeConfig> get copyWith => _$SoundscapeConfigCopyWithImpl<SoundscapeConfig>(this as SoundscapeConfig, _$identity);

  /// Serializes this SoundscapeConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SoundscapeConfig&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.warmth, warmth) || other.warmth == warmth)&&(identical(other.complexity, complexity) || other.complexity == complexity)&&(identical(other.piano, piano) || other.piano == piano)&&(identical(other.noise, noise) || other.noise == noise)&&(identical(other.pad, pad) || other.pad == pad)&&(identical(other.nature, nature) || other.nature == nature)&&(identical(other.binaural, binaural) || other.binaural == binaural)&&(identical(other.beats, beats) || other.beats == beats)&&(identical(other.bass, bass) || other.bass == bass)&&(identical(other.beatsBpm, beatsBpm) || other.beatsBpm == beatsBpm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intensity,warmth,complexity,piano,noise,pad,nature,binaural,beats,bass,beatsBpm);

@override
String toString() {
  return 'SoundscapeConfig(intensity: $intensity, warmth: $warmth, complexity: $complexity, piano: $piano, noise: $noise, pad: $pad, nature: $nature, binaural: $binaural, beats: $beats, bass: $bass, beatsBpm: $beatsBpm)';
}


}

/// @nodoc
abstract mixin class $SoundscapeConfigCopyWith<$Res>  {
  factory $SoundscapeConfigCopyWith(SoundscapeConfig value, $Res Function(SoundscapeConfig) _then) = _$SoundscapeConfigCopyWithImpl;
@useResult
$Res call({
@HiveField(0) double intensity,@HiveField(1) double warmth,@HiveField(2) double complexity,@HiveField(3) double piano,@HiveField(4) double noise,@HiveField(5) double pad,@HiveField(6) double nature,@HiveField(7) double binaural,@HiveField(8) double beats,@HiveField(9) double bass,@HiveField(10) int beatsBpm
});




}
/// @nodoc
class _$SoundscapeConfigCopyWithImpl<$Res>
    implements $SoundscapeConfigCopyWith<$Res> {
  _$SoundscapeConfigCopyWithImpl(this._self, this._then);

  final SoundscapeConfig _self;
  final $Res Function(SoundscapeConfig) _then;

/// Create a copy of SoundscapeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intensity = null,Object? warmth = null,Object? complexity = null,Object? piano = null,Object? noise = null,Object? pad = null,Object? nature = null,Object? binaural = null,Object? beats = null,Object? bass = null,Object? beatsBpm = null,}) {
  return _then(_self.copyWith(
intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,warmth: null == warmth ? _self.warmth : warmth // ignore: cast_nullable_to_non_nullable
as double,complexity: null == complexity ? _self.complexity : complexity // ignore: cast_nullable_to_non_nullable
as double,piano: null == piano ? _self.piano : piano // ignore: cast_nullable_to_non_nullable
as double,noise: null == noise ? _self.noise : noise // ignore: cast_nullable_to_non_nullable
as double,pad: null == pad ? _self.pad : pad // ignore: cast_nullable_to_non_nullable
as double,nature: null == nature ? _self.nature : nature // ignore: cast_nullable_to_non_nullable
as double,binaural: null == binaural ? _self.binaural : binaural // ignore: cast_nullable_to_non_nullable
as double,beats: null == beats ? _self.beats : beats // ignore: cast_nullable_to_non_nullable
as double,bass: null == bass ? _self.bass : bass // ignore: cast_nullable_to_non_nullable
as double,beatsBpm: null == beatsBpm ? _self.beatsBpm : beatsBpm // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SoundscapeConfig].
extension SoundscapeConfigPatterns on SoundscapeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SoundscapeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SoundscapeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SoundscapeConfig value)  $default,){
final _that = this;
switch (_that) {
case _SoundscapeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SoundscapeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _SoundscapeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  double intensity, @HiveField(1)  double warmth, @HiveField(2)  double complexity, @HiveField(3)  double piano, @HiveField(4)  double noise, @HiveField(5)  double pad, @HiveField(6)  double nature, @HiveField(7)  double binaural, @HiveField(8)  double beats, @HiveField(9)  double bass, @HiveField(10)  int beatsBpm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SoundscapeConfig() when $default != null:
return $default(_that.intensity,_that.warmth,_that.complexity,_that.piano,_that.noise,_that.pad,_that.nature,_that.binaural,_that.beats,_that.bass,_that.beatsBpm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  double intensity, @HiveField(1)  double warmth, @HiveField(2)  double complexity, @HiveField(3)  double piano, @HiveField(4)  double noise, @HiveField(5)  double pad, @HiveField(6)  double nature, @HiveField(7)  double binaural, @HiveField(8)  double beats, @HiveField(9)  double bass, @HiveField(10)  int beatsBpm)  $default,) {final _that = this;
switch (_that) {
case _SoundscapeConfig():
return $default(_that.intensity,_that.warmth,_that.complexity,_that.piano,_that.noise,_that.pad,_that.nature,_that.binaural,_that.beats,_that.bass,_that.beatsBpm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  double intensity, @HiveField(1)  double warmth, @HiveField(2)  double complexity, @HiveField(3)  double piano, @HiveField(4)  double noise, @HiveField(5)  double pad, @HiveField(6)  double nature, @HiveField(7)  double binaural, @HiveField(8)  double beats, @HiveField(9)  double bass, @HiveField(10)  int beatsBpm)?  $default,) {final _that = this;
switch (_that) {
case _SoundscapeConfig() when $default != null:
return $default(_that.intensity,_that.warmth,_that.complexity,_that.piano,_that.noise,_that.pad,_that.nature,_that.binaural,_that.beats,_that.bass,_that.beatsBpm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SoundscapeConfig implements SoundscapeConfig {
  const _SoundscapeConfig({@HiveField(0) this.intensity = 0.5, @HiveField(1) this.warmth = 0.5, @HiveField(2) this.complexity = 0.5, @HiveField(3) this.piano = 0.3, @HiveField(4) this.noise = 0.5, @HiveField(5) this.pad = 0.4, @HiveField(6) this.nature = 0.2, @HiveField(7) this.binaural = 0.2, @HiveField(8) this.beats = 0.0, @HiveField(9) this.bass = 0.0, @HiveField(10) this.beatsBpm = 72});
  factory _SoundscapeConfig.fromJson(Map<String, dynamic> json) => _$SoundscapeConfigFromJson(json);

@override@JsonKey()@HiveField(0) final  double intensity;
@override@JsonKey()@HiveField(1) final  double warmth;
@override@JsonKey()@HiveField(2) final  double complexity;
@override@JsonKey()@HiveField(3) final  double piano;
@override@JsonKey()@HiveField(4) final  double noise;
@override@JsonKey()@HiveField(5) final  double pad;
@override@JsonKey()@HiveField(6) final  double nature;
@override@JsonKey()@HiveField(7) final  double binaural;
@override@JsonKey()@HiveField(8) final  double beats;
@override@JsonKey()@HiveField(9) final  double bass;
@override@JsonKey()@HiveField(10) final  int beatsBpm;

/// Create a copy of SoundscapeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SoundscapeConfigCopyWith<_SoundscapeConfig> get copyWith => __$SoundscapeConfigCopyWithImpl<_SoundscapeConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SoundscapeConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SoundscapeConfig&&(identical(other.intensity, intensity) || other.intensity == intensity)&&(identical(other.warmth, warmth) || other.warmth == warmth)&&(identical(other.complexity, complexity) || other.complexity == complexity)&&(identical(other.piano, piano) || other.piano == piano)&&(identical(other.noise, noise) || other.noise == noise)&&(identical(other.pad, pad) || other.pad == pad)&&(identical(other.nature, nature) || other.nature == nature)&&(identical(other.binaural, binaural) || other.binaural == binaural)&&(identical(other.beats, beats) || other.beats == beats)&&(identical(other.bass, bass) || other.bass == bass)&&(identical(other.beatsBpm, beatsBpm) || other.beatsBpm == beatsBpm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intensity,warmth,complexity,piano,noise,pad,nature,binaural,beats,bass,beatsBpm);

@override
String toString() {
  return 'SoundscapeConfig(intensity: $intensity, warmth: $warmth, complexity: $complexity, piano: $piano, noise: $noise, pad: $pad, nature: $nature, binaural: $binaural, beats: $beats, bass: $bass, beatsBpm: $beatsBpm)';
}


}

/// @nodoc
abstract mixin class _$SoundscapeConfigCopyWith<$Res> implements $SoundscapeConfigCopyWith<$Res> {
  factory _$SoundscapeConfigCopyWith(_SoundscapeConfig value, $Res Function(_SoundscapeConfig) _then) = __$SoundscapeConfigCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) double intensity,@HiveField(1) double warmth,@HiveField(2) double complexity,@HiveField(3) double piano,@HiveField(4) double noise,@HiveField(5) double pad,@HiveField(6) double nature,@HiveField(7) double binaural,@HiveField(8) double beats,@HiveField(9) double bass,@HiveField(10) int beatsBpm
});




}
/// @nodoc
class __$SoundscapeConfigCopyWithImpl<$Res>
    implements _$SoundscapeConfigCopyWith<$Res> {
  __$SoundscapeConfigCopyWithImpl(this._self, this._then);

  final _SoundscapeConfig _self;
  final $Res Function(_SoundscapeConfig) _then;

/// Create a copy of SoundscapeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intensity = null,Object? warmth = null,Object? complexity = null,Object? piano = null,Object? noise = null,Object? pad = null,Object? nature = null,Object? binaural = null,Object? beats = null,Object? bass = null,Object? beatsBpm = null,}) {
  return _then(_SoundscapeConfig(
intensity: null == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as double,warmth: null == warmth ? _self.warmth : warmth // ignore: cast_nullable_to_non_nullable
as double,complexity: null == complexity ? _self.complexity : complexity // ignore: cast_nullable_to_non_nullable
as double,piano: null == piano ? _self.piano : piano // ignore: cast_nullable_to_non_nullable
as double,noise: null == noise ? _self.noise : noise // ignore: cast_nullable_to_non_nullable
as double,pad: null == pad ? _self.pad : pad // ignore: cast_nullable_to_non_nullable
as double,nature: null == nature ? _self.nature : nature // ignore: cast_nullable_to_non_nullable
as double,binaural: null == binaural ? _self.binaural : binaural // ignore: cast_nullable_to_non_nullable
as double,beats: null == beats ? _self.beats : beats // ignore: cast_nullable_to_non_nullable
as double,bass: null == bass ? _self.bass : bass // ignore: cast_nullable_to_non_nullable
as double,beatsBpm: null == beatsBpm ? _self.beatsBpm : beatsBpm // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
