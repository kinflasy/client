import 'package:client/core/address/address_request_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'church_request_model.freezed.dart';
part 'church_request_model.g.dart';

@freezed
abstract class UnitRequestModel with _$UnitRequestModel {
  const factory UnitRequestModel({
    required String name,
    required String slug,
    required String phone,
    required String email,
    @Default('MAIN') String type,
    required AddressRequestModel address,
  }) = _UnitRequestModel;

  factory UnitRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UnitRequestModelFromJson(json);
}

@freezed
abstract class ChurchStarterRequestModel with _$ChurchStarterRequestModel {
  const factory ChurchStarterRequestModel({
    required String name,
    required String slug,
    String? acronym,
    String? phone,
    required String email,
    required UnitRequestModel unit,
  }) = _ChurchStarterRequestModel;

  factory ChurchStarterRequestModel.fromJson(Map<String, dynamic> json) =>
      _$ChurchStarterRequestModelFromJson(json);
}
