import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  const loggedUser = UserEntity(
    id: 'user-123',
    username: 'lisa',
    email: 'lisa@example.com',
    fullName: 'Lisa Silva',
  );

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('signIn publishes AsyncData with a valid authenticated user', () async {
    when(
      () => repository.signIn(email: 'lisa', password: 'secret'),
    ).thenAnswer((_) async => const Right(loggedUser));

    await container.read(authProvider.notifier).signIn('lisa', 'secret');

    final state = container.read(authProvider);
    expect(state, isA<AsyncData<UserEntity?>>());
    expect(state.value?.id, 'user-123');
    expect(state.value?.username, 'lisa');
    expect(state.value?.fullName, 'Lisa Silva');
    expect(state.value?.id, isNotEmpty);
  });

  test('signIn publishes AsyncError when repository returns failure', () async {
    when(
      () => repository.signIn(email: 'lisa', password: 'secret'),
    ).thenAnswer(
      (_) async => const Left(AuthFailure('Nao foi possivel validar a sessao')),
    );

    await container.read(authProvider.notifier).signIn('lisa', 'secret');

    final state = container.read(authProvider);
    expect(state.hasError, isTrue);
    expect(state.error, 'Nao foi possivel validar a sessao');
  });
}
