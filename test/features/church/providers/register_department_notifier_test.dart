import 'package:client/core/errors/failure.dart';
import 'package:client/features/church/data/models/department_request_model.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/domain/repositories/church_department_repository.dart';
import 'package:client/features/church/providers/church_department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockChurchDepartmentRepository extends Mock
    implements ChurchDepartmentRepository {}

void main() {
  late _MockChurchDepartmentRepository repository;
  late ProviderContainer container;

  const request = DepartmentRequestModel(
    name: 'Recepcao',
    slug: 'recepcao',
    type: 'MINISTRY',
  );

  setUp(() {
    repository = _MockChurchDepartmentRepository();
    container = ProviderContainer(
      overrides: [
        churchDepartmentRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('create updates state to success when repository succeeds', () async {
    when(() => repository.createDepartment('unit-1', request)).thenAnswer(
      (_) async => const Right(
        ChurchDepartmentEntity(
          id: 'dep-1',
          name: 'Recepcao',
          slug: 'recepcao',
          type: 'MINISTRY',
        ),
      ),
    );

    final result = await container
        .read(registerDepartmentProvider.notifier)
        .create('unit-1', request);

    expect(result.isRight(), isTrue);
    expect(
      container.read(registerDepartmentProvider),
      const AsyncData<void>(null),
    );
  });

  test('create updates state to error when repository fails', () async {
    when(() => repository.createDepartment('unit-1', request)).thenAnswer(
      (_) async => const Left(ValidationFailure('Nome ja cadastrado')),
    );

    final result = await container
        .read(registerDepartmentProvider.notifier)
        .create('unit-1', request);

    expect(result.isLeft(), isTrue);
    final state = container.read(registerDepartmentProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<ValidationFailure>());
  });
}
