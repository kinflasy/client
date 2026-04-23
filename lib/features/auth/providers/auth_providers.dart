import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/storage/secure_storage.dart';
import 'package:client/features/auth/data/datasources/auth_api.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:client/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:client/features/auth/domain/usecases/sign_up_usecase.dart';

part 'auth_providers.g.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
  ),
);

final signInUsecaseProvider = Provider(
  (ref) => SignInUsecase(ref.watch(authRepositoryProvider)),
);

final signUpUsecaseProvider = Provider(
  (ref) => SignUpUsecase(ref.watch(authRepositoryProvider)),
);

final signOutUsecaseProvider = Provider(
  (ref) => SignOutUsecase(ref.watch(authRepositoryProvider)),
);

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<UserEntity?> build() async {
    // Ao iniciar o app, verifica se há sessão ativa
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> signIn(String username, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signInUsecaseProvider)
        .call(email: username, password: password);
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (user) => state = AsyncData(user),
    );
  }

  Future<void> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
    required String gender,
    required DateTime birthDate,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signUpUsecaseProvider)
        .call(
          name: name,
          username: username,
          email: email,
          password: password,
          gender: gender,
          birthDate: birthDate,
        );
    result.fold(
      (failure) => state = AsyncError(failure.message, StackTrace.current),
      (user) => state = AsyncData(user),
    );
  }

  Future<void> signOut() async {
    await ref.read(signOutUsecaseProvider).call();
    state = const AsyncData(null);
  }

  Future<Either<Failure, UserEntity>> updateLoggedUser(
    UpdateLoggedUserRequestModel request,
  ) async {
    final previousState = state;
    final result = await ref
        .read(authRepositoryProvider)
        .updateLoggedUser(request);

    result.fold(
      (_) => state = previousState,
      (user) => state = AsyncData(user),
    );

    return result;
  }
}

// Alias semântico para o go_router observar
final authStateProvider = authProvider;
