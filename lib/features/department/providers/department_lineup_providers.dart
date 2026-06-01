import 'package:client/core/errors/failure.dart';
import 'package:client/core/utils/string_utils.dart';
import 'package:client/features/department/data/models/lineup_item_request_model.dart';
import 'package:client/features/department/data/models/lineup_request_model.dart';
import 'package:client/features/department/data/models/role_request_model.dart';
import 'package:client/features/department/domain/entities/lineup_entity.dart';
import 'package:client/features/department/domain/entities/lineup_item_entity.dart';
import 'package:client/features/department/domain/entities/role_entity.dart';
import 'package:client/features/department/providers/department_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

class FilteredRolesRequest extends Equatable {
  const FilteredRolesRequest({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

class LineupItemMutationRequest extends Equatable {
  const LineupItemMutationRequest({
    required this.lineupId,
    this.itemId,
    this.departmentId,
  });

  final String lineupId;
  final String? itemId;
  final String? departmentId;

  @override
  List<Object?> get props => [lineupId, itemId, departmentId];
}

final rolesProvider = FutureProvider<List<RoleEntity>>((ref) async {
  final result = await ref.read(departmentRepositoryProvider).getRoles();

  return result.fold((failure) => throw failure, (roles) {
    return [...roles]..sort(_compareRolesByName);
  });
});

final filteredRolesProvider = FutureProvider.family<List<RoleEntity>, String>((
  ref,
  query,
) async {
  final roles = await ref.watch(rolesProvider.future);
  final normalizedQuery = normalizeSearchTerm(query);

  if (normalizedQuery.isEmpty) return roles;

  return roles.where((role) {
    return normalizeSearchTerm(role.name).contains(normalizedQuery);
  }).toList();
});

final departmentLineupsProvider =
    FutureProvider.family<List<LineupEntity>, String>((
      ref,
      departmentId,
    ) async {
      final result = await ref
          .read(departmentRepositoryProvider)
          .getDepartmentLineups(departmentId);

      return result.fold((failure) => throw failure, (lineups) {
        return [...lineups]..sort(_compareLineupsByName);
      });
    });

final lineupWithItemsProvider = FutureProvider.family<LineupEntity, String>((
  ref,
  lineupId,
) async {
  final result = await ref
      .read(departmentRepositoryProvider)
      .getLineupWithItems(lineupId);

  return result.fold((failure) => throw failure, (lineup) => lineup);
});

final lineupItemsProvider =
    FutureProvider.family<List<LineupItemEntity>, String>((
      ref,
      lineupId,
    ) async {
      final result = await ref
          .read(departmentRepositoryProvider)
          .getLineupItems(lineupId);

      return result.fold((failure) => throw failure, (items) => items);
    });

final lineupMutationVersionProvider =
    NotifierProvider<LineupMutationVersionNotifier, int>(
      LineupMutationVersionNotifier.new,
    );

class LineupMutationVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final roleActionsProvider =
    NotifierProvider<RoleActionsNotifier, AsyncValue<void>>(
      RoleActionsNotifier.new,
    );

final lineupActionsProvider =
    NotifierProvider<LineupActionsNotifier, AsyncValue<void>>(
      LineupActionsNotifier.new,
    );

final lineupItemActionsProvider =
    NotifierProvider<LineupItemActionsNotifier, AsyncValue<void>>(
      LineupItemActionsNotifier.new,
    );

class RoleActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, RoleEntity>> create(RoleRequestModel request) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .createRole(request);
    if (result.isRight()) {
      ref.invalidate(rolesProvider);
    }
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result;
  }
}

class LineupActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, LineupEntity>> create({
    required String departmentId,
    required LineupRequestModel request,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .createDepartmentLineup(departmentId, request);
    _invalidateAfterLineupMutation(
      departmentId: departmentId,
      shouldInvalidate: result.isRight(),
    );
    state = _stateFromResult(result);
    return result;
  }

  Future<Either<Failure, LineupEntity>> update({
    required String departmentId,
    required String lineupId,
    required LineupRequestModel request,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .updateLineup(lineupId, request);
    _invalidateAfterLineupMutation(
      departmentId: departmentId,
      lineupId: lineupId,
      shouldInvalidate: result.isRight(),
    );
    state = _stateFromResult(result);
    return result;
  }

  Future<Either<Failure, Unit>> delete({
    required String departmentId,
    required String lineupId,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .deleteLineup(lineupId);
    _invalidateAfterLineupMutation(
      departmentId: departmentId,
      lineupId: lineupId,
      shouldInvalidate: result.isRight(),
    );
    state = _stateFromResult(result);
    return result;
  }

  void _invalidateAfterLineupMutation({
    required String departmentId,
    String? lineupId,
    required bool shouldInvalidate,
  }) {
    if (!shouldInvalidate) return;

    ref.invalidate(departmentLineupsProvider(departmentId));
    ref.read(lineupMutationVersionProvider.notifier).bump();
    if (lineupId != null) {
      ref.invalidate(lineupWithItemsProvider(lineupId));
      ref.invalidate(lineupItemsProvider(lineupId));
    }
  }
}

class LineupItemActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Either<Failure, LineupItemEntity>> create({
    required String lineupId,
    required LineupItemRequestModel request,
    String? departmentId,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .createLineupItem(lineupId, request);
    _invalidateAfterItemMutation(
      lineupId: lineupId,
      departmentId: departmentId,
      shouldInvalidate: result.isRight(),
    );
    state = _stateFromResult(result);
    return result;
  }

  Future<Either<Failure, LineupItemEntity>> update({
    required String lineupId,
    required String itemId,
    required LineupItemUpdateRequestModel request,
    String? departmentId,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .updateLineupItem(itemId, request);
    _invalidateAfterItemMutation(
      lineupId: lineupId,
      departmentId: departmentId,
      shouldInvalidate: result.isRight(),
    );
    state = _stateFromResult(result);
    return result;
  }

  Future<Either<Failure, Unit>> delete({
    required String lineupId,
    required String itemId,
    String? departmentId,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(departmentRepositoryProvider)
        .deleteLineupItem(itemId);
    _invalidateAfterItemMutation(
      lineupId: lineupId,
      departmentId: departmentId,
      shouldInvalidate: result.isRight(),
    );
    state = _stateFromResult(result);
    return result;
  }

  void _invalidateAfterItemMutation({
    required String lineupId,
    required String? departmentId,
    required bool shouldInvalidate,
  }) {
    if (!shouldInvalidate) return;

    ref.invalidate(lineupWithItemsProvider(lineupId));
    ref.invalidate(lineupItemsProvider(lineupId));
    ref.read(lineupMutationVersionProvider.notifier).bump();
    if (departmentId != null && departmentId.isNotEmpty) {
      ref.invalidate(departmentLineupsProvider(departmentId));
    }
  }
}

int _compareRolesByName(RoleEntity a, RoleEntity b) => a.name.compareTo(b.name);

int _compareLineupsByName(LineupEntity a, LineupEntity b) {
  return a.name.compareTo(b.name);
}

AsyncValue<void> _stateFromResult(Either<Failure, Object?> result) {
  return result.fold(
    (failure) => AsyncError(failure, StackTrace.current),
    (_) => const AsyncData(null),
  );
}
