import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../entities/church_unit_entity.dart';

abstract class ChurchUnitRepository {
  Future<Either<Failure, ChurchUnitEntity>> getUnitById(String id);
  Future<Either<Failure, List<ChurchUnitEntity>>> getUnitsByChurchId(
    String churchId,
  );
  Future<Either<Failure, void>> joinUnit(String unitId, String affiliation);
}
