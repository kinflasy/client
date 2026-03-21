import 'package:freezed_annotation/freezed_annotation.dart';

part 'church_model.freezed.dart';
part 'church_model.g.dart';

@freezed
abstract class UnitModel with _$UnitModel {
  const factory UnitModel({
    required String id,
    required String name,
    required String slug,
    required String email,
    required String phone,
    required String type,
    required String churchId,
    required String addressId,
  }) = _UnitModel;

  factory UnitModel.fromJson(Map<String, dynamic> json) =>
      _$UnitModelFromJson(json);
}

@freezed
abstract class ChurchStarterModel with _$ChurchStarterModel {
  const factory ChurchStarterModel({
    required String id,
    required String name,
    required String slug,
    String? acronym,
    String? phone,
    required String email,
    required UnitModel unit,
  }) = _ChurchStarterModel;

  factory ChurchStarterModel.fromJson(Map<String, dynamic> json) =>
      _$ChurchStarterModelFromJson(json);
}