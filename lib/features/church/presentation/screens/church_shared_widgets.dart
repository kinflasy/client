import 'package:flutter/material.dart';

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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Busca de igrejas em breve.')),
                );
              },
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
