// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unit_member_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnitMemberModel {

 String get id; String get unitId; UnitMemberPersonModel get person; String get affiliation;
/// Create a copy of UnitMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitMemberModelCopyWith<UnitMemberModel> get copyWith => _$UnitMemberModelCopyWithImpl<UnitMemberModel>(this as UnitMemberModel, _$identity);

  /// Serializes this UnitMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.person, person) || other.person == person)&&(identical(other.affiliation, affiliation) || other.affiliation == affiliation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,person,affiliation);

@override
String toString() {
  return 'UnitMemberModel(id: $id, unitId: $unitId, person: $person, affiliation: $affiliation)';
}


}

/// @nodoc
abstract mixin class $UnitMemberModelCopyWith<$Res>  {
  factory $UnitMemberModelCopyWith(UnitMemberModel value, $Res Function(UnitMemberModel) _then) = _$UnitMemberModelCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, UnitMemberPersonModel person, String affiliation
});


$UnitMemberPersonModelCopyWith<$Res> get person;

}
/// @nodoc
class _$UnitMemberModelCopyWithImpl<$Res>
    implements $UnitMemberModelCopyWith<$Res> {
  _$UnitMemberModelCopyWithImpl(this._self, this._then);

  final UnitMemberModel _self;
  final $Res Function(UnitMemberModel) _then;

/// Create a copy of UnitMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? person = null,Object? affiliation = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,person: null == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as UnitMemberPersonModel,affiliation: null == affiliation ? _self.affiliation : affiliation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of UnitMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnitMemberPersonModelCopyWith<$Res> get person {
  
  return $UnitMemberPersonModelCopyWith<$Res>(_self.person, (value) {
    return _then(_self.copyWith(person: value));
  });
}
}


