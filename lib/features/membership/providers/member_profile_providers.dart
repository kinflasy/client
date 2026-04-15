import 'dart:async';

import 'package:client/core/errors/failure.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/features/church/domain/entities/church_department_entity.dart';
import 'package:client/features/church/providers/church_providers.dart';
import 'package:client/features/membership/data/datasources/member_profile_api.dart';
import 'package:client/features/membership/data/repositories/member_profile_repository_impl.dart';
import 'package:client/features/membership/domain/entities/member_profile_entity.dart';
import 'package:client/features/membership/domain/repositories/member_profile_repository.dart';
import 'package:client/features/membership/providers/unit_member_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final memberProfileApiProvider = Provider<MemberProfileApi>(
  (ref) => MemberProfileApi(ref.watch(dioClientProvider)),
);

final memberProfileRepositoryProvider = Provider<MemberProfileRepository>(
  (ref) => MemberProfileRepositoryImpl(ref.watch(memberProfileApiProvider)),
);

final memberProfileProvider =
    FutureProvider.family<MemberProfileEntity, String>((ref, personId) async {
      final activeMembership = await ref.watch(activeMembershipProvider.future);
      final unitId = activeMembership?.unitId;
      if (unitId == null || unitId.isEmpty) {
        throw const NotFoundFailure('Nenhuma unidade ativa encontrada.');
      }

      return resolveMemberProfile(
        personId: personId,
        unitId: unitId,
        repository: ref.read(memberProfileRepositoryProvider),
        fetchDepartments: () async =>
            ref.read(churchDepartmentsProvider(unitId).future),
      );
    });

Future<MemberProfileEntity> resolveMemberProfile({
  required String personId,
  required String unitId,
  required MemberProfileRepository repository,
  required Future<List<ChurchDepartmentEntity>> Function() fetchDepartments,
}) async {
  final personResult = await repository.getPersonProfile(personId);
  final person = personResult.fold(
    (failure) => throw failure,
    (value) => value,
  );

  final membershipResult = await repository.getActiveMembership(
    unitId: unitId,
    personId: personId,
  );
  final membership = membershipResult.fold(
    (failure) => throw failure,
    (value) => value,
  );

  final addressFuture = _loadAddress(repository, person.addressId);
  final integrationsFuture = _combineIntegrations(
    repository: repository,
    membershipId: membership.id,
    fetchDepartments: fetchDepartments,
  );

  final address = await addressFuture;
  final integrations = await integrationsFuture;

  return MemberProfileEntity(
    personId: person.id,
    membershipId: membership.id,
    personType: person.type,
    fullName: person.fullName,
    nickname: person.nickname,
    gender: person.gender,
    birthDate: person.birthDate,
    age: person.age ?? calculateAge(person.birthDate),
    phone: person.phone,
    email: person.email,
    address: address?.toValue().format(),
    addressDetails: address,
    affiliation: membership.affiliation,
    entryDate: membership.entryDate != null
        ? DateTime.tryParse(membership.entryDate!)
        : null,
    integrations: integrations,
  );
}

Future<AddressDetailsEntity?> _loadAddress(
  MemberProfileRepository repository,
  String? addressId,
) async {
  if (addressId == null || addressId.isEmpty) return null;
  final result = await repository.getAddress(addressId);
  return result.fold((_) => null, (address) => address.toEntity());
}

Future<List<ChurchDepartmentEntity>> _loadDepartments(
  Future<List<ChurchDepartmentEntity>> Function() fetchDepartments,
) async {
  try {
    return await fetchDepartments();
  } catch (_) {
    return const [];
  }
}

Future<List<MemberProfileIntegrationEntity>> _combineIntegrations({
  required MemberProfileRepository repository,
  required String membershipId,
  required Future<List<ChurchDepartmentEntity>> Function() fetchDepartments,
}) async {
  final integrationsResult = await repository.getIntegrations(membershipId);
  final integrations = integrationsResult.fold(
    (_) => const [],
    (value) => value,
  );
  if (integrations.isEmpty) return const [];

  final departments = await _loadDepartments(fetchDepartments);
  final departmentsById = {
    for (final department in departments) department.id: department,
  };

  return integrations.map((integration) {
    final department = departmentsById[integration.departmentId];
    return MemberProfileIntegrationEntity(
      departmentId: integration.departmentId,
      departmentName: department?.name ?? 'Departamento',
      departmentType: department?.type ?? integration.departmentType,
      integrationType: integration.integrationType,
    );
  }).toList();
}
