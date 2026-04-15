// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AddressRequestModel {

 String? get zip; String? get country; String? get state; String? get city; String? get neighborhood; String? get street; String? get number; String? get complement; String? get reference;
/// Create a copy of AddressRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddressRequestModelCopyWith<AddressRequestModel> get copyWith => _$AddressRequestModelCopyWithImpl<AddressRequestModel>(this as AddressRequestModel, _$identity);

  /// Serializes this AddressRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddressRequestModel&&(identical(other.zip, zip) || other.zip == zip)&&(identical(other.country, country) || other.country == country)&&(identical(other.state, state) || other.state == state)&&(identical(other.city, city) || other.city == city)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.street, street) || other.street == street)&&(identical(other.number, number) || other.number == number)&&(identical(other.complement, complement) || other.complement == complement)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,zip,country,state,city,neighborhood,street,number,complement,reference);

@override
String toString() {
  return 'AddressRequestModel(zip: $zip, country: $country, state: $state, city: $city, neighborhood: $neighborhood, street: $street, number: $number, complement: $complement, reference: $reference)';
}


}

/// @nodoc
abstract mixin class $AddressRequestModelCopyWith<$Res>  {
  factory $AddressRequestModelCopyWith(AddressRequestModel value, $Res Function(AddressRequestModel) _then) = _$AddressRequestModelCopyWithImpl;
@useResult
$Res call({
 String? zip, String? country, String? state, String? city, String? neighborhood, String? street, String? number, String? complement, String? reference
});




}
/// @nodoc
class _$AddressRequestModelCopyWithImpl<$Res>
    implements $AddressRequestModelCopyWith<$Res> {
  _$AddressRequestModelCopyWithImpl(this._self, this._then);

  final AddressRequestModel _self;
  final $Res Function(AddressRequestModel) _then;

/// Create a copy of AddressRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? zip = freezed,Object? country = freezed,Object? state = freezed,Object? city = freezed,Object? neighborhood = freezed,Object? street = freezed,Object? number = freezed,Object? complement = freezed,Object? reference = freezed,}) {
  return _then(_self.copyWith(
zip: freezed == zip ? _self.zip : zip // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,street: freezed == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,complement: freezed == complement ? _self.complement : complement // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddressRequestModel].
extension AddressRequestModelPatterns on AddressRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddressRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddressRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddressRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _AddressRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddressRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _AddressRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? zip,  String? country,  String? state,  String? city,  String? neighborhood,  String? street,  String? number,  String? complement,  String? reference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddressRequestModel() when $default != null:
return $default(_that.zip,_that.country,_that.state,_that.city,_that.neighborhood,_that.street,_that.number,_that.complement,_that.reference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? zip,  String? country,  String? state,  String? city,  String? neighborhood,  String? street,  String? number,  String? complement,  String? reference)  $default,) {final _that = this;
switch (_that) {
case _AddressRequestModel():
return $default(_that.zip,_that.country,_that.state,_that.city,_that.neighborhood,_that.street,_that.number,_that.complement,_that.reference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? zip,  String? country,  String? state,  String? city,  String? neighborhood,  String? street,  String? number,  String? complement,  String? reference)?  $default,) {final _that = this;
switch (_that) {
case _AddressRequestModel() when $default != null:
return $default(_that.zip,_that.country,_that.state,_that.city,_that.neighborhood,_that.street,_that.number,_that.complement,_that.reference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AddressRequestModel implements AddressRequestModel {
  const _AddressRequestModel({this.zip, this.country, this.state, this.city, this.neighborhood, this.street, this.number, this.complement, this.reference});
  factory _AddressRequestModel.fromJson(Map<String, dynamic> json) => _$AddressRequestModelFromJson(json);

@override final  String? zip;
@override final  String? country;
@override final  String? state;
@override final  String? city;
@override final  String? neighborhood;
@override final  String? street;
@override final  String? number;
@override final  String? complement;
@override final  String? reference;

/// Create a copy of AddressRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddressRequestModelCopyWith<_AddressRequestModel> get copyWith => __$AddressRequestModelCopyWithImpl<_AddressRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddressRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddressRequestModel&&(identical(other.zip, zip) || other.zip == zip)&&(identical(other.country, country) || other.country == country)&&(identical(other.state, state) || other.state == state)&&(identical(other.city, city) || other.city == city)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.street, street) || other.street == street)&&(identical(other.number, number) || other.number == number)&&(identical(other.complement, complement) || other.complement == complement)&&(identical(other.reference, reference) || other.reference == reference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,zip,country,state,city,neighborhood,street,number,complement,reference);

@override
String toString() {
  return 'AddressRequestModel(zip: $zip, country: $country, state: $state, city: $city, neighborhood: $neighborhood, street: $street, number: $number, complement: $complement, reference: $reference)';
}


}

/// @nodoc
abstract mixin class _$AddressRequestModelCopyWith<$Res> implements $AddressRequestModelCopyWith<$Res> {
  factory _$AddressRequestModelCopyWith(_AddressRequestModel value, $Res Function(_AddressRequestModel) _then) = __$AddressRequestModelCopyWithImpl;
@override @useResult
$Res call({
 String? zip, String? country, String? state, String? city, String? neighborhood, String? street, String? number, String? complement, String? reference
});




}
/// @nodoc
class __$AddressRequestModelCopyWithImpl<$Res>
    implements _$AddressRequestModelCopyWith<$Res> {
  __$AddressRequestModelCopyWithImpl(this._self, this._then);

  final _AddressRequestModel _self;
  final $Res Function(_AddressRequestModel) _then;

/// Create a copy of AddressRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? zip = freezed,Object? country = freezed,Object? state = freezed,Object? city = freezed,Object? neighborhood = freezed,Object? street = freezed,Object? number = freezed,Object? complement = freezed,Object? reference = freezed,}) {
  return _then(_AddressRequestModel(
zip: freezed == zip ? _self.zip : zip // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,street: freezed == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String?,number: freezed == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String?,complement: freezed == complement ? _self.complement : complement // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