/// Adds pattern-matching-related methods to [UnitMemberModel].
extension UnitMemberModelPatterns on UnitMemberModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitMemberModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _UnitMemberModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _UnitMemberModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  UnitMemberPersonModel person,  String affiliation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitMemberModel() when $default != null:
return $default(_that.id,_that.unitId,_that.person,_that.affiliation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  UnitMemberPersonModel person,  String affiliation)  $default,) {final _that = this;
switch (_that) {
case _UnitMemberModel():
return $default(_that.id,_that.unitId,_that.person,_that.affiliation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  UnitMemberPersonModel person,  String affiliation)?  $default,) {final _that = this;
switch (_that) {
case _UnitMemberModel() when $default != null:
return $default(_that.id,_that.unitId,_that.person,_that.affiliation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnitMemberModel implements UnitMemberModel {
  const _UnitMemberModel({required this.id, required this.unitId, required this.person, required this.affiliation});
  factory _UnitMemberModel.fromJson(Map<String, dynamic> json) => _$UnitMemberModelFromJson(json);

@override final  String id;
@override final  String unitId;
@override final  UnitMemberPersonModel person;
@override final  String affiliation;

/// Create a copy of UnitMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitMemberModelCopyWith<_UnitMemberModel> get copyWith => __$UnitMemberModelCopyWithImpl<_UnitMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.person, person) || other.person == person)&&(identical(other.affiliation, affiliation) || other.affiliation == affiliation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,person,affiliation);

@override
String toString() {
  return 'UnitMemberModel(id: $id, unitId: $unitId, person: $person, affiliation: $affiliation)';
}


}

/// @nodoc
abstract mixin class _$UnitMemberModelCopyWith<$Res> implements $UnitMemberModelCopyWith<$Res> {
  factory _$UnitMemberModelCopyWith(_UnitMemberModel value, $Res Function(_UnitMemberModel) _then) = __$UnitMemberModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, UnitMemberPersonModel person, String affiliation
});


@override $UnitMemberPersonModelCopyWith<$Res> get person;

}
/// @nodoc
class __$UnitMemberModelCopyWithImpl<$Res>
    implements _$UnitMemberModelCopyWith<$Res> {
  __$UnitMemberModelCopyWithImpl(this._self, this._then);

  final _UnitMemberModel _self;
  final $Res Function(_UnitMemberModel) _then;

/// Create a copy of UnitMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? person = null,Object? affiliation = null,}) {
  return _then(_UnitMemberModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,person: null == person ? _self.person : person // ignore: cast_nullable_to_non_nullable
as UnitMemberPersonModel,affiliation: null == affiliation ? _self.affiliation : affiliation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of UnitMemberModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnitMemberPersonModelCopyWith<$Res> get person {
  
  return $UnitMemberPersonModelCopyWith<$Res>(_self.person, (value) {
    return _then(_self.copyWith(person: value));
  });
}
}


/// @nodoc
mixin _$UnitMemberPersonModel {

 String get id; String get type; String get fullName; String? get nickname; String get gender; String? get birthDate; String? get phone; String? get addressId; String? get profileImageId;
/// Create a copy of UnitMemberPersonModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitMemberPersonModelCopyWith<UnitMemberPersonModel> get copyWith => _$UnitMemberPersonModelCopyWithImpl<UnitMemberPersonModel>(this as UnitMemberPersonModel, _$identity);

  /// Serializes this UnitMemberPersonModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitMemberPersonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.profileImageId, profileImageId) || other.profileImageId == profileImageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,fullName,nickname,gender,birthDate,phone,addressId,profileImageId);

@override
String toString() {
  return 'UnitMemberPersonModel(id: $id, type: $type, fullName: $fullName, nickname: $nickname, gender: $gender, birthDate: $birthDate, phone: $phone, addressId: $addressId, profileImageId: $profileImageId)';
}


}

/// @nodoc
abstract mixin class $UnitMemberPersonModelCopyWith<$Res>  {
  factory $UnitMemberPersonModelCopyWith(UnitMemberPersonModel value, $Res Function(UnitMemberPersonModel) _then) = _$UnitMemberPersonModelCopyWithImpl;
@useResult
$Res call({
 String id, String type, String fullName, String? nickname, String gender, String? birthDate, String? phone, String? addressId, String? profileImageId
});




}
/// @nodoc
class _$UnitMemberPersonModelCopyWithImpl<$Res>
    implements $UnitMemberPersonModelCopyWith<$Res> {
  _$UnitMemberPersonModelCopyWithImpl(this._self, this._then);

  final UnitMemberPersonModel _self;
  final $Res Function(UnitMemberPersonModel) _then;

/// Create a copy of UnitMemberPersonModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? fullName = null,Object? nickname = freezed,Object? gender = null,Object? birthDate = freezed,Object? phone = freezed,Object? addressId = freezed,Object? profileImageId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,addressId: freezed == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as String?,profileImageId: freezed == profileImageId ? _self.profileImageId : profileImageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UnitMemberPersonModel].
extension UnitMemberPersonModelPatterns on UnitMemberPersonModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitMemberPersonModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitMemberPersonModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitMemberPersonModel value)  $default,){
final _that = this;
switch (_that) {
case _UnitMemberPersonModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitMemberPersonModel value)?  $default,){
final _that = this;
switch (_that) {
case _UnitMemberPersonModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String fullName,  String? nickname,  String gender,  String? birthDate,  String? phone,  String? addressId,  String? profileImageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitMemberPersonModel() when $default != null:
return $default(_that.id,_that.type,_that.fullName,_that.nickname,_that.gender,_that.birthDate,_that.phone,_that.addressId,_that.profileImageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String fullName,  String? nickname,  String gender,  String? birthDate,  String? phone,  String? addressId,  String? profileImageId)  $default,) {final _that = this;
switch (_that) {
case _UnitMemberPersonModel():
return $default(_that.id,_that.type,_that.fullName,_that.nickname,_that.gender,_that.birthDate,_that.phone,_that.addressId,_that.profileImageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String fullName,  String? nickname,  String gender,  String? birthDate,  String? phone,  String? addressId,  String? profileImageId)?  $default,) {final _that = this;
switch (_that) {
case _UnitMemberPersonModel() when $default != null:
return $default(_that.id,_that.type,_that.fullName,_that.nickname,_that.gender,_that.birthDate,_that.phone,_that.addressId,_that.profileImageId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnitMemberPersonModel implements UnitMemberPersonModel {
  const _UnitMemberPersonModel({required this.id, required this.type, required this.fullName, this.nickname, required this.gender, this.birthDate, this.phone, this.addressId, this.profileImageId});
  factory _UnitMemberPersonModel.fromJson(Map<String, dynamic> json) => _$UnitMemberPersonModelFromJson(json);

@override final  String id;
@override final  String type;
@override final  String fullName;
@override final  String? nickname;
@override final  String gender;
@override final  String? birthDate;
@override final  String? phone;
@override final  String? addressId;
@override final  String? profileImageId;

/// Create a copy of UnitMemberPersonModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitMemberPersonModelCopyWith<_UnitMemberPersonModel> get copyWith => __$UnitMemberPersonModelCopyWithImpl<_UnitMemberPersonModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnitMemberPersonModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitMemberPersonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.profileImageId, profileImageId) || other.profileImageId == profileImageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,fullName,nickname,gender,birthDate,phone,addressId,profileImageId);

@override
String toString() {
  return 'UnitMemberPersonModel(id: $id, type: $type, fullName: $fullName, nickname: $nickname, gender: $gender, birthDate: $birthDate, phone: $phone, addressId: $addressId, profileImageId: $profileImageId)';
}


}

/// @nodoc
abstract mixin class _$UnitMemberPersonModelCopyWith<$Res> implements $UnitMemberPersonModelCopyWith<$Res> {
  factory _$UnitMemberPersonModelCopyWith(_UnitMemberPersonModel value, $Res Function(_UnitMemberPersonModel) _then) = __$UnitMemberPersonModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String fullName, String? nickname, String gender, String? birthDate, String? phone, String? addressId, String? profileImageId
});




}
/// @nodoc
class __$UnitMemberPersonModelCopyWithImpl<$Res>
    implements _$UnitMemberPersonModelCopyWith<$Res> {
  __$UnitMemberPersonModelCopyWithImpl(this._self, this._then);

  final _UnitMemberPersonModel _self;
  final $Res Function(_UnitMemberPersonModel) _then;

/// Create a copy of UnitMemberPersonModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? fullName = null,Object? nickname = freezed,Object? gender = null,Object? birthDate = freezed,Object? phone = freezed,Object? addressId = freezed,Object? profileImageId = freezed,}) {
  return _then(_UnitMemberPersonModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,nickname: freezed == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String?,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,addressId: freezed == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as String?,profileImageId: freezed == profileImageId ? _self.profileImageId : profileImageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
