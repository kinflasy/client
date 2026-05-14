import 'package:client/core/media/media_providers.dart';
import 'package:client/core/presentation/widgets/current_user_avatar_button.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  Widget buildApp(UserEntity user) {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: CurrentUserAvatarButton())),
    );
  }

  setUp(() {
    repository = _MockAuthRepository();
  });

  testWidgets('mostra imagem quando profileImageId existe', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const UserEntity(
          id: 'user-1',
          username: 'lisa',
          fullName: 'Lisa Silva',
          profileImageId: 'image-1',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('LS'), findsNothing);
  });

  testWidgets('mantem iniciais no fallback', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const UserEntity(
          id: 'user-1',
          username: 'lisa',
          fullName: 'Lisa Silva',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('LS'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
