import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_request_model.freezed.dart';
part 'address_request_model.g.dart';

@freezed
abstract class AddressRequestModel with _$AddressRequestModel {
  const factory AddressRequestModel({
    String? zip,
    String? country,
    String? state,
    String? city,
    String? neighborhood,
    String? street,
    String? number,
    String? complement,
    String? reference,
  }) = _AddressRequestModel;

  factory AddressRequestModel.fromJson(Map<String, dynamic> json) =>
      _$AddressRequestModelFromJson(json);
}
