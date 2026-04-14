import 'package:client/features/church/presentation/screens/church_shared_widgets.dart';
import 'package:flutter/material.dart';

class ChurchProfileTopBar extends StatelessWidget {
  const ChurchProfileTopBar({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu),
          iconSize: 27,
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          color: Colors.white,
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        ),
        const SizedBox(width: 12),
        const Expanded(child: ChurchSearchRow()),
      ],
    );
  }
}
