// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'soundscape_preset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SoundscapePreset {


/// Create a copy of SoundscapePreset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SoundscapePresetCopyWith<SoundscapePreset> get copyWith => _$SoundscapePresetCopyWithImpl<SoundscapePreset>(this as SoundscapePreset, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SoundscapePreset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SoundscapePreset&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.config, _this.config) || other.config == _this.config)&&(identical(other.visualPreset, _this.visualPreset) || other.visualPreset == _this.visualPreset));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SoundscapePreset;
  return Object.hash(runtimeType,_this.id,_this.name,_this.config,_this.visualPreset);
}

@override
String toString() {
  final _this = this as SoundscapePreset;
  return 'SoundscapePreset(id: ${_this.id}, name: ${_this.name}, config: ${_this.config}, visualPreset: ${_this.visualPreset})';
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
  return _then(SoundscapePreset(
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
