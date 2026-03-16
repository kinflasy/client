// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'membership_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MembershipModel {

 String get id; String get unitId; String get affiliation;
/// Create a copy of MembershipModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipModelCopyWith<MembershipModel> get copyWith => _$MembershipModelCopyWithImpl<MembershipModel>(this as MembershipModel, _$identity);

  /// Serializes this MembershipModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MembershipModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.affiliation, affiliation) || other.affiliation == affiliation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,affiliation);

@override
String toString() {
  return 'MembershipModel(id: $id, unitId: $unitId, affiliation: $affiliation)';
}


}

/// @nodoc
abstract mixin class $MembershipModelCopyWith<$Res>  {
  factory $MembershipModelCopyWith(MembershipModel value, $Res Function(MembershipModel) _then) = _$MembershipModelCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, String affiliation
});




}
/// @nodoc
class _$MembershipModelCopyWithImpl<$Res>
    implements $MembershipModelCopyWith<$Res> {
  _$MembershipModelCopyWithImpl(this._self, this._then);

  final MembershipModel _self;
  final $Res Function(MembershipModel) _then;

/// Create a copy of MembershipModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? affiliation = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,affiliation: null == affiliation ? _self.affiliation : affiliation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MembershipModel].
extension MembershipModelPatterns on MembershipModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MembershipModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MembershipModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MembershipModel value)  $default,){
final _that = this;
switch (_that) {
case _MembershipModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MembershipModel value)?  $default,){
final _that = this;
switch (_that) {
case _MembershipModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  String affiliation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MembershipModel() when $default != null:
return $default(_that.id,_that.unitId,_that.affiliation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  String affiliation)  $default,) {final _that = this;
switch (_that) {
case _MembershipModel():
return $default(_that.id,_that.unitId,_that.affiliation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  String affiliation)?  $default,) {final _that = this;
switch (_that) {
case _MembershipModel() when $default != null:
return $default(_that.id,_that.unitId,_that.affiliation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MembershipModel implements MembershipModel {
  const _MembershipModel({required this.id, required this.unitId, this.affiliation = 'VISITOR'});
  factory _MembershipModel.fromJson(Map<String, dynamic> json) => _$MembershipModelFromJson(json);

@override final  String id;
@override final  String unitId;
@override@JsonKey() final  String affiliation;

/// Create a copy of MembershipModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipModelCopyWith<_MembershipModel> get copyWith => __$MembershipModelCopyWithImpl<_MembershipModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MembershipModel&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.affiliation, affiliation) || other.affiliation == affiliation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,unitId,affiliation);

@override
String toString() {
  return 'MembershipModel(id: $id, unitId: $unitId, affiliation: $affiliation)';
}


}

/// @nodoc
abstract mixin class _$MembershipModelCopyWith<$Res> implements $MembershipModelCopyWith<$Res> {
  factory _$MembershipModelCopyWith(_MembershipModel value, $Res Function(_MembershipModel) _then) = __$MembershipModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, String affiliation
});




}
/// @nodoc
class __$MembershipModelCopyWithImpl<$Res>
    implements _$MembershipModelCopyWith<$Res> {
  __$MembershipModelCopyWithImpl(this._self, this._then);

  final _MembershipModel _self;
  final $Res Function(_MembershipModel) _then;

/// Create a copy of MembershipModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? affiliation = null,}) {
  return _then(_MembershipModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,affiliation: null == affiliation ? _self.affiliation : affiliation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
