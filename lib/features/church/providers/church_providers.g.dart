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
