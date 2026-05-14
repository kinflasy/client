import 'package:client/core/config/theme/app_colors.dart';
import 'package:client/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChurchFloatingBackButton extends StatelessWidget {
  const ChurchFloatingBackButton({super.key});

  static const buttonKey = ValueKey('church-floating-back-button');

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 4,
      child: IconButton(
        key: buttonKey,
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class ChurchSearchRow extends StatelessWidget {
  const ChurchSearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        SizedBox(
          height: 35,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: TextField(
              readOnly: true,
              textAlignVertical: TextAlignVertical.center,
              onTap: () => context.pushNamed(AppRoutes.churchSearchName),
              decoration: InputDecoration(
                hintText: 'Pesquisar igreja',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 16),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.60),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String churchInitials(String name) {
  return name
      .split(' ')
      .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
      .take(2)
      .join();
}
