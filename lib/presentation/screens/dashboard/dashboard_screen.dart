import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';
import '../warehouses/warehouse_list_screen.dart' show showWarehouseDialog;

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _accentGreen = Color(0xFF52B788);
const _white = Color(0xFFFFFFFF);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _scrollCtrl = ScrollController();
  final _lowStockKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToLowStock() {
    final ctx = _lowStockKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const LoadingIndicator(message: 'Cargando…');
        }
        if (state is DashboardError) {
          return ErrorView(
            message: state.message,
            onRetry: () => context.read<DashboardCubit>().load(),
          );
        }
        if (state is! DashboardLoaded) return const SizedBox();

        return RefreshIndicator(
          onRefresh: () => context.read<DashboardCubit>().refresh(),
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── 3 STAT BUTTONS ───────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatButton(
                      icon: Icons.warning_amber_rounded,
                      label: 'Bajo stock',
                      value: '${state.lowStockCount}',
                      color: state.lowStockCount > 0
                          ? Colors.red.shade600
                          : _accentGreen,
                      onTap: state.lowStockCount > 0
                          ? _scrollToLowStock
                          : () {},
                    ),
                    const SizedBox(width: 10),
                    _StatButton(
                      icon: Icons.inventory_2_outlined,
                      label: 'Catálogo',
                      value: '${state.productCount}',
                      color: _purple,
                      onTap: () => navigateToShellSection(context, '/products'),
                    ),
                    const SizedBox(width: 10),
                    _StatButton(
                      icon: Icons.shopping_basket_outlined,
                      label: 'Lista compra',
                      value: '',
                      color: _accentGreen,
                      onTap: () => navigateToShellSection(
                        context,
                        '/shopping-list',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── SEARCH BAR ──────────────────────────────────────────
              GestureDetector(
                onTap: () => context.openAuxiliaryRoute('/search'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Buscar productos…',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.qr_code_scanner,
                          color: _purple.withOpacity(0.7), size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── QUICK ACTIONS 3 x 2 ──────────────────────────────────
              const _SectionTitle(title: 'Accesos rápidos'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.96,
                children: [
                  _QuickActionTile(
                    icon: Icons.swap_vert_circle_outlined,
                    label: 'Movimientos',
                    backgroundColor: _mint,
                    iconColor: _purple,
                    onTap: () =>
                      navigateToShellSection(context, '/stock-history'),
                  ),
                  _QuickActionTile(
                    icon: Icons.add_business_outlined,
                    label: 'Nuevo almacén',
                    backgroundColor: const Color(0xFFE9D8FD),
                    iconColor: _purple,
                    onTap: () => showWarehouseDialog(context),
                  ),
                  _QuickActionTile(
                    icon: Icons.store_outlined,
                    label: 'Tiendas',
                    backgroundColor: const Color(0xFFDFF3E4),
                    iconColor: _accentGreen,
                    onTap: () => navigateToShellSection(context, '/stores'),
                  ),
                  _QuickActionTile(
                    icon: Icons.label_outlined,
                    label: 'Marcas',
                    backgroundColor: const Color(0xFFFDE2E4),
                    iconColor: const Color(0xFFB02A37),
                    onTap: () => navigateToShellSection(context, '/brands'),
                  ),
                  _QuickActionTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos',
                    backgroundColor: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    onTap: () => navigateToShellSection(context, '/products'),
                  ),
                  _QuickActionTile(
                    icon: Icons.add_box_outlined,
                    label: 'Nuevo producto',
                    backgroundColor: const Color(0xFFFFF3BF),
                    iconColor: const Color(0xFF9C6B00),
                    onTap: () =>
                        context.openAuxiliaryRoute('/products/new'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── RECENT WAREHOUSES ─────────────────────────────────────
              if (state.recentWarehouses.isNotEmpty) ...[
                _SectionTitle(
                  title: 'Mis almacenes',
                  actionLabel: 'Ver todos',
                    onAction: () =>
                      navigateToShellSection(context, '/warehouses'),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: [
                    for (final w in state.recentWarehouses)
                      _WarehouseButton(
                        name: w.name,
                        onTap: () => context.openAuxiliaryRoute(
                          '/warehouses/${w.id}/detail',
                        ),
                      ),
                    _WarehouseAddButton(
                      onTap: () => showWarehouseDialog(context),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ── LOW STOCK ─────────────────────────────────────────────
              if (state.lowStockItems.isNotEmpty) ...[
                Row(
                  key: _lowStockKey,
                  children: [
                    const _SectionTitle(title: 'Stock crítico'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.lowStockCount}',
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in state.lowStockItems)
                  _LowStockRow(
                    name: item.product?.name ?? 'Producto ${item.productId}',
                    qty: item.quantity,
                    min: item.minQuantity,
                    onTap: () => context.openAuxiliaryRoute(
                      '/products/${item.id}/detail',
                      extra: {'warehouseId': item.warehouseId},
                    ),
                  ),
              ] else
                const EmptyView(
                  message: 'No hay productos bajos de stock',
                  icon: Icons.check_circle_outline,
                ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stat button (3 across top) ───────────────────────────────────────────────
class _StatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              if (value.isNotEmpty)
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick action tile (3 x 2 grid) ──────────────────────────────────────────
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _purple)),
        if (actionLabel != null && onAction != null)
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: _accentGreen, padding: EdgeInsets.zero),
            onPressed: onAction,
            child: Text(actionLabel!,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ─── Warehouse button chip ────────────────────────────────────────────────────
class _WarehouseButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _WarehouseButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _purple.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: _mint, shape: BoxShape.circle),
              child: const Icon(Icons.warehouse_outlined,
                  color: _purple, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add warehouse button ─────────────────────────────────────────────────────
class _WarehouseAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WarehouseAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _mint.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accentGreen.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.add,
                  color: _accentGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Nuevo',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _accentGreen)),
          ],
        ),
      ),
    );
  }
}

// ─── Low stock row ─────────────────────────────────────────────────────────────
class _LowStockRow extends StatelessWidget {
  final String name;
  final num qty;
  final num? min;
  final VoidCallback onTap;

  const _LowStockRow({
    required this.name,
    required this.qty,
    this.min,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Stock: ${qty.toInt()} / Mín: ${min?.toInt() ?? 0}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.red.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}
