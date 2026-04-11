import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';

class SignUpUsecase {
  final AuthRepository _repository;
  SignUpUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String username,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
  }) => _repository.signUp(
    name: name,
    username: username,
    email: email,
    password: password,
    gender: gender,
    birthDate: birthDate,
  );
}
