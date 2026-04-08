import 'package:client/core/presentation/widgets/current_user_avatar_button.dart';
import 'package:client/features/church/presentation/screens/church_shared_widgets.dart';
import 'package:flutter/material.dart';

class ChurchProfileTopBar extends StatelessWidget {
  const ChurchProfileTopBar({super.key, this.onAvatarTap});

  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CurrentUserAvatarButton(onTap: onAvatarTap),
        const SizedBox(width: 12),
        const Expanded(child: ChurchSearchRow()),
      ],
    );
  }
}
