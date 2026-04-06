import 'package:equatable/equatable.dart';

import 'church_entity.dart';
import 'church_unit_entity.dart';

class PublicChurchUnitProfileEntity extends Equatable {
  const PublicChurchUnitProfileEntity({
    required this.unit,
    required this.church,
    required this.relatedUnits,
  });

  final ChurchUnitEntity unit;
  final ChurchEntity church;
  final List<ChurchUnitEntity> relatedUnits;

  @override
  List<Object?> get props => [unit, church, relatedUnits];
}
