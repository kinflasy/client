import 'package:client/core/media/media_providers.dart';
import 'package:client/features/auth/domain/entities/logged_user_profile_entity.dart';
import 'package:client/features/auth/domain/entities/user_entity.dart';
import 'package:client/features/auth/providers/edit_logged_user_providers.dart';
import 'package:client/features/menu/presentation/widgets/menu_user_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(UserEntity user) {
    return ProviderScope(
      overrides: [
        mediaImageUrlProvider.overrideWith(
          (ref, imageId) async => 'https://cdn.example/$imageId.png',
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: MenuUserHeaderContent(user: user)),
      ),
    );
  }

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

    expect(find.text('Lisa Silva'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('LS'), findsNothing);
  });

  testWidgets('usa imagem atualizada do perfil detalhado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaImageUrlProvider.overrideWith(
            (ref, imageId) async => 'https://cdn.example/$imageId.png',
          ),
          editLoggedUserInitialDataProvider.overrideWith(
            (ref) async => const LoggedUserProfileEntity(
              id: 'user-1',
              fullName: 'Lisa Silva',
              gender: 'FEMALE',
              profileImageId: 'updated-image',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MenuUserHeader(
              authState: AsyncValue.data(
                UserEntity(
                  id: 'user-1',
                  username: 'lisa',
                  fullName: 'Lisa Silva',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('LS'), findsNothing);
  });
}
