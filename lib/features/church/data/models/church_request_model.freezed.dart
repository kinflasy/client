// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'church_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnitRequestModel {

 String get name; String get slug; String get phone; String get email; String get type; AddressRequestModel get address;
/// Create a copy of UnitRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitRequestModelCopyWith<UnitRequestModel> get copyWith => _$UnitRequestModelCopyWithImpl<UnitRequestModel>(this as UnitRequestModel, _$identity);

  /// Serializes this UnitRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitRequestModel&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.type, type) || other.type == type)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,phone,email,type,address);

@override
String toString() {
  return 'UnitRequestModel(name: $name, slug: $slug, phone: $phone, email: $email, type: $type, address: $address)';
}


}

/// @nodoc
abstract mixin class $UnitRequestModelCopyWith<$Res>  {
  factory $UnitRequestModelCopyWith(UnitRequestModel value, $Res Function(UnitRequestModel) _then) = _$UnitRequestModelCopyWithImpl;
@useResult
$Res call({
 String name, String slug, String phone, String email, String type, AddressRequestModel address
});


$AddressRequestModelCopyWith<$Res> get address;

}
/// @nodoc
class _$UnitRequestModelCopyWithImpl<$Res>
    implements $UnitRequestModelCopyWith<$Res> {
  _$UnitRequestModelCopyWithImpl(this._self, this._then);

  final UnitRequestModel _self;
  final $Res Function(UnitRequestModel) _then;

/// Create a copy of UnitRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? slug = null,Object? phone = null,Object? email = null,Object? type = null,Object? address = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AddressRequestModel,
  ));
}
/// Create a copy of UnitRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressRequestModelCopyWith<$Res> get address {
  
  return $AddressRequestModelCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds pattern-matching-related methods to [UnitRequestModel].
