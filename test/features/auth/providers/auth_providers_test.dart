import 'package:client/core/errors/failure.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeUpdateLoggedUserRequestModel extends Fake
    implements UpdateLoggedUserRequestModel {}

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
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  setUpAll(() {
    registerFallbackValue(_FakeUpdateLoggedUserRequestModel());
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
    when(() => repository.signIn(email: 'lisa', password: 'secret')).thenAnswer(
      (_) async => const Left(AuthFailure('Não foi possível validar a sessão')),
    );

    await container.read(authProvider.notifier).signIn('lisa', 'secret');

    final state = container.read(authProvider);
    expect(state.hasError, isTrue);
    expect(state.error, 'Não foi possível validar a sessão');
  });

  test(
    'signUp forwards gender and birthDate and publishes AsyncData',
    () async {
      final birthDate = DateTime(1998, 4, 9);

      when(
        () => repository.signUp(
          name: 'Lisa Silva',
          username: 'lisa',
          email: 'lisa@example.com',
          password: 'secret',
          gender: 'FEMALE',
          birthDate: birthDate,
        ),
      ).thenAnswer((_) async => const Right(loggedUser));

      await container
          .read(authProvider.notifier)
          .signUp(
            name: 'Lisa Silva',
            username: 'lisa',
            email: 'lisa@example.com',
            password: 'secret',
            gender: 'FEMALE',
            birthDate: birthDate,
          );

      final state = container.read(authProvider);
      expect(state, isA<AsyncData<UserEntity?>>());
      expect(state.value?.id, 'user-123');

      verify(
        () => repository.signUp(
          name: 'Lisa Silva',
          username: 'lisa',
          email: 'lisa@example.com',
          password: 'secret',
          gender: 'FEMALE',
          birthDate: birthDate,
        ),
      ).called(1);
    },
  );

  test('updateLoggedUser publishes updated authenticated user', () async {
    when(() => repository.updateLoggedUser(any())).thenAnswer(
      (_) async => const Right(
        UserEntity(
          id: 'user-123',
          username: 'lisa',
          fullName: 'Lisa Atualizada',
          nickname: 'Lili',
          email: 'novo@example.com',
        ),
      ),
    );

    final result = await container
        .read(authProvider.notifier)
        .updateLoggedUser(
          const UpdateLoggedUserRequestModel(
            fullName: 'Lisa Atualizada',
            nickname: 'Lili',
            gender: 'FEMALE',
            birthDate: '1998-04-09',
            email: 'novo@example.com',
          ),
        );

    expect(result.isRight(), isTrue);
    final state = container.read(authProvider);
    expect(state, isA<AsyncData<UserEntity?>>());
    expect(state.value?.fullName, 'Lisa Atualizada');
    expect(state.value?.nickname, 'Lili');
  });
}
