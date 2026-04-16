import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:client/features/church/presentation/widgets/church_shared_widgets.dart';
import 'package:flutter/material.dart';

class ChurchProfileCoverHeader extends StatelessWidget {
  const ChurchProfileCoverHeader({
    super.key,
    required this.unit,
    required this.fallbackChurch,
    this.topBar,
    this.showBackButton = false,
  });

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;
  final Widget? topBar;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final coverUrl = unit.coverUrl ?? fallbackChurch.coverUrl;
    final logoUrl = unit.logoUrl ?? fallbackChurch.logoUrl;
    final displayName = _displayName(unit, fallbackChurch);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 168,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F4C81), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: coverUrl == null
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x22000000), Color(0x00000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              : Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
        ),
        if (showBackButton) const ChurchFloatingBackButton(),
        if (topBar != null)
          Positioned(top: 10, left: 16, right: 16, child: topBar!),
        Positioned(
          bottom: -58,
          child: CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.surface,
            child: CircleAvatar(
              radius: 58,
              backgroundColor: const Color(0xFFE8F0FE),
              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
              child: logoUrl == null
                  ? Text(
                      churchInitials(displayName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

String _displayName(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final name = unit.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return fallbackChurch.name;
}
