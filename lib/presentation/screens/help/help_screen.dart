import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.secondary,
        foregroundColor: cs.onPrimary,
        title: const Text('Ayuda y tutoriales',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: const [
          _HelpSection(
            icon: Icons.rocket_launch_outlined,
            title: 'Primeros pasos',
            items: [
              _HelpItem(
                question: '¿Qué es InvesVault?',
                answer:
                    'InvesVault es una aplicación de gestión de inventario. Te permite organizar tus productos por almacenes, controlar el stock, llevar un historial de cambios y generar listas de la compra automáticas cuando el stock de un producto cae por debajo de su mínimo.',
              ),
              _HelpItem(
                question: '¿Por dónde empiezo?',
                answer:
                    '1. Crea al menos un almacén desde "Inventario".\n2. Añade productos al almacén e indica la cantidad actual y el stock mínimo.\n3. Opcionalmente, asigna una marca y una tienda a cada producto.\n4. A partir de ahí puedes generar la lista de la compra automáticamente y registrar entradas/salidas de stock.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.home_outlined,
            title: 'Panel de inicio',
            items: [
              _HelpItem(
                question: '¿Qué información muestra el panel de inicio?',
                answer:
                    'El panel muestra tres contadores en la parte superior (productos con stock bajo, total del catálogo y acceso directo a la lista de la compra), una barra de búsqueda global, seis accesos rápidos a las funciones más usadas, una sección de almacenes recientes y la lista de productos en stock crítico.',
              ),
              _HelpItem(
                question: '¿Cómo actualizo los datos del panel?',
                answer:
                    'Desliza hacia abajo en la pantalla para refrescar (pull-to-refresh). Los contadores y las listas se actualizarán con la información más reciente.',
              ),
              _HelpItem(
                question: '¿Qué es la sección de stock crítico del panel?',
                answer:
                    'Muestra los productos cuyo stock actual está por debajo del mínimo configurado. Pulsa sobre cualquier producto para ver su detalle, o pulsa "Ver todos" para abrir la pantalla completa de stock crítico con la lista entera.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.warehouse_outlined,
            title: 'Almacenes',
            items: [
              _HelpItem(
                question: '¿Qué es un almacén?',
                answer:
                    'Un almacén representa un espacio físico de almacenamiento: tu casa, un local, una despensa, etc. Cada almacén tiene su propio inventario de productos con sus cantidades y stocks mínimos independientes.',
              ),
              _HelpItem(
                question: '¿Puedo compartir un almacén con otras personas?',
                answer:
                    'Sí. Desde el detalle de un almacén, pulsa el icono de compartir. Puedes añadir otros usuarios por correo electrónico y asignarles el rol de visor, editor o administrador.',
              ),
              _HelpItem(
                question: '¿Qué diferencia hay entre los roles de un almacén?',
                answer:
                    '• Visor: solo puede consultar el inventario.\n• Editor: puede modificar cantidades y productos.\n• Administrador: tiene acceso completo, incluido invitar a otros usuarios.',
              ),
              _HelpItem(
                question: '¿Cómo añado un producto a un almacén?',
                answer:
                    'Desde el detalle del almacén, pulsa el botón "+". Elige un producto del catálogo, indica la cantidad inicial y, opcionalmente, el stock mínimo, el precio por unidad y la tienda habitual de compra.',
              ),
              _HelpItem(
                question: '¿Cómo elimino varios productos del almacén a la vez?',
                answer:
                    'Pulsa el icono de modo eliminación en la barra superior del detalle del almacén. Marca los productos que desees eliminar y confirma la acción en el diálogo que aparece.',
              ),
              _HelpItem(
                question: '¿Puedo buscar un producto dentro de un almacén?',
                answer:
                    'Sí. En el detalle de cualquier almacén hay una barra de búsqueda que filtra los productos en tiempo real mientras escribes.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.inventory_2_outlined,
            title: 'Productos y catálogo',
            items: [
              _HelpItem(
                question: '¿Qué diferencia hay entre un producto y un ítem de almacén?',
                answer:
                    'El catálogo contiene los productos globales (nombre, marca, código de barras…). Cuando añades un producto a un almacén, se crea un "ítem de almacén" que guarda la cantidad actual y el stock mínimo específicos de ese almacén.',
              ),
              _HelpItem(
                question: '¿Qué es el stock mínimo?',
                answer:
                    'Es la cantidad por debajo de la cual el producto se considera en estado crítico. El sistema usará este valor para avisarte en el panel de inicio y para incluir el producto en la lista de la compra cuando generes una automáticamente.',
              ),
              _HelpItem(
                question: '¿Cómo uso el escáner de código de barras?',
                answer:
                    'Al crear o editar un producto, pulsa el icono de cámara junto al campo de código de barras. Apunta con la cámara al código y la app lo leerá automáticamente.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.search_outlined,
            title: 'Búsqueda global',
            items: [
              _HelpItem(
                question: '¿Cómo accedo a la búsqueda global?',
                answer:
                    'Pulsa la barra de búsqueda del panel de inicio. Se abrirá la pantalla de búsqueda global donde puedes encontrar cualquier producto del catálogo.',
              ),
              _HelpItem(
                question: '¿Por qué campos puedo buscar?',
                answer:
                    'Puedes buscar por nombre de producto, código de barras y nombre de marca. Los resultados se filtran en tiempo real mientras escribes.',
              ),
              _HelpItem(
                question: '¿Puedo buscar escaneando un código de barras?',
                answer:
                    'Sí. Pulsa el botón verde "Escanear" en la pantalla de búsqueda. La cámara leerá el código de barras y mostrará automáticamente el producto correspondiente.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.shopping_cart_outlined,
            title: 'Lista de la compra',
            items: [
              _HelpItem(
                question: '¿Cómo se genera la lista automáticamente?',
                answer:
                    'Pulsa el icono ✨ en la pantalla de lista de la compra. El sistema revisará todos los almacenes y añadirá a la lista los productos cuyo stock actual esté por debajo del mínimo, indicando la cantidad sugerida a comprar.',
              ),
              _HelpItem(
                question: '¿Cómo marco un producto para comprarlo?',
                answer:
                    'Toca el check a la izquierda del producto para marcarlo. Solo los productos marcados se procesarán al pulsar "Comprar seleccionados".',
              ),
              _HelpItem(
                question: '¿Qué hace "Comprar seleccionados"?',
                answer:
                    'Registra una entrada de stock por cada producto marcado, sumando la cantidad a comprar al stock actual del almacén correspondiente. Si la cantidad comprada cubre la planificada, el producto se elimina de la lista; si no, la lista se actualiza con la cantidad pendiente.',
              ),
              _HelpItem(
                question: '¿La papelera modifica el stock del almacén?',
                answer:
                    'No. La papelera (y la selección múltiple con el icono de lista) solo eliminan el producto de la lista de la compra. El stock del almacén y el producto en sí no se ven afectados.',
              ),
              _HelpItem(
                question: '¿Para qué sirve la pestaña "Almacenes"?',
                answer:
                    'Te permite ver y gestionar la lista de la compra de un almacén concreto, en lugar de ver todos los almacenes a la vez como hace la pestaña "Tiendas".',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.swap_vert_circle_outlined,
            title: 'Stock e historial',
            items: [
              _HelpItem(
                question: '¿Cómo registro una entrada o salida de stock?',
                answer:
                    'Entra al detalle de un almacén, pulsa sobre un producto y usa los botones de entrada (+) o salida (−) para registrar el cambio. También puedes introducir la cantidad manualmente.',
              ),
              _HelpItem(
                question: '¿Dónde veo el historial de cambios?',
                answer:
                    'En la sección "Historial de cambios" del menú lateral. Puedes filtrar por almacén, producto, tipo de cambio y fechas.',
              ),
              _HelpItem(
                question: '¿Puedo ver el historial de un producto concreto desde su detalle?',
                answer:
                    'Sí. En la pantalla de detalle de un producto dentro de un almacén, desplázate hacia abajo para ver sus movimientos. Puedes filtrar por tipo: Todos, Entrada, Salida o Ajuste.',
              ),
              _HelpItem(
                question: '¿Puedo editar el stock mínimo o el precio desde el detalle del producto?',
                answer:
                    'Sí. En el detalle del producto, despliega la tarjeta de edición para modificar el stock mínimo, el precio por unidad y la tienda asociada a ese almacén concreto.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            items: [
              _HelpItem(
                question: '¿Cuándo recibo notificaciones?',
                answer:
                    'El sistema genera notificaciones automáticas cuando el stock de un producto baja del mínimo o llega a cero en algún almacén al que tienes acceso.',
              ),
              _HelpItem(
                question: '¿Dónde veo las notificaciones?',
                answer:
                    'Pulsa el icono de campana en la barra superior del panel de inicio. Las notificaciones no leídas se muestran con un punto de aviso.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.label_outlined,
            title: 'Marcas y tiendas',
            items: [
              _HelpItem(
                question: '¿Para qué sirven las marcas?',
                answer:
                    'Las marcas te permiten categorizar y filtrar tus productos por fabricante. Puedes gestionarlas desde la sección "Marcas" del menú lateral.',
              ),
              _HelpItem(
                question: '¿Para qué sirven las tiendas?',
                answer:
                    'Las tiendas indican dónde compras habitualmente cada producto. Al asignar una tienda a un producto, la lista de la compra puede agrupar los artículos por tienda para facilitarte las compras.',
              ),
            ],
          ),
          SizedBox(height: 8),
          _HelpSection(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            items: [
              _HelpItem(
                question: '¿Cómo cambio mi nombre o correo electrónico?',
                answer:
                    'Ve a "Configuración" en el menú lateral. Edita los campos de nombre y correo electrónico y pulsa "Guardar cambios". Los cambios se aplican de inmediato.',
              ),
              _HelpItem(
                question: '¿Dónde veo la versión de la app?',
                answer:
                    'En la pantalla de "Configuración", al final, se muestra la versión actual de InvesVault.',
              ),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────────
class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_HelpItem> items;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.secondary.withValues(alpha: 0.1),
              child: Icon(icon, size: 16, color: cs.secondary),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant),
          ),
          color: cs.surface,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: cs.outlineVariant,
                  ),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Item ─────────────────────────────────────────────────────────────────────
class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: Icon(Icons.help_outline, size: 18, color: cs.primary),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        iconColor: cs.secondary,
        collapsedIconColor: cs.onSurfaceVariant,
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