extension UnitRequestModelPatterns on UnitRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _UnitRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _UnitRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String slug,  String phone,  String email,  String type,  AddressRequestModel address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitRequestModel() when $default != null:
return $default(_that.name,_that.slug,_that.phone,_that.email,_that.type,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String slug,  String phone,  String email,  String type,  AddressRequestModel address)  $default,) {final _that = this;
switch (_that) {
case _UnitRequestModel():
return $default(_that.name,_that.slug,_that.phone,_that.email,_that.type,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String slug,  String phone,  String email,  String type,  AddressRequestModel address)?  $default,) {final _that = this;
switch (_that) {
case _UnitRequestModel() when $default != null:
return $default(_that.name,_that.slug,_that.phone,_that.email,_that.type,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnitRequestModel implements UnitRequestModel {
  const _UnitRequestModel({required this.name, required this.slug, required this.phone, required this.email, this.type = 'MAIN', required this.address});
  factory _UnitRequestModel.fromJson(Map<String, dynamic> json) => _$UnitRequestModelFromJson(json);

@override final  String name;
@override final  String slug;
@override final  String phone;
@override final  String email;
@override@JsonKey() final  String type;
@override final  AddressRequestModel address;

/// Create a copy of UnitRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitRequestModelCopyWith<_UnitRequestModel> get copyWith => __$UnitRequestModelCopyWithImpl<_UnitRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitRequestModel&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.type, type) || other.type == type)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,phone,email,type,address);

@override
String toString() {
  return 'UnitRequestModel(name: $name, slug: $slug, phone: $phone, email: $email, type: $type, address: $address)';
}


}

/// @nodoc
abstract mixin class _$UnitRequestModelCopyWith<$Res> implements $UnitRequestModelCopyWith<$Res> {
  factory _$UnitRequestModelCopyWith(_UnitRequestModel value, $Res Function(_UnitRequestModel) _then) = __$UnitRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String name, String slug, String phone, String email, String type, AddressRequestModel address
});


@override $AddressRequestModelCopyWith<$Res> get address;

}
/// @nodoc
class __$UnitRequestModelCopyWithImpl<$Res>
    implements _$UnitRequestModelCopyWith<$Res> {
  __$UnitRequestModelCopyWithImpl(this._self, this._then);

  final _UnitRequestModel _self;
  final $Res Function(_UnitRequestModel) _then;

/// Create a copy of UnitRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? slug = null,Object? phone = null,Object? email = null,Object? type = null,Object? address = null,}) {
  return _then(_UnitRequestModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as AddressRequestModel,
  ));
}

/// Create a copy of UnitRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressRequestModelCopyWith<$Res> get address {
  
  return $AddressRequestModelCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// @nodoc
mixin _$ChurchStarterRequestModel {

 String get name; String get slug; String? get acronym; String? get phone; String get email; UnitRequestModel get unit;
/// Create a copy of ChurchStarterRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChurchStarterRequestModelCopyWith<ChurchStarterRequestModel> get copyWith => _$ChurchStarterRequestModelCopyWithImpl<ChurchStarterRequestModel>(this as ChurchStarterRequestModel, _$identity);

  /// Serializes this ChurchStarterRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChurchStarterRequestModel&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.acronym, acronym) || other.acronym == acronym)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,acronym,phone,email,unit);

@override
String toString() {
  return 'ChurchStarterRequestModel(name: $name, slug: $slug, acronym: $acronym, phone: $phone, email: $email, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $ChurchStarterRequestModelCopyWith<$Res>  {
  factory $ChurchStarterRequestModelCopyWith(ChurchStarterRequestModel value, $Res Function(ChurchStarterRequestModel) _then) = _$ChurchStarterRequestModelCopyWithImpl;
@useResult
$Res call({
 String name, String slug, String? acronym, String? phone, String email, UnitRequestModel unit
});


$UnitRequestModelCopyWith<$Res> get unit;

}
/// @nodoc
class _$ChurchStarterRequestModelCopyWithImpl<$Res>
    implements $ChurchStarterRequestModelCopyWith<$Res> {
  _$ChurchStarterRequestModelCopyWithImpl(this._self, this._then);

  final ChurchStarterRequestModel _self;
  final $Res Function(ChurchStarterRequestModel) _then;

/// Create a copy of ChurchStarterRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? slug = null,Object? acronym = freezed,Object? phone = freezed,Object? email = null,Object? unit = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,acronym: freezed == acronym ? _self.acronym : acronym // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as UnitRequestModel,
  ));
}
/// Create a copy of ChurchStarterRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnitRequestModelCopyWith<$Res> get unit {
  
  return $UnitRequestModelCopyWith<$Res>(_self.unit, (value) {
    return _then(_self.copyWith(unit: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChurchStarterRequestModel].
extension ChurchStarterRequestModelPatterns on ChurchStarterRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChurchStarterRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChurchStarterRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChurchStarterRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _ChurchStarterRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChurchStarterRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChurchStarterRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String slug,  String? acronym,  String? phone,  String email,  UnitRequestModel unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChurchStarterRequestModel() when $default != null:
return $default(_that.name,_that.slug,_that.acronym,_that.phone,_that.email,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String slug,  String? acronym,  String? phone,  String email,  UnitRequestModel unit)  $default,) {final _that = this;
switch (_that) {
case _ChurchStarterRequestModel():
return $default(_that.name,_that.slug,_that.acronym,_that.phone,_that.email,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String slug,  String? acronym,  String? phone,  String email,  UnitRequestModel unit)?  $default,) {final _that = this;
switch (_that) {
case _ChurchStarterRequestModel() when $default != null:
return $default(_that.name,_that.slug,_that.acronym,_that.phone,_that.email,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChurchStarterRequestModel implements ChurchStarterRequestModel {
  const _ChurchStarterRequestModel({required this.name, required this.slug, this.acronym, this.phone, required this.email, required this.unit});
  factory _ChurchStarterRequestModel.fromJson(Map<String, dynamic> json) => _$ChurchStarterRequestModelFromJson(json);

@override final  String name;
@override final  String slug;
@override final  String? acronym;
@override final  String? phone;
@override final  String email;
@override final  UnitRequestModel unit;

/// Create a copy of ChurchStarterRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChurchStarterRequestModelCopyWith<_ChurchStarterRequestModel> get copyWith => __$ChurchStarterRequestModelCopyWithImpl<_ChurchStarterRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChurchStarterRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChurchStarterRequestModel&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.acronym, acronym) || other.acronym == acronym)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,slug,acronym,phone,email,unit);

@override
String toString() {
  return 'ChurchStarterRequestModel(name: $name, slug: $slug, acronym: $acronym, phone: $phone, email: $email, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$ChurchStarterRequestModelCopyWith<$Res> implements $ChurchStarterRequestModelCopyWith<$Res> {
  factory _$ChurchStarterRequestModelCopyWith(_ChurchStarterRequestModel value, $Res Function(_ChurchStarterRequestModel) _then) = __$ChurchStarterRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String name, String slug, String? acronym, String? phone, String email, UnitRequestModel unit
});


@override $UnitRequestModelCopyWith<$Res> get unit;

}
/// @nodoc
class __$ChurchStarterRequestModelCopyWithImpl<$Res>
    implements _$ChurchStarterRequestModelCopyWith<$Res> {
  __$ChurchStarterRequestModelCopyWithImpl(this._self, this._then);

  final _ChurchStarterRequestModel _self;
  final $Res Function(_ChurchStarterRequestModel) _then;

/// Create a copy of ChurchStarterRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? slug = null,Object? acronym = freezed,Object? phone = freezed,Object? email = null,Object? unit = null,}) {
  return _then(_ChurchStarterRequestModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,acronym: freezed == acronym ? _self.acronym : acronym // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as UnitRequestModel,
  ));
}

/// Create a copy of ChurchStarterRequestModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnitRequestModelCopyWith<$Res> get unit {
  
  return $UnitRequestModelCopyWith<$Res>(_self.unit, (value) {
    return _then(_self.copyWith(unit: value));
  });
}
}

// dart format on
