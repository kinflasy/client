import 'package:client/core/domain/enums/integration_type.dart';

class IntegrationRequestModel {
  const IntegrationRequestModel({
    required this.membershipId,
    this.type = IntegrationType.integrant,
  });

  final String membershipId;
  final IntegrationType type;

  Map<String, dynamic> toJson() => {
    'membershipId': membershipId,
    'type': type.name.toUpperCase(),
  };
}
