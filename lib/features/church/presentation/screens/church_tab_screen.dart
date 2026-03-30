import 'package:client/features/church/presentation/screens/church_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChurchTabScreen extends ConsumerWidget {
  const ChurchTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const ChurchProfileScreen();
}
