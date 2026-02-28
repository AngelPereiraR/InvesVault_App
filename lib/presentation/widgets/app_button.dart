import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, danger, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(onPressed: loading ? null : onPressed, child: child);
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(onPressed: loading ? null : onPressed, child: child);
        break;
      case AppButtonVariant.danger:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: loading ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(onPressed: loading ? null : onPressed, child: child);
        break;
    }

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
