import 'package:equatable/equatable.dart';

import '../../../membership/domain/entities/membership_entity.dart';
import 'church_entity.dart';
import 'church_unit_entity.dart';

class CurrentChurchProfileEntity extends Equatable {
  const CurrentChurchProfileEntity({
    required this.membership,
    required this.unit,
    required this.church,
  });

  final MembershipEntity membership;
  final ChurchUnitEntity unit;
  final ChurchEntity church;

  @override
  List<Object?> get props => [membership, unit, church];
}
