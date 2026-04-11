import 'package:fpdart/fpdart.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
  });

  Future<Either<Failure, void>> signOut();

  Future<UserEntity?> getCurrentUser();
}
