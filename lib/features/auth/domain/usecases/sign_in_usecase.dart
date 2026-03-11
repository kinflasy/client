import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';

class SignInUsecase {
  final AuthRepository _repository;
  SignInUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) => _repository.signIn(email: email, password: password);
}