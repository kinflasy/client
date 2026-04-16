import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/church/domain/entities/church_entity.dart';
import 'package:client/features/church/domain/entities/church_unit_entity.dart';
import 'package:flutter/material.dart';

class ChurchProfileIdentityCard extends StatelessWidget {
  const ChurchProfileIdentityCard({
    super.key,
    required this.unit,
    required this.fallbackChurch,
    required this.onOpenPublicProfile,
  });

  final ChurchUnitEntity unit;
  final ChurchEntity fallbackChurch;
  final VoidCallback onOpenPublicProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(unit, fallbackChurch),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${_displaySlug(unit, fallbackChurch)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onOpenPublicProfile,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

String _displayName(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final name = unit.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return fallbackChurch.name;
}

String _displaySlug(ChurchUnitEntity unit, ChurchEntity fallbackChurch) {
  final slug = unit.slug?.trim();
  if (slug != null && slug.isNotEmpty) return slug;
  return fallbackChurch.slug;
}
