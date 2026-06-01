import 'package:flutter/material.dart';

class AppColors {
  // Primária
  static const primary = Color(0xFF435E91);

  // Neutras
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFE8E7EE);
  static const error = Color(0xFFD93025);
  static final inactiveBackground = Color.alphaBlend(
    primary.withValues(alpha: 0.12),
    surfaceContainerHigh,
  );

  // Texto
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
}
