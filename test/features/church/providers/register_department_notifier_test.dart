import 'package:client/core/errors/failure.dart';
import 'package:client/features/department/data/models/department_request_model.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:client/features/department/domain/repositories/department_repository.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockDepartmentRepository extends Mock implements DepartmentRepository {}

void main() {
  late _MockDepartmentRepository repository;
  late ProviderContainer container;

  const request = DepartmentRequestModel(
    name: 'Recepcao',
    slug: 'recepcao',
    type: 'MINISTRY',
  );

  setUp(() {
    repository = _MockDepartmentRepository();
    container = ProviderContainer(
      overrides: [departmentRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('create updates state to success when repository succeeds', () async {
    when(() => repository.createDepartment('unit-1', request)).thenAnswer(
      (_) async => const Right(
        DepartmentEntity(
          id: 'dep-1',
          name: 'Recepcao',
          slug: 'recepcao',
          type: 'MINISTRY',
        ),
      ),
    );

    final result = await container
        .read(createDepartmentProvider.notifier)
        .create('unit-1', request);

    expect(result.isRight(), isTrue);
    expect(container.read(createDepartmentProvider), const AsyncData<void>(null));
  });

  test('create updates state to error when repository fails', () async {
    when(() => repository.createDepartment('unit-1', request)).thenAnswer(
      (_) async => const Left(ValidationFailure('Nome ja cadastrado')),
    );

    final result = await container
        .read(createDepartmentProvider.notifier)
        .create('unit-1', request);

    expect(result.isLeft(), isTrue);
    final state = container.read(createDepartmentProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<ValidationFailure>());
  });
}
