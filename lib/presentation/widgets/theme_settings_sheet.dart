import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/theme/theme_cubit.dart';

void showThemeSettingsSheet(BuildContext context) {
  final navigator = Navigator.of(context);
  final themeCubit = context.read<ThemeCubit>();

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, state) {
            final current = state is ThemeLoaded
                ? state.themeMode
                : ThemeMode.system;

            final cs = Theme.of(context).colorScheme;

            void setTheme(ThemeMode mode) {
              navigator.pop();
              if (navigator.context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  themeCubit.setThemeMode(mode);
                });
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apariencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige el modo de tema',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _ThemeOption(
                  icon: Icons.brightness_auto_outlined,
                  label: 'Automático',
                  subtitle: 'Según el sistema del dispositivo',
                  selected: current == ThemeMode.system,
                  onTap: () => setTheme(ThemeMode.system),
                ),
                const SizedBox(height: 4),
                _ThemeOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Claro',
                  subtitle: 'Tema claro siempre',
                  selected: current == ThemeMode.light,
                  onTap: () => setTheme(ThemeMode.light),
                ),
                const SizedBox(height: 4),
                _ThemeOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Oscuro',
                  subtitle: 'Tema oscuro siempre',
                  selected: current == ThemeMode.dark,
                  onTap: () => setTheme(ThemeMode.dark),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => navigator.pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: cs.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
