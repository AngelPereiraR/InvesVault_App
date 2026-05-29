import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool isSearching;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.isSearching = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          readOnly: onTap != null,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
            suffixIcon: trailing ??
                (controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null),
          ),
          onChanged: onChanged,
        ),
        if (isSearching) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}
