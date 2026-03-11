import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';

class SignOutUsecase {
  final AuthRepository _repository;
  SignOutUsecase(this._repository);

  Future<Either<Failure, void>> call() => _repository.signOut();
}