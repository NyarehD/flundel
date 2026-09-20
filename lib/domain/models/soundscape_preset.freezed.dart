// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'soundscape_preset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SoundscapePreset {

@HiveField(0) String get id;@HiveField(1) String get name;@HiveField(2) SoundscapeConfig get config;@HiveField(3) String get visualPreset;
/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SoundscapePresetCopyWith<SoundscapePreset> get copyWith => _$SoundscapePresetCopyWithImpl<SoundscapePreset>(this as SoundscapePreset, _$identity);

  /// Serializes this SoundscapePreset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SoundscapePreset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.config, config) || other.config == config)&&(identical(other.visualPreset, visualPreset) || other.visualPreset == visualPreset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,config,visualPreset);

@override
String toString() {
  return 'SoundscapePreset(id: $id, name: $name, config: $config, visualPreset: $visualPreset)';
}


}

/// @nodoc
abstract mixin class $SoundscapePresetCopyWith<$Res>  {
  factory $SoundscapePresetCopyWith(SoundscapePreset value, $Res Function(SoundscapePreset) _then) = _$SoundscapePresetCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) SoundscapeConfig config,@HiveField(3) String visualPreset
});


$SoundscapeConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$SoundscapePresetCopyWithImpl<$Res>
    implements $SoundscapePresetCopyWith<$Res> {
  _$SoundscapePresetCopyWithImpl(this._self, this._then);

  final SoundscapePreset _self;
  final $Res Function(SoundscapePreset) _then;

/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? config = null,Object? visualPreset = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as SoundscapeConfig,visualPreset: null == visualPreset ? _self.visualPreset : visualPreset // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SoundscapeConfigCopyWith<$Res> get config {
  
  return $SoundscapeConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [SoundscapePreset].
extension SoundscapePresetPatterns on SoundscapePreset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SoundscapePreset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SoundscapePreset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SoundscapePreset value)  $default,){
final _that = this;
switch (_that) {
case _SoundscapePreset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SoundscapePreset value)?  $default,){
final _that = this;
switch (_that) {
case _SoundscapePreset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  SoundscapeConfig config, @HiveField(3)  String visualPreset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SoundscapePreset() when $default != null:
return $default(_that.id,_that.name,_that.config,_that.visualPreset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  SoundscapeConfig config, @HiveField(3)  String visualPreset)  $default,) {final _that = this;
switch (_that) {
case _SoundscapePreset():
return $default(_that.id,_that.name,_that.config,_that.visualPreset);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  SoundscapeConfig config, @HiveField(3)  String visualPreset)?  $default,) {final _that = this;
switch (_that) {
case _SoundscapePreset() when $default != null:
return $default(_that.id,_that.name,_that.config,_that.visualPreset);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SoundscapePreset implements SoundscapePreset {
  const _SoundscapePreset({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) required this.config, @HiveField(3) this.visualPreset = 'particles_waves'});
  factory _SoundscapePreset.fromJson(Map<String, dynamic> json) => _$SoundscapePresetFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String name;
@override@HiveField(2) final  SoundscapeConfig config;
@override@JsonKey()@HiveField(3) final  String visualPreset;

/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SoundscapePresetCopyWith<_SoundscapePreset> get copyWith => __$SoundscapePresetCopyWithImpl<_SoundscapePreset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SoundscapePresetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SoundscapePreset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.config, config) || other.config == config)&&(identical(other.visualPreset, visualPreset) || other.visualPreset == visualPreset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,config,visualPreset);

@override
String toString() {
  return 'SoundscapePreset(id: $id, name: $name, config: $config, visualPreset: $visualPreset)';
}


}

/// @nodoc
abstract mixin class _$SoundscapePresetCopyWith<$Res> implements $SoundscapePresetCopyWith<$Res> {
  factory _$SoundscapePresetCopyWith(_SoundscapePreset value, $Res Function(_SoundscapePreset) _then) = __$SoundscapePresetCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) SoundscapeConfig config,@HiveField(3) String visualPreset
});


@override $SoundscapeConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$SoundscapePresetCopyWithImpl<$Res>
    implements _$SoundscapePresetCopyWith<$Res> {
  __$SoundscapePresetCopyWithImpl(this._self, this._then);

  final _SoundscapePreset _self;
  final $Res Function(_SoundscapePreset) _then;

/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? config = null,Object? visualPreset = null,}) {
  return _then(_SoundscapePreset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as SoundscapeConfig,visualPreset: null == visualPreset ? _self.visualPreset : visualPreset // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SoundscapeConfigCopyWith<$Res> get config {
  
  return $SoundscapeConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
