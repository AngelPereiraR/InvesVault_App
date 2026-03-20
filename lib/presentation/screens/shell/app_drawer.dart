import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/auth/auth_cubit.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _mintBg = Color(0xFFF2FBF4);
const _accentGreen = Color(0xFF52B788);

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final String userName =
        authState is AuthAuthenticated ? authState.name : '';
    final String userEmail =
        authState is AuthAuthenticated ? authState.email : '';

    return Drawer(
      backgroundColor: _mintBg,
      child: Column(
        children: [
          // ── Purple header ───────────────────────────────────────────
          _DrawerHeader(userName: userName, userEmail: userEmail),

          // ── Scrollable menu ─────────────────────────────────────────
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                // MENÚ INICIAL
                const _SectionHeader('Menú inicial'),
                const _DrawerTile(
                  icon: Icons.home_outlined,
                  label: 'Inicio',
                  route: '/dashboard',
                ),
                const _DrawerTile(
                  icon: Icons.warehouse_outlined,
                  label: 'Inventario',
                  route: '/warehouses',
                ),
                const _DrawerTile(
                  icon: Icons.store_outlined,
                  label: 'Tiendas',
                  route: '/stores',
                ),
                const _DrawerTile(
                  icon: Icons.label_outlined,
                  label: 'Marcas',
                  route: '/brands',
                ),
                const _DrawerTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Catálogo',
                  route: '/products',
                ),
                const _DrawerTile(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Lista de compra',
                  route: '/shopping-list',
                ),
                const _DrawerTile(
                  icon: Icons.history_outlined,
                  label: 'Historial de cambios',
                  route: '/stock-history',
                ),

                const _Divider(),

                // PRÓXIMAMENTE (datos)
                const _SectionHeader('Próximamente'),
                const _ComingSoonTile(
                    icon: Icons.upload_outlined, label: 'Importar datos'),
                const _ComingSoonTile(
                    icon: Icons.download_outlined, label: 'Exportar datos'),
                const _ComingSoonTile(
                    icon: Icons.delete_outline, label: 'Datos eliminados'),
                const _ComingSoonTile(
                    icon: Icons.backup_outlined, label: 'Copia de seguridad'),
                const _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'Configuración',
                  route: '/settings',
                ),

                const _Divider(),

                // SOPORTE (Próximamente)
                const _SectionHeader('Soporte · Próximamente'),
                const _ComingSoonTile(
                    icon: Icons.support_agent_outlined, label: 'Asistencia'),
                const _ComingSoonTile(icon: Icons.help_outline, label: 'Ayuda'),
                const _ComingSoonTile(
                    icon: Icons.newspaper_outlined, label: 'Noticias'),
                const _ComingSoonTile(
                    icon: Icons.lightbulb_outline, label: 'Sugerencias'),

                const _Divider(),

                // ACCIONES FINALES
                ListTile(
                  enabled: false,
                  leading:
                      Icon(Icons.restart_alt, color: Colors.blueGrey.shade300),
                  title: Text('Reiniciar',
                      style: TextStyle(color: Colors.blueGrey.shade400)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Próximamente',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _accentGreen)),
                  ),
                  onTap: null,
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar sesión',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<AuthCubit>().logout();
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String userName;
  final String userEmail;

  const _DrawerHeader({required this.userName, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _purple,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + app name row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                child: Image.asset('assets/logo.png', width: 44, height: 44),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('InvesVault',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                    Text('v1.0.6',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // User info
          Text(userName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(userEmail,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Tiles ────────────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final current = currentRouteName(context);
    final selected = current == route ||
        (route != '/dashboard' && current.startsWith(route));
    return ListTile(
      dense: true,
      leading: Icon(icon,
          size: 22, color: selected ? _purple : Colors.blueGrey.shade700),
      title: Text(label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? _purple : Colors.blueGrey.shade900,
          )),
      selected: selected,
      selectedTileColor: _mint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      horizontalTitleGap: 6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        Navigator.of(context).pop();
        if (!selected) {
          navigateToShellSection(
            context,
            route,
            mode: ShellNavigationMode.resetFromDashboard,
          );
        }
      },
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ComingSoonTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: Colors.blueGrey.shade300),
      title: Text(label,
          style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _accentGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Pronto',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _accentGreen)),
      ),
      horizontalTitleGap: 6,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 16, thickness: 0.5, indent: 16, endIndent: 16);
}
