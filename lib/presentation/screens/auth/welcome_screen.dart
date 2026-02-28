import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/auth/auth_cubit.dart';

const _purple = Color(0xFF3C096C);
const _mint = Color(0xFFD8F3DC);
const _white = Color(0xFFFFFFFF);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.inventory_2_outlined,
      title: 'Controla tu stock al instante',
      subtitle:
          'Gestiona tu inventario sin complicaciones. Con nuestro escáner de '
          'códigos de barras, añadir y actualizar productos es cuestión de '
          'segundos. Despídete de las hojas de cálculo y da la bienvenida '
          'a la eficiencia.',
    ),
    _SlideData(
      icon: Icons.warehouse_outlined,
      title: 'Tu almacén, perfectamente organizado',
      subtitle:
          '¿Cansado del caos? Centraliza todos tus productos y almacenes en '
          'un solo lugar. Recibe alertas inteligentes cuando el stock esté '
          'bajo y genera listas de compras automáticas para que nunca te '
          'falte nada.',
    ),
    _SlideData(
      icon: Icons.bar_chart_outlined,
      title: 'Inventario inteligente, vida fácil',
      subtitle:
          'Simplifica la gestión de tu inventario. Con alertas de stock en '
          'tiempo real y un control de cambios detallado, siempre sabrás '
          'lo que tienes y lo que necesitas. ¡Más control, menos estrés!',
    ),
    _SlideData(
      icon: Icons.smartphone_outlined,
      title: 'Todo el poder en tu mano',
      subtitle:
          'Desde el escaneo rápido de productos hasta el seguimiento de '
          'movimientos de stock. Nuestra aplicación te da las herramientas '
          'para optimizar tu almacén, organizar tus listas de compras y '
          'colaborar con tu equipo, todo desde tu móvil.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await context.read<AuthCubit>().markWelcomeSeen();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: Column(
        children: [
          // ── Header: logo + name + version + settings ───────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: _purple, shape: BoxShape.circle),
                    child: const Icon(Icons.inventory_2_outlined,
                        size: 22, color: _mint),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'InvesVault',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                      Text(
                        'v0.0.1-alpha',
                        style: TextStyle(
                          fontSize: 11,
                          color: _purple.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: _purple.withOpacity(0.7)),
                    tooltip: 'Ajustes',
                    onPressed: () {}, // TODO: settings
                  ),
                ],
              ),
            ),
          ),

          // Slides area
          Expanded(
            child: ScrollConfiguration(
              behavior: _WebScrollBehavior(),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlidePage(data: _slides[i]),
              ),
            ),
          ),

          // Bottom bar
          Container(
            color: _purple,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? _mint : _white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mint,
                      foregroundColor: _purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _start,
                    child: const Text('Comienza Ahora'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Web scroll behaviour (allows mouse drag on PageView) ───────────────────
class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

// ─── Slide data model ─────────────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// ─── Single slide page ────────────────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _SlideData data;

  const _SlidePage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 60, color: _purple),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _purple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: _purple.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
