import 'package:flutter/material.dart';

class AppColors {
  // Primária
  static const primary = Color(0xFF435E91);
  static const primaryDark = Color(0xFF1A2438);
  static const secondary = Color(0xFF7E97C7);
  static const secondaryLight = Color(0xFFB8C6E0);
  static const secondaryExtraLight = Color(0xFFD4DDEC);
  static const tertiary = Color(0xFFC37046);
  static const tertiaryLight = Color(0xFFE6C3B2);
  static const quaternary = Color(0xFF976849);
  static const quaternaryDark = Color(0xFF8B4C2D);

  // Neutras
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFE8E7EE);
  static const error = Color(0xFFA42832);
  static final inactiveBackground = Color.alphaBlend(
    primary.withValues(alpha: 0.12),
    surfaceContainerHigh,
  );

  // Texto
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
}
