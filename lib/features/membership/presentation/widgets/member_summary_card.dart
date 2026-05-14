import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/presentation/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class MemberSummaryCard extends StatelessWidget {
  const MemberSummaryCard({
    super.key,
    required this.fullName,
    required this.affiliation,
    required this.gender,
    this.birthDate,
    this.age,
    this.profileImageId,
    this.onTap,
  });

  final String fullName;
  final String affiliation;
  final String gender;
  final DateTime? birthDate;
  final int? age;
  final String? profileImageId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedAge = age ?? calculateAge(birthDate);
    final translatedAffiliation = translateAffiliation(affiliation);
    final subtitle = resolvedAge == null
        ? translatedAffiliation
        : '$translatedAffiliation · $resolvedAge anos';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: UserAvatar(
          displayName: fullName,
          radius: 20,
          profileImageId: profileImageId,
        ),
        title: Text(
          fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

int? calculateAge(DateTime? birthDate) {
  if (birthDate == null) return null;

  final now = DateTime.now();
  var age = now.year - birthDate.year;

  final hadBirthdayThisYear =
      now.month > birthDate.month ||
      (now.month == birthDate.month && now.day >= birthDate.day);

  if (!hadBirthdayThisYear) {
    age--;
  }

  return age < 0 ? null : age;
}

String translateAffiliation(String affiliation) {
  return switch (affiliation.toUpperCase()) {
    'MEMBER' => 'Membros',
    'CONGREGATED' => 'Congregados',
    'VISITOR' => 'Visitantes',
    _ => affiliation,
  };
}
