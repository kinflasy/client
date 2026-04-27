// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateChurchNotifier)
final createChurchProvider = CreateChurchNotifierProvider._();

final class CreateChurchNotifierProvider
    extends $NotifierProvider<CreateChurchNotifier, AsyncValue<ChurchEntity?>> {
  CreateChurchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createChurchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createChurchNotifierHash();

  @$internal
  @override
  CreateChurchNotifier create() => CreateChurchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ChurchEntity?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ChurchEntity?>>(value),
    );
  }
}

String _$createChurchNotifierHash() =>
    r'1632265002be512e68029adecd239b275c7a0200';

abstract class _$CreateChurchNotifier
    extends $Notifier<AsyncValue<ChurchEntity?>> {
  AsyncValue<ChurchEntity?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ChurchEntity?>, AsyncValue<ChurchEntity?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChurchEntity?>, AsyncValue<ChurchEntity?>>,
              AsyncValue<ChurchEntity?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(JoinChurchUnitNotifier)
final joinChurchUnitProvider = JoinChurchUnitNotifierProvider._();

final class JoinChurchUnitNotifierProvider
    extends $NotifierProvider<JoinChurchUnitNotifier, AsyncValue<void>> {
  JoinChurchUnitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'joinChurchUnitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$joinChurchUnitNotifierHash();

  @$internal
  @override
  JoinChurchUnitNotifier create() => JoinChurchUnitNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$joinChurchUnitNotifierHash() =>
    r'6f36c9f693ea6d59944e828471e0bc2b67512557';

abstract class _$JoinChurchUnitNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
