import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/church_entity.dart';
import '../../data/models/church_request_model.dart';

abstract class ChurchRepository {
  Future<Either<Failure, ChurchEntity>> createChurch(
    ChurchStarterRequestModel request,
  );

  Future<Either<Failure, ChurchEntity>> getChurchById(String id);

  Future<Either<Failure, List<ChurchEntity>>> searchChurches(String term);
}
