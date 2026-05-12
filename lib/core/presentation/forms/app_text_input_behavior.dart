import 'package:flutter/material.dart';

@immutable
class AppTextInputBehavior {
  const AppTextInputBehavior._({
    required this.textCapitalization,
    required this.autocorrect,
    required this.enableSuggestions,
  });

  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;

  static const nameLike = AppTextInputBehavior._(
    textCapitalization: TextCapitalization.words,
    autocorrect: true,
    enableSuggestions: true,
  );

  static const plain = AppTextInputBehavior._(
    textCapitalization: TextCapitalization.none,
    autocorrect: false,
    enableSuggestions: false,
  );

  static const longText = AppTextInputBehavior._(
    textCapitalization: TextCapitalization.sentences,
    autocorrect: true,
    enableSuggestions: true,
  );

  static const lowercaseId = AppTextInputBehavior._(
    textCapitalization: TextCapitalization.none,
    autocorrect: false,
    enableSuggestions: false,
  );

  static const uppercaseAcronym = AppTextInputBehavior._(
    textCapitalization: TextCapitalization.characters,
    autocorrect: false,
    enableSuggestions: false,
  );

  static const emailLike = AppTextInputBehavior._(
    textCapitalization: TextCapitalization.none,
    autocorrect: false,
    enableSuggestions: false,
  );
}
