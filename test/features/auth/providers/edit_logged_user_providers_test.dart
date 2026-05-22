import 'dart:async';

import 'package:client/core/address/address_value.dart';
import 'package:client/core/address/address_form_state.dart';
import 'package:client/core/errors/failure.dart';
import 'package:client/core/media/media_providers.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/auth/data/datasources/auth_request_models.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const UpdateLoggedUserRequestModel(
        fullName: 'Fallback',
        gender: 'FEMALE',
        birthDate: '1998-04-09',
      ),
    );
  });

  final profile = LoggedUserProfileEntity(
    id: 'user-1',
    fullName: 'Lisa Silva',
    nickname: 'Lisa',
    email: 'lisa@example.com',
    phone: '(85) 99999-1111',
    gender: 'FEMALE',
    birthDate: DateTime(1998, 4, 9),
    address: const AddressValue(
      zip: '60000-000',
      country: 'Brasil',
      state: 'CE',
      city: 'Fortaleza',
      neighborhood: 'Centro',
      street: 'Rua Alfa',
      number: '123',
      complement: 'Apto 4',
      reference: 'PrÃ³ximo Ã  praÃ§a',
    ),
  );

  test('initializes personal data form state without address', () {
    final state = createEditLoggedUserPersonalDataFormStateFromProfile(profile);

    expect(state.isInitialized, isTrue);
    expect(state.fullName, 'Lisa Silva');
    expect(state.nickname, 'Lisa');
    expect(state.email, 'lisa@example.com');
    expect(state.phone, '(85) 99999-1111');
  });

  test('initializes address form state from profile address', () {
    final state = createEditLoggedUserAddressFormStateFromProfile(profile);

    expect(state.isInitialized, isTrue);
    expect(state.address.zip, '60000-000');
    expect(state.address.city, 'Fortaleza');
  });

  test('personal data request preserves current address when it exists', () {
    final request = buildUpdateLoggedUserPersonalDataRequest(
      EditLoggedUserPersonalDataFormState(
        fullName: 'Lisa Silva',
        nickname: '   ',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
        phone: ' ',
        email: '',
        isInitialized: true,
      ),
      profile,
    );

    expect(request.nickname, isNull);
    expect(request.phone, isNull);
    expect(request.email, isNull);
    expect(request.address, isNotNull);
    expect(request.address!.city, 'Fortaleza');
    expect(request.birthDate, '1998-04-09');
  });

  test('personal data request omits address when profile has no address', () {
    final request = buildUpdateLoggedUserPersonalDataRequest(
      EditLoggedUserPersonalDataFormState(
        fullName: 'Lisa Silva',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
        isInitialized: true,
      ),
      LoggedUserProfileEntity(
        id: 'user-1',
        fullName: 'Lisa Silva',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
      ),
    );

    expect(request.address, isNull);
  });

  test('address request preserves current required personal data', () {
    final request = buildUpdateLoggedUserAddressRequest(
      const EditLoggedUserAddressFormState(
        address: AddressFormState(city: 'Fortaleza'),
        isInitialized: true,
      ),
      profile,
    );

    expect(request.fullName, 'Lisa Silva');
    expect(request.nickname, 'Lisa');
    expect(request.gender, 'FEMALE');
    expect(request.birthDate, '1998-04-09');
    expect(request.phone, '85999991111');
    expect(request.email, 'lisa@example.com');
  });

  test('filled address request sends normalized AddressRequestModel', () {
    final request = buildUpdateLoggedUserAddressRequest(
      const EditLoggedUserAddressFormState(
        address: AddressFormState(
          zip: ' 60000-000 ',
          country: ' Brasil ',
          state: ' CE ',
          city: ' Fortaleza ',
          neighborhood: ' Centro ',
          street: ' Rua Alfa ',
          number: ' 123 ',
          complement: ' Apto 4 ',
          reference: ' PrÃ³ximo Ã  praÃ§a ',
        ),
        isInitialized: true,
      ),
      profile,
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
    expect(request.address!.reference, 'PrÃ³ximo Ã  praÃ§a');
  });

  test('empty address request sends non-null empty address to clear it', () {
    final request = buildUpdateLoggedUserAddressRequest(
      const EditLoggedUserAddressFormState(
        address: AddressFormState(),
        isInitialized: true,
      ),
      profile,
    );

    expect(request.address, isNotNull);
    expect(request.address!.zip, isNull);
    expect(request.address!.country, isNull);
    expect(request.address!.state, isNull);
    expect(request.address!.city, isNull);
    expect(request.address!.neighborhood, isNull);
    expect(request.address!.street, isNull);
    expect(request.address!.number, isNull);
    expect(request.address!.complement, isNull);
    expect(request.address!.reference, isNull);
  });

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

  testWidgets('personal data submit uses personal data submit provider', (
    tester,
  ) async {
    final repository = _MockAuthRepository();
    final completer = Completer<Either<Failure, UserEntity>>();

    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => const UserEntity(id: 'user-1', username: 'lisa'));
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: Consumer(
          builder: (context, ref, _) {
            widgetRef = ref;
            ref.watch(authProvider);
            ref.watch(editLoggedUserPersonalDataSubmitProvider);
            ref.watch(editLoggedUserAddressSubmitProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final request = buildUpdateLoggedUserPersonalDataRequest(
      EditLoggedUserPersonalDataFormState(
        fullName: 'Lisa Silva',
        gender: 'FEMALE',
        birthDate: DateTime(1998, 4, 9),
      ),
      profile,
    );
    final submitFuture = submitEditLoggedUserPersonalData(
      widgetRef,
      request: request,
    );
    await tester.pump();

    expect(
      widgetRef.read(editLoggedUserPersonalDataSubmitProvider).isLoading,
      isTrue,
    );
    expect(
      widgetRef.read(editLoggedUserAddressSubmitProvider).isLoading,
      isFalse,
    );

    completer.complete(const Right(UserEntity(id: 'user-1', username: 'lisa')));
    final result = await submitFuture;

    expect(result.isRight(), isTrue);
    expect(
      widgetRef.read(editLoggedUserPersonalDataSubmitProvider),
      const AsyncValue<void>.data(null),
    );
    verify(() => repository.updateLoggedUser(request)).called(1);
  });

  testWidgets('address submit uses address submit provider', (tester) async {
    final repository = _MockAuthRepository();
    final completer = Completer<Either<Failure, UserEntity>>();

    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => const UserEntity(id: 'user-1', username: 'lisa'));
    when(
      () => repository.updateLoggedUser(any()),
    ).thenAnswer((_) => completer.future);

    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: Consumer(
          builder: (context, ref, _) {
            widgetRef = ref;
            ref.watch(authProvider);
            ref.watch(editLoggedUserPersonalDataSubmitProvider);
            ref.watch(editLoggedUserAddressSubmitProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final request = buildUpdateLoggedUserAddressRequest(
      const EditLoggedUserAddressFormState(
        address: AddressFormState(city: 'Fortaleza'),
        isInitialized: true,
      ),
      profile,
    );
    final submitFuture = submitEditLoggedUserAddress(
      widgetRef,
      request: request,
    );
    await tester.pump();

    expect(widgetRef.read(editLoggedUserAddressSubmitProvider).isLoading, true);
    expect(
      widgetRef.read(editLoggedUserPersonalDataSubmitProvider).isLoading,
      isFalse,
    );

    completer.complete(const Right(UserEntity(id: 'user-1', username: 'lisa')));
    final result = await submitFuture;

    expect(result.isRight(), isTrue);
    expect(
      widgetRef.read(editLoggedUserAddressSubmitProvider),
      const AsyncValue<void>.data(null),
    );
    verify(() => repository.updateLoggedUser(request)).called(1);
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
    'profile image update marks loading, reloads profile and invalidates media',
    () async {
      final repository = _MockAuthRepository();
      final dio = _MockDio();
      var profileLoads = 0;
      final mediaLoads = <String, int>{};
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          dioClientProvider.overrideWithValue(dio),
          mediaImageUrlProvider.overrideWith((ref, imageId) async {
            mediaLoads[imageId] = (mediaLoads[imageId] ?? 0) + 1;
            return 'https://cdn.example/$imageId/${mediaLoads[imageId]}';
          }),
        ],
      );
      addTearDown(container.dispose);

      when(() => repository.getCurrentUser()).thenAnswer(
        (_) async => const UserEntity(
          id: 'user-1',
          username: 'lisa',
          profileImageId: 'old-image',
        ),
      );
      final completer = Completer<Either<Failure, UserEntity>>();
      when(
        () => repository.updateLoggedUserProfileImage('/tmp/perfil.png'),
      ).thenAnswer((_) => completer.future);
      when(
        () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
      ).thenAnswer((_) async {
        profileLoads++;
        final profileImageId = profileLoads == 1 ? 'old-image' : 'image-123';
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
          data: {
            'id': 'user-1',
            'fullName': 'Lisa Silva',
            'gender': 'FEMALE',
            'profileImageId': profileImageId,
          },
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
      final oldMediaSubscription = container.listen(
        mediaImageUrlProvider('old-image'),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(oldMediaSubscription.close);
      final newMediaSubscription = container.listen(
        mediaImageUrlProvider('image-123'),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(newMediaSubscription.close);
      await container.read(mediaImageUrlProvider('old-image').future);
      await container.read(mediaImageUrlProvider('image-123').future);

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
      await container.read(mediaImageUrlProvider('old-image').future);
      await container.read(mediaImageUrlProvider('image-123').future);
      expect(mediaLoads['old-image'], 2);
      expect(mediaLoads['image-123'], 2);
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

  test(
    'profile image delete marks data, reloads auth profile and invalidates media',
    () async {
      final repository = _MockAuthRepository();
      final dio = _MockDio();
      var authLoads = 0;
      var profileLoads = 0;
      final mediaLoads = <String, int>{};
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          dioClientProvider.overrideWithValue(dio),
          mediaImageUrlProvider.overrideWith((ref, imageId) async {
            mediaLoads[imageId] = (mediaLoads[imageId] ?? 0) + 1;
            return 'https://cdn.example/$imageId/${mediaLoads[imageId]}';
          }),
        ],
      );
      addTearDown(container.dispose);

      when(() => repository.getCurrentUser()).thenAnswer((_) async {
        authLoads++;
        return UserEntity(
          id: 'user-1',
          username: 'lisa',
          profileImageId: authLoads == 1 ? 'old-image' : null,
        );
      });
      when(
        () => repository.deleteLoggedUserProfileImage(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => dio.get<Map<String, dynamic>>('/v1/core/people/user-1'),
      ).thenAnswer((_) async {
        profileLoads++;
        final data = <String, dynamic>{
          'id': 'user-1',
          'fullName': 'Lisa Silva',
          'gender': 'FEMALE',
        };
        if (profileLoads == 1) {
          data['profileImageId'] = 'old-image';
        }
        return Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/v1/core/people/user-1'),
          data: data,
        );
      });

      final subscription = container.listen(
        editLoggedUserInitialDataProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(editLoggedUserInitialDataProvider.future);
      final mediaSubscription = container.listen(
        mediaImageUrlProvider('old-image'),
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(mediaSubscription.close);
      await container.read(mediaImageUrlProvider('old-image').future);

      final result = await container
          .read(editLoggedUserActionsProvider)
          .deleteLoggedUserProfileImage();

      expect(result.isRight(), isTrue);
      expect(
        container.read(loggedUserProfileImageSubmitProvider),
        const AsyncValue<void>.data(null),
      );

      await container.read(editLoggedUserInitialDataProvider.future);
      await container.read(mediaImageUrlProvider('old-image').future);
      expect(authLoads, 2);
      expect(profileLoads, 2);
      expect(mediaLoads['old-image'], 2);
    },
  );
}
