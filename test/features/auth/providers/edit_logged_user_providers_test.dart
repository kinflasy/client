import 'dart:async';

import 'package:client/core/address/address_value.dart';
import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDio extends Mock implements Dio {}

void main() {
  final profile = LoggedUserProfileEntity(
    id: 'user-1',
    fullName: 'Lisa Silva',
    nickname: 'Lisa',
    email: 'lisa@example.com',
    phone: '(85) 99999-1111',
    gender: 'FEMALE',
    birthDate: DateTime(1998, 4, 9),
    address: const AddressValue(city: 'Fortaleza'),
  );

  test('initializes form state from detailed logged user profile', () {
    final state = createEditLoggedUserFormStateFromProfile(profile);

    expect(state.isInitialized, isTrue);
    expect(state.fullName, 'Lisa Silva');
    expect(state.nickname, 'Lisa');
    expect(state.email, 'lisa@example.com');
    expect(state.phone, '(85) 99999-1111');
    expect(state.address.city, 'Fortaleza');
  });

  test('updates fields incrementally', () {
    final updated = updateEditLoggedUserFormPersonalData(
      const EditLoggedUserFormState(),
      fullName: 'Novo Nome',
      email: 'novo@example.com',
    );

    expect(updated.fullName, 'Novo Nome');
    expect(updated.email, 'novo@example.com');
    expect(updated.isInitialized, isTrue);
  });

  test('normalizes optional blanks and empty address to null in payload', () {
    final request = buildUpdateLoggedUserRequest(
      EditLoggedUserFormState(
        fullName: 'Lisa Silva',
        nickname: '   ',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
        phone: ' ',
        email: '',
        address: AddressFormState(),
        isInitialized: true,
      ),
    );

    expect(request.nickname, isNull);
    expect(request.phone, isNull);
    expect(request.email, isNull);
    expect(request.address, isNull);
    expect(request.birthDate, '1998-04-09');
  });

  test('includes address in payload when any address field is filled', () {
    final request = buildUpdateLoggedUserRequest(
      EditLoggedUserFormState(
        fullName: 'Lisa Silva',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
        address: const AddressFormState(
          zip: ' 60000-000 ',
          country: ' Brasil ',
          state: ' CE ',
          city: ' Fortaleza ',
          neighborhood: ' Centro ',
          street: ' Rua Alfa ',
          number: ' 123 ',
          complement: ' Apto 4 ',
          reference: ' Próximo à praça ',
        ),
        isInitialized: true,
      ),
    );

    expect(request.address, isNotNull);
    expect(request.address!.zip, '60000-000');
    expect(request.address!.country, 'Brasil');
    expect(request.address!.state, 'CE');
    expect(request.address!.city, 'Fortaleza');
    expect(request.address!.neighborhood, 'Centro');
    expect(request.address!.street, 'Rua Alfa');
    expect(request.address!.number, '123');
    expect(request.address!.complement, 'Apto 4');
    expect(request.address!.reference, 'Próximo à praça');
  });

  test('resolved profile loads complete address from addressId', () async {
    final repository = _MockAuthRepository();
    final dio = _MockDio();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        dioClientProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);

    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => const UserEntity(id: 'user-1', username: 'lisa'));
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {
          'id': 'user-1',
          'fullName': 'Lisa Silva',
          'gender': 'FEMALE',
          'addressId': 'address-1',
        },
      ),
    );
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/addresses/address-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/addresses/address-1'),
        data: {
          'zip': '60000-000',
          'country': 'Brasil',
          'state': 'CE',
          'city': 'Fortaleza',
          'neighborhood': 'Centro',
          'street': 'Rua Alfa',
          'number': '123',
          'complement': 'Apto 4',
          'reference': 'Próximo à praça',
        },
      ),
    );

    final result = await container.read(
      editLoggedUserInitialDataProvider.future,
    );

    expect(result.address.zip, '60000-000');
    expect(result.address.country, 'Brasil');
    expect(result.address.state, 'CE');
    expect(result.address.city, 'Fortaleza');
    expect(result.address.neighborhood, 'Centro');
    expect(result.address.street, 'Rua Alfa');
    expect(result.address.number, '123');
    expect(result.address.complement, 'Apto 4');
    expect(result.address.reference, 'Próximo à praça');
  });

  test(
    'resolved profile uses detailed people data over minimal auth data',
    () async {
      final repository = _MockAuthRepository();
      final dio = _MockDio();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => const UserEntity(
          id: 'user-1',
          username: 'lisa',
          fullName: 'Auth Name',
          email: 'auth@example.com',
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
          data: {
            'id': 'user-1',
            'fullName': 'Lisa Silva',
            'gender': 'FEMALE',
            'birthDate': [1998, 4, 9],
            'phone': '85999991111',
            'email': 'profile@example.com',
          },
        ),
      );

      final result = await container.read(
        editLoggedUserInitialDataProvider.future,
      );

      expect(result.fullName, 'Lisa Silva');
      expect(result.email, 'profile@example.com');
      expect(result.phone, '85999991111');
      expect(result.birthDate, DateTime(1998, 4, 9));
    },
  );

  test('resolved profile uses empty address when address load fails', () async {
    final repository = _MockAuthRepository();
    final dio = _MockDio();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        dioClientProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);

    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => const UserEntity(id: 'user-1', username: 'lisa'));
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {
          'id': 'user-1',
          'fullName': 'Lisa Silva',
          'gender': 'FEMALE',
          'addressId': 'address-1',
        },
      ),
    );
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/addresses/address-1'),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/core/addresses/address-1'),
      ),
    );

    final result = await container.read(
      editLoggedUserInitialDataProvider.future,
    );

    expect(result.address.isBlank, isTrue);
  });

  test(
    'resolved profile preserves profileImageId from detailed profile',
    () async {
      final repository = _MockAuthRepository();
      final dio = _MockDio();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => const UserEntity(
          id: 'user-1',
          username: 'lisa',
          profileImageId: 'auth-image',
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
          data: {
            'id': 'user-1',
            'fullName': 'Lisa Silva',
            'gender': 'FEMALE',
            'profileImageId': 'profile-image',
          },
        ),
      );

      final result = await container.read(
        editLoggedUserInitialDataProvider.future,
      );

      expect(result.profileImageId, 'profile-image');
    },
  );

  test('resolved profile falls back to auth profileImageId', () async {
    final repository = _MockAuthRepository();
    final dio = _MockDio();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        dioClientProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);

    when(() => repository.getCurrentUser()).thenAnswer(
      (_) async => const UserEntity(
        id: 'user-1',
        username: 'lisa',
        fullName: 'Lisa Silva',
        gender: 'FEMALE',
        profileImageId: 'auth-image',
      ),
    );
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {'id': 'user-1', 'fullName': 'Lisa Silva', 'gender': 'FEMALE'},
      ),
    );

    final result = await container.read(
      editLoggedUserInitialDataProvider.future,
    );

    expect(result.profileImageId, 'auth-image');
  });

  test(
    'profile image update marks loading, data and reloads profile',
    () async {
      final repository = _MockAuthRepository();
      final dio = _MockDio();
      var profileLoads = 0;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          dioClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);

      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => const UserEntity(id: 'user-1', username: 'lisa'),
      );
      final completer = Completer<Either<Failure, UserEntity>>();
      when(
        () => repository.updateLoggedUserProfileImage('/tmp/perfil.png'),
      ).thenAnswer((_) => completer.future);
      when(
        () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
      ).thenAnswer((_) async {
        profileLoads++;
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
          data: {'id': 'user-1', 'fullName': 'Lisa Silva', 'gender': 'FEMALE'},
        );
      });

      final subscription = container.listen(
        editLoggedUserInitialDataProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(editLoggedUserInitialDataProvider.future);
      final submitSubscription = container.listen(
        loggedUserProfileImageSubmitProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(submitSubscription.close);

      final actionFuture = container
          .read(editLoggedUserActionsProvider)
          .updateLoggedUserProfileImage('/tmp/perfil.png');
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(loggedUserProfileImageSubmitProvider),
        const AsyncValue<void>.loading(),
      );

      completer.complete(
        const Right(
          UserEntity(
            id: 'user-1',
            username: 'lisa',
            profileImageId: 'image-123',
          ),
        ),
      );
      final result = await actionFuture;

      expect(result.isRight(), isTrue);
      expect(
        container.read(loggedUserProfileImageSubmitProvider),
        const AsyncValue<void>.data(null),
      );

      final profile = await container.read(
        editLoggedUserInitialDataProvider.future,
      );
      expect(profile.profileImageId, 'image-123');
      expect(profileLoads, 2);
    },
  );

  test('profile image update stores submit error on failure', () async {
    final repository = _MockAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => const UserEntity(id: 'user-1', username: 'lisa'));
    when(
      () => repository.updateLoggedUserProfileImage('/tmp/perfil.png'),
    ).thenAnswer(
      (_) async => const Left(NetworkFailure('Falha ao atualizar foto.')),
    );

    final result = await container
        .read(editLoggedUserActionsProvider)
        .updateLoggedUserProfileImage('/tmp/perfil.png');

    expect(result.isLeft(), isTrue);
    expect(
      container.read(loggedUserProfileImageSubmitProvider),
      isA<AsyncError<void>>(),
    );
  });

  test('profile image delete marks data and reloads auth profile', () async {
    final repository = _MockAuthRepository();
    final dio = _MockDio();
    var authLoads = 0;
    var profileLoads = 0;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        dioClientProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);

    when(() => repository.getCurrentUser()).thenAnswer((_) async {
      authLoads++;
      return const UserEntity(id: 'user-1', username: 'lisa');
    });
    when(
      () => repository.deleteLoggedUserProfileImage(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
    ).thenAnswer((_) async {
      profileLoads++;
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
        data: {'id': 'user-1', 'fullName': 'Lisa Silva', 'gender': 'FEMALE'},
      );
    });

    final subscription = container.listen(
      editLoggedUserInitialDataProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(editLoggedUserInitialDataProvider.future);

    final result = await container
        .read(editLoggedUserActionsProvider)
        .deleteLoggedUserProfileImage();

    expect(result.isRight(), isTrue);
    expect(
      container.read(loggedUserProfileImageSubmitProvider),
      const AsyncValue<void>.data(null),
    );

    await container.read(editLoggedUserInitialDataProvider.future);
    expect(authLoads, 2);
    expect(profileLoads, 2);
  });
}
