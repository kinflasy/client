import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/features/department/domain/entities/department_entity.dart';
import 'package:flutter/material.dart';

class DepartmentCard extends StatelessWidget {
  const DepartmentCard({
    super.key,
    required this.department,
    this.onTap,
  });

  final DepartmentEntity department;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F0FE),
          child: Icon(
            department.type == 'ADMINISTRATIVE'
                ? Icons.admin_panel_settings_outlined
                : Icons.groups_3_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          department.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _buildSubtitle(department),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

String _buildSubtitle(DepartmentEntity department) {
  final slug = department.slug;
  if (slug != null && slug.isNotEmpty) {
    return '@$slug';
  }

  return translateDepartmentType(department.type);
}

String translateDepartmentType(String? type) {
  return switch (type?.toUpperCase()) {
    'ADMINISTRATIVE' => 'Administrativo',
    'MINISTRY' => 'Departamento',
    _ => 'Departamento',
  };
}
