# Plan de Acción — InvesVault App

Plan unificado de mejora de UX, UI y navegación basado en los tres análisis previos.

**Documentos fuente:**
- [[UI_ANALYSIS]] — Análisis de interfaz visual, componentes y sistema de diseño
- [[UX_ANALYSIS]] — Análisis de experiencia de usuario, flujos y estados
- [[NAVIGATION_ANALYSIS]] — Análisis de navegación pantalla por pantalla

Las tareas están ordenadas por prioridad y agrupadas por área temática. Cada tarea describe qué hacer, por qué, y qué impacto tiene, sin entrar en código.

Todas las funcionalidades actualmente visibles pero no operativas son características planificadas que deben implementarse, no eliminarse.

---

## Prioridad Alta

Deben implementarse primero. Corrigen problemas de usabilidad, completan funcionalidad pendiente, o tienen alto impacto con esfuerzo moderado.

---

### ✅ A1. Implementar acceso a settings desde las pantallas auth

**Origen**: NAV-5, NAV-6, NAV-7 / UX-3

**Problema**: El icono de ajustes aparece en la esquina superior derecha de Login, Register y Welcome pero su `onPressed` está vacío. Es una funcionalidad pendiente que rompe la expectativa del usuario al no responder.

**Tarea**:
- Implementar la acción del botón en las 3 pantallas. Debe mostrar un modal con las opciones de tema (claro/oscuro/sistema) usando el `ThemeCubit`, permitiendo al usuario configurar la apariencia incluso antes de autenticarse.
- El modal debe ser ligero: un `showModalBottomSheet` o `Dialog` con los 3 radio options y un botón "Cerrar".
- Verificar que no quede ningún otro `onPressed: () {}` pendiente en la app.

**Impacto**: Completa una funcionalidad esperada. Permite al usuario ajustar el tema antes de hacer login. Esfuerzo bajo.

---

### A2. Implementar flujo de recuperación de contraseña

**Origen**: NAV-7 / UX-4

**Problema**: El `TextButton` "¿Olvidaste tu contraseña?" en Login es un placeholder sin implementar. El usuario hace tap y no obtiene respuesta.

**Tarea**:
- Implementar un flujo completo de recuperación:
  - Diálogo que solicita el email del usuario.
  - Llamada a un endpoint de la API para solicitar reset de contraseña (a coordinar con el backend si no existe todavía).
  - Mostrar confirmación: "Si el email existe, recibirás un enlace de recuperación".
- Si el backend no tiene endpoint de reset todavía, esta tarea incluye la coordinación para añadirlo.
- El botón ya tiene buena visibilidad y ubicación; solo falta la funcionalidad.

**Impacto**: Completa una funcionalidad esencial de auth que los usuarios esperan encontrar. Esfuerzo medio (incluye coordinación con backend).

---

### ✅ A3. Menú contextual (⋮) → botón directo en WarehouseDetail

**Origen**: NAV-13 / UI-2.3

**Problema**: El `ProductListTile` en el detalle de almacén tiene un `PopupMenuButton` (⋮) que contiene una sola opción: "Eliminar del almacén". Un menú de 1 item es sobre-ingeniería que oculta la acción.

**Tarea**:
- Reemplazar el `PopupMenuButton` por un `IconButton` con `Icons.delete_outline` en color rojo directamente visible en el tile.
- Mantener el diálogo de confirmación `ConfirmDialog` con `isDangerous: true` antes de ejecutar la eliminación.
- Verificar que no haya duplicación con el icono de papelera ya existente en el `trailing` del tile en modo normal.

**Impacto**: Reduce un tap innecesario (abrir menú → seleccionar) y hace la acción más descubrible. Esfuerzo bajo.

---

### ✅ A4. Tap en catálogo → detalle de producto, no editar

**Origen**: NAV-14 / UX-5

**Problema**: En `ProductListScreen` (Catálogo), el tap en una card de producto navega directamente al formulario de edición (`/products/:id/edit`). El usuario espera ver información del producto, no editarlo. Para consultar cualquier detalle hay que ir a un almacén específico, lo cual es un rodeo innecesario.

**Tarea**:
- Cambiar el destino del tap en las cards de `ProductListScreen`: de `/products/:id/edit` a una pantalla de detalle del producto.
- La pantalla de detalle (puede reutilizar `ProductDetailScreen` adaptada o ser una nueva vista "ficha de producto") debe mostrar: nombre, marca, barcode, unidad, categorías, imagen, y la lista de almacenes donde está presente con sus cantidades.
- Incluir un botón "Editar producto" dentro de la pantalla de detalle para acceder al formulario de edición.
- Mantener el icono de papelera en la card para eliminación rápida desde la lista.

**Impacto**: Corrige una expectativa rota fundamental. Los usuarios podrán consultar productos sin pasar por un almacén. Esfuerzo medio.

---

### ✅ A5. Notificaciones navegables al origen

**Origen**: NAV-19 / UX-3

**Problema**: Las notificaciones en `NotificationListScreen` solo pueden marcarse como leídas o eliminarse. Al tocarlas no navegan a ningún lado. Una notificación de "Stock bajo de Leche" debería llevar al detalle de ese producto en su almacén.

**Tarea**:
- El modelo `NotificationModel` ya contiene `productId`, `warehouseId`, `type` y `batchId`. Usar estos campos para determinar el destino de navegación.
- Al hacer tap en una notificación:
  - Si `type == 'low_stock'` y tiene `productId` + `warehouseId`: navegar a `/products/:warehouseProductId/detail?warehouseId=X`.
  - Si `type == 'expiry_warning'` y tiene `productId` + `warehouseId` + `batchId`: navegar al detalle del producto con scroll a la sección de lotes.
  - Si `type == 'shared'` y tiene `warehouseId`: navegar a `/warehouses/:id/detail`.
- Marcar como leída la notificación al navegar.
- Las notificaciones locales (`showLowStockNotification`) ya existen; añadir payload con `productId` y `warehouseId` para que al tocar la notificación del sistema también se abra la pantalla correcta.

**Impacto**: Convierte las notificaciones de elementos pasivos a activos, creando atajos directos a la acción. Esfuerzo medio.

---

### ✅ A6. Indicador de swipe + botón "Siguiente" en onboarding

**Origen**: NAV-6 / UI-13

**Problema**: El `WelcomeScreen` usa `PageView` con swipe horizontal, pero no hay ninguna indicación visual de que se puede deslizar. Los dots animados son el único feedback. Usuarios no familiarizados con el patrón pueden no descubrir los slides 2-4.

**Tarea**:
- Añadir en el primer slide una indicación visual: un texto "Desliza para continuar →" o un icono de flecha animada (pulso o bounce) bajo el subtítulo.
- Añadir un botón "Siguiente" junto a los dots que avance al siguiente slide (`_pageController.nextPage`). Esto da una alternativa explícita al swipe.
- El botón "Comienza Ahora" debe cambiar según el slide:
  - Slides 1-3: mostrar "Siguiente" en su lugar.
  - Slide 4 (último): mostrar "Comienza Ahora".
- Alternativamente, ocultar "Comienza Ahora" hasta el último slide y mostrar solo dots + botón "Siguiente" en slides intermedios.

**Impacto**: Mejora drásticamente la descubribilidad del onboarding para usuarios no técnicos. Esfuerzo bajo.

---

### ✅ A7. Corregir contraste de colores (WCAG AA)

**Origen**: UI-5

**Problema**: Varios colores no cumplen el ratio de contraste mínimo WCAG AA (4.5:1 para texto normal, 3:1 para texto grande):
- `textHint` (#9E9E9E) sobre blanco: 2.9:1 — texto ilegible para usuarios con visión reducida.
- `success` (#74C69D) sobre blanco: 1.8:1 — usado como color de texto en shopping list, invisible.
- `primary` (#40916C) sobre blanco: 3.6:1 — usado como texto en algunos contextos.

**Tarea**:
- Cambiar `AppColors.textHint` a `#757575` (ratio 4.6:1 sobre blanco).
- Cambiar `AppColors.success` a `AppGreens.c500` (#2D6A4F) para texto sobre fondo claro. Mantener `AppGreens.c300` (#74C69D) para fondos e iconos donde no se requiere contraste de texto.
- Usar `AppColors.primaryDark` (#2D6A4F) para texto verde sobre fondo claro en lugar de `AppColors.primary` (#40916C).
- Actualizar todas las referencias a estos colores en la app (shopping list, stat buttons, etc.).
- Verificar que los cambios no rompan el tema oscuro (donde los colores actuales sí tienen contraste suficiente).

**Impacto**: Hace la app legible para usuarios con visión reducida y cumple estándares de accesibilidad. Esfuerzo bajo.

---

### ✅ A8. SafeArea correcto en drawer

**Origen**: UI-3.2 / UI-7

**Problema**: El drawer usa `SafeArea(top: false)` pero sin `bottom: true` explícito. En dispositivos con barra de navegación por gestos (iPhone X+, Android 10+), los últimos items ("Cerrar sesión") pueden quedar parcialmente ocultos bajo la barra del sistema.

**Tarea**:
- Envolver el contenido del drawer con `SafeArea` que tenga tanto `top: false` como `bottom: true`.
- Alternativamente, usar `MediaQuery.of(context).padding.bottom` para añadir padding inferior al último `SizedBox` de la lista.
- Verificar en dispositivos con notch y gestos (simulador iPhone, Android con gesture navigation).

**Impacto**: Evita que elementos interactivos queden inaccesibles. Esfuerzo mínimo.

---

### A9. SnackBar con acción "Deshacer" en eliminaciones

**Origen**: UX-3 / UX-2

**Problema**: Todas las eliminaciones (producto de almacén, almacén, marca, categoría, tienda, notificación, item de shopping list) son definitivas tras confirmar. Si el usuario se equivoca, no hay vuelta atrás.

**Tarea**:
- Después de una eliminación exitosa (no en el diálogo de confirmación, sino tras la respuesta 200 del backend), mostrar un `SnackBar` con:
  - Texto: `"X eliminado correctamente"`
  - Acción: botón `TextButton` "Deshacer" que llame al endpoint de creación/restauración correspondiente.
- El SnackBar debe durar al menos 5 segundos (`duration: Duration(seconds: 5)`) para dar tiempo a reaccionar.
- Aplicar en: WarehouseDetail (eliminar producto), WarehouseList (eliminar almacén), ProductList, BrandList, CategoryList, StoreList, ShoppingList, NotificationList.
- Para eliminaciones batch, el SnackBar debe agrupar: "5 productos eliminados. Deshacer".
- Para shopping list, el undo debe restaurar el item con su `suggestedQty` original.

**Impacto**: Previene pérdida de datos por error. Reduce ansiedad al usar acciones destructivas. Esfuerzo medio (hay que implementarlo en ~8 pantallas).

---

### A10. Skeleton screens en listas principales

**Origen**: UX-2 / UI-9 / UI-11.2

**Problema**: Todas las cargas de datos muestran un `CircularProgressIndicator` centrado. Esto da sensación de espera y no comunica la estructura que va a aparecer.

**Tarea**:
- Implementar skeleton screens (shimmer) para las pantallas de lista principales: Dashboard, WarehouseDetail, ProductList, WarehouseList, ShoppingList.
- Cada skeleton debe imitar la estructura de la pantalla cargada: cards rectangulares con mismo tamaño y posición que los elementos reales.
- Priorizar las pantallas más frecuentadas: Dashboard y WarehouseDetail.
- Usar `AnimatedSwitcher` con `FadeTransition` para transicionar suavemente del skeleton al contenido real.
- La técnica puede ser manual (contenedores grises animados) o usando un paquete como `shimmer`.

**Impacto**: Reduce drásticamente la percepción de lentitud. La app se siente instantánea aunque la API tarde. Esfuerzo medio.

---

### ✅ A11. AnimatedCrossFade entre estados de carga y contenido

**Origen**: UX-2 / UI-9 / UI-11.2

**Problema**: La transición entre `LoadingIndicator`/`ErrorView`/contenido es instantánea (corte brusco). El ojo no tiene tiempo de adaptarse.

**Tarea**:
- Envolver el `BlocBuilder` de cada pantalla principal con `AnimatedSwitcher` + `FadeTransition` (duration: ~300ms).
- Aplicar en: Dashboard, WarehouseDetail, WarehouseList, ProductList, ShoppingList, BrandList, CategoryList, StoreList, StockHistory, Notifications.
- El `AnimatedSwitcher` debe envolver los 3 estados (loading, error, loaded) para que la transición sea suave entre cualquiera de ellos.
- Usar `ValueKey` para forzar la animación al cambiar de estado.

**Impacto**: Hace que los cambios de estado se sientan fluidos en lugar de abruptos. Esfuerzo bajo (cambio mecánico en cada pantalla).

---

### ✅ A12. Placeholder visual durante carga de imágenes

**Origen**: UX-5 / UI-6

**Problema**: Las imágenes de producto usan `Image.network` con `errorBuilder` (que muestra `Icons.image_not_supported`), pero sin `loadingBuilder`. Mientras la imagen carga, no se muestra nada en su lugar — la card aparece con un espacio vacío.

**Tarea**:
- Añadir `loadingBuilder` en todas las imágenes de producto (`ProductListTile`, `ProductDetailScreen`, `GlobalSearchScreen`) que muestre un placeholder shimmer o un `CircleAvatar` con la inicial del producto mientras carga.
- El placeholder debe tener el mismo tamaño que la imagen final para evitar reflow.
- Si la imagen falla (`errorBuilder`), mostrar un placeholder con icono de cámara o `inventory_2` en lugar del genérico `image_not_supported`.

**Impacto**: Elimina el "parpadeo" de imágenes al cargar. Mejora la percepción de calidad. Esfuerzo bajo.

---

### ✅ A13. Animaciones de transición entre pantallas

**Origen**: UX-6 / UI-9

**Problema**: Las transiciones entre rutas usan el `MaterialPageRoute` default de Flutter (slide desde la derecha en iOS, fade en Android). No hay una animación personalizada que dé identidad a la app.

**Tarea**:
- Configurar `pageTransitionsTheme` en `ThemeData.light` y `ThemeData.dark` con un builder personalizado (ej: `FadeUpwardsPageTransitionsBuilder` o `OpenUpwardsPageTransitionsBuilder` de Material 3).
- La animación debe ser sutil: ~300ms, curva `easeOut`.
- Aplicar a `MaterialApp` mediante `theme.copyWith(pageTransitionsTheme: ...)`.
- Verificar que no rompa la navegación del shell (las rutas del shell usan `IndexedStack`, no deberían verse afectadas).

**Impacto**: Da pulido profesional a cada navegación. Diferencia la app de una app Flutter genérica. Esfuerzo bajo (configuración en un solo lugar).

---

### A14. Unificar barra de búsqueda (AppSearchBar)

**Origen**: UI-2.2 / UI-12

**Problema**: La barra de búsqueda se implementa de 4 formas distintas: `GestureDetector` decorado en Dashboard, `TextField` en WarehouseDetail, `TextField` en ProductList, `TextField` en Notifications, sin barra en Categories y Help.

**Tarea**:
- Crear un widget `AppSearchBar` que encapsule el `TextField` con:
  - `InputDecoration` con `prefixIcon: search`, `suffixIcon: clear` (condicional), hint personalizable.
  - Callback `onChanged` con debounce interno configurable (default 400ms).
  - Callback `onClear` para limpiar.
  - `autofocus` opcional.
  - Tema heredado del `InputDecorationTheme` global.
- Reemplazar todas las barras de búsqueda manuales por `AppSearchBar`.
- En Dashboard, evaluar si mantener el `GestureDetector` (navega a /search) o convertirlo en un `AppSearchBar` real con búsqueda inline.

**Impacto**: Consistencia visual y funcional en 5+ pantallas. Una sola fuente de verdad para el comportamiento de búsqueda. Esfuerzo medio.

---

### ✅ A15. Pull-to-refresh en todas las listas

**Origen**: UX-2 / UX-5 / NAV-18

**Problema**: `RefreshIndicator` solo está implementado en Dashboard, WarehouseDetail, ProductList y Notifications. Falta en: ShoppingList, StockHistory, BrandList, CategoryList, StoreList y CriticalStock.

**Tarea**:
- Añadir `RefreshIndicator` en cada pantalla de lista que no lo tenga.
- En ShoppingList: el refresh debe recargar la lista actual (si es vista global → `loadAll()`, si es vista por almacén → `load(warehouseId)`).
- En StockHistory: el refresh debe recargar los cambios del almacén seleccionado. Si no hay almacén seleccionado, no mostrar refresh.
- En BrandList/CategoryList/StoreList: recargar la lista completa.
- El `onRefresh` debe devolver un `Future` que complete cuando los datos se hayan recargado.

**Impacto**: El usuario puede forzar una actualización sin tener que re-aplicar filtros o cambiar de pantalla. Esfuerzo bajo.

---

## Prioridad Media

Mejoras importantes que aumentan la consistencia y calidad de la experiencia, pero no bloquean la funcionalidad básica.

---

### M1. Bottom Navigation Bar

**Origen**: UX-1 / NAV-10

**Problema**: La navegación principal depende 100% del drawer, requiriendo 2 interacciones (abrir drawer → seleccionar destino) para cada cambio de sección. Los usuarios nuevos pueden no descubrir el drawer.

**Tarea**:
- Añadir una `BottomNavigationBar` con 4 items principales: Inicio (Dashboard), Inventario (Warehouses), Catálogo (Products), Lista de compra (ShoppingList).
- El drawer debe permanecer accesible vía hamburguesa y contener las secciones secundarias: Tiendas, Marcas, Categorías, Historial, Configuración, Ayuda, Cerrar sesión.
- Rediseñar `AppShell` para que el `Scaffold` incluya `bottomNavigationBar` y el `body` use `IndexedStack` (ya lo usa) con las 4 secciones principales.
- Los items "Próximamente" se quedan en el drawer.
- Sincronizar el índice del bottom nav con la ruta actual (si se navega por drawer a una sección que está en el bottom nav, debe reflejarse).

**Impacto**: Reduce la fricción de navegación a 1 tap para las secciones más usadas. Mejora drásticamente la descubribilidad. Esfuerzo alto (implica rediseñar AppShell, drawer, y router).

---

### M2. Icono QR independiente en search bar del dashboard

**Origen**: NAV-11

**Problema**: La barra de búsqueda del dashboard es un `GestureDetector` decorado que navega a `/search`. El icono QR a la derecha insinúa escáner pero no es cliqueable independientemente.

**Tarea**:
- Convertir el icono QR en un `IconButton` independiente (o `GestureDetector` con hotspot separado) que navegue directamente a `/scanner`.
- El área de texto "Buscar productos…" debe navegar a `/search`.
- Son dos acciones diferenciadas visualmente: la lupa + texto → búsqueda, el QR → escáner.
- Si se implementa `AppSearchBar` (tarea A14), este widget debe soportar un `trailing` action independiente.

**Impacto**: Acceso directo al escáner sin pasar por búsqueda. Reduce 1 navegación innecesaria. Esfuerzo bajo.

---

### M3. Reorganizar menú de acciones en ShoppingList

**Origen**: NAV-17 / UX-8

**Problema**: El menú ⋮ en ShoppingList contiene 7-8 acciones: generar, añadir, ordenar (2 opciones), info, seleccionar para borrar, limpiar. Es un menú sobrecargado. Las acciones frecuentes están ocultas.

**Tarea**:
- Sacar acciones frecuentes del menú y ponerlas como botones visibles en la toolbar:
  - "Generar automáticamente" (✨): botón en la toolbar de la tab Almacenes (junto al dropdown de almacén).
  - "Añadir producto" (+): botón visible en ambas tabs.
  - "Cómo funciona" (ℹ️): icono en la cabecera de tabs, no escondido en menú.
- Dejar en el menú ⋮ solo: opciones de ordenación (con check), seleccionar para borrar, limpiar lista.
- El menú reducido es más escaneable y las acciones frecuentes son visibles.

**Impacto**: Mejora la descubribilidad de las acciones más usadas en la pantalla más compleja. Esfuerzo medio.

---

### M4. Animación de éxito en escáner

**Origen**: NAV-23 / UX-4

**Problema**: Cuando el escáner detecta un código, hace `Navigator.pop()` instantáneamente. El usuario no tiene confirmación visual de que el escaneo fue exitoso.

**Tarea**:
- Antes del `pop()`, ejecutar una animación de éxito:
  - Flash verde semi-transparente sobre el recuadro guía (~200ms).
  - Vibración háptica (`HapticFeedback.mediumImpact()`).
  - Breve pausa (~300ms) para que el usuario registre el éxito.
- Si la app está en modo "escanear para buscar", el pop devuelve el código. Si está en "escanear para crear producto", debe navegar al formulario con el barcode pre-rellenado.
- Cambiar el color del recuadro guía a verde durante la animación de éxito.

**Impacto**: Convierte una experiencia abrupta en una satisfactoria. Esfuerzo bajo.

---

### M5. Añadir barra de búsqueda en Categorías

**Origen**: NAV-20 / UI-12

**Problema**: `CategoryListScreen` es la única pantalla de lista de entidades sin barra de búsqueda. Marcas y Tiendas sí la tienen. Es una inconsistencia entre pantallas hermanas.

**Tarea**:
- Añadir un `TextField` de búsqueda (o `AppSearchBar` si ya se implementó A14) en `CategoryListScreen` que filtre las categorías por nombre.
- Usar filtrado local (las categorías suelen ser pocas, no justifica llamada a API).
- Si el `CategoryCubit` no soporta búsqueda, añadir filtrado en el `BlocBuilder` sobre la lista cargada.

**Impacto**: Consistencia entre las 3 pantallas de entidades auxiliares. Esfuerzo bajo.

---

### M6. Unificar FilterChips (AppFilterChip)

**Origen**: UI-2.3 / UI-12 / NAV-18

**Problema**: Los chips de filtro se implementan de 3 formas distintas: `FilterChip` nativo de Material 3 (WarehouseDetail, ProductList), `_TypeChip` custom con `AnimatedContainer` (StockHistory), `_StoreChip` custom (ShoppingList). Mismo propósito, distinta implementación visual.

**Tarea**:
- Crear `AppFilterChip` que unifique los 3 estilos.
- Debe soportar: label, selected, onSelected, color (opcional), animated (opcional).
- Migrar `_TypeChip` y `_StoreChip` a usar `AppFilterChip`.
- La animación de `_TypeChip` (`AnimatedContainer` 180ms) es deseable — mantenerla como opción en `AppFilterChip`.
- Mantener la codificación de color semántica (verde = entradas, rojo = salidas, ámbar = ajustes).

**Impacto**: Consistencia visual en todos los filtros de la app. Esfuerzo medio.

---

### M7. Sticky headers en shopping list agrupada

**Origen**: UX-5 / UX-8

**Problema**: Cuando la shopping list se ordena por categoría, los headers de categoría no son sticky. Al hacer scroll, el usuario pierde la referencia de en qué categoría está.

**Tarea**:
- Implementar sticky headers para la vista agrupada por categoría en shopping list.
- Usar `SliverList` con `SliverStickyHeader` o el paquete `flutter_sticky_header`.
- Cada header debe mostrar el nombre de la categoría en mayúsculas (estilo actual `_buildCategoryHeader`).
- Solo aplicar en el modo de ordenación `byCategory`.

**Impacto**: Mejora la orientación en listas largas agrupadas. Esfuerzo medio.

---

### M8. AppCard widget reutilizable

**Origen**: UI-2.3 / UI-12

**Problema**: No existe un componente de card reutilizable. Cada pantalla construye sus cards con `Container` + `BoxDecoration` manual, con ligeras variaciones de radio, sombra y borde.

**Tarea**:
- Crear `AppCard` con variantes:
  - `AppCard.elevated`: con sombra (estilo dashboard stat buttons).
  - `AppCard.filled`: sin sombra, con color de fondo.
  - `AppCard.outlined`: con borde.
- Parámetros: `child`, `onTap`, `color`, `borderColor`, `borderRadius` (default 14px), `padding`.
- Migrar progresivamente las cards existentes: empezar por Dashboard (stat buttons, warehouse buttons), luego ShoppingList cards, StockHistory cards, Search result cards.
- No requiere migración masiva inmediata; puede hacerse pantalla por pantalla.

**Impacto**: Consistencia visual y código más limpio. Facilita cambios globales de estilo. Esfuerzo medio (migración progresiva).

---

### M9. Sistema de espaciado estandarizado

**Origen**: UI-1

**Problema**: Los paddings y margins usan valores arbitrarios (10, 12, 14, 16, 18, 20, 24, 28, 32...) sin un sistema de escala.

**Tarea**:
- Definir constantes de espaciado en un archivo `app_spacing.dart`:
  - `xxs = 2`, `xs = 4`, `sm = 8`, `md = 12`, `lg = 16`, `xl = 20`, `xxl = 24`, `xxxl = 32`.
- Documentar cuándo usar cada una (ej: `sm` entre icono y texto, `lg` padding de card, `xl` entre secciones).
- Migrar los valores inline más usados. No es necesario migrar todos los existentes; empezar por los nuevos desarrollos.
- Añadir helpers `SizedBox` como `gapSm`, `gapMd`, `gapLg` para simplificar el código.

**Impacto**: Consistencia de layout en toda la app. Facilita decisiones de diseño. Esfuerzo bajo (definición) + medio (migración progresiva).

---

### M10. Responsive grid con breakpoints

**Origen**: UI-8

**Problema**: Los grids usan `crossAxisCount` fijo (2 columnas). En tablets y landscape se desperdicia espacio. Las cards no tienen `maxWidth`.

**Tarea**:
- Definir breakpoints: `mobile` (< 600dp), `tablet` (600-900dp), `desktop` (> 900dp).
- En grids de WarehouseList y ProductList:
  - Mobile: 2 columnas (como ahora).
  - Tablet/landscape: 3 columnas.
  - Desktop/web: 4 columnas con `maxWidth` constraint en el grid.
- En ShoppingList cards: añadir `maxWidth: 600` para que no se estiren en landscape.
- Usar `LayoutBuilder` para determinar el ancho disponible y ajustar `crossAxisCount`.

**Impacto**: Mejor aprovechamiento del espacio en tablets y landscape. Esfuerzo alto.

---

### M11. Shopping list cards sin reflow

**Origen**: UI-3.3

**Problema**: La columna "Ahora" (segundo contador +/-) solo aparece cuando el item está checked. Esto causa que el ancho de la card cambie y todo el layout haga reflow, lo cual es visualmente molesto.

**Tarea**:
- Reservar el espacio para la columna "Ahora" siempre, usando `Visibility` con `maintainSize: true`, `maintainAnimation: true`, `maintainState: true` en lugar de mostrar/ocultar condicionalmente.
- Cuando no hay item checked, la columna "Ahora" debe estar invisible (`Opacity: 0`) pero ocupando su espacio.
- Alternativa: usar `AnimatedOpacity` + `SizedBox` con ancho fijo para que el espacio esté siempre reservado.

**Impacto**: Elimina el molesto reflow al marcar/desmarcar items. Esfuerzo bajo.

---

### M12. Unificar estilos visuales de Login y Register

**Origen**: UI-14

**Problema**: Login y Register tienen estilos diferentes: Register usa una `Card` con `borderRadius: 28` como wrapper, Login no. Register tiene header con logo + nombre en fila, Login los tiene centrados en columna. Los campos usan el mismo estilo de fondo pero el layout general es inconsistente.

**Tarea**:
- Decidir un diseño unificado para ambas pantallas. Recomendación: usar la `Card` con `borderRadius: 28` en ambas (el diseño de Register es más pulido visualmente).
- Unificar logo y nombre de app como header consistente en ambas pantallas.
- Ambas deben tener el mismo padding horizontal y espaciado entre elementos.
- Si se implementa A1 y A2, el ⚙️ y el enlace de contraseña ya estarán funcionales.

**Impacto**: Consistencia visual en el flujo de autenticación. Esfuerzo medio.

---

### M13. autofillHints en campos de login y registro

**Origen**: UX-4

**Problema**: Los campos de email y contraseña no usan `autofillHints`. El usuario tiene que escribir manualmente cada vez, incluso cuando el gestor de contraseñas del dispositivo tiene los datos guardados.

**Tarea**:
- En `_Field` de Login: añadir `autofillHints: const [AutofillHints.email]` en el campo email y `autofillHints: const [AutofillHints.password]` en el campo contraseña.
- En `_Field` de Register: además de lo anterior, `autofillHints: const [AutofillHints.name]` en el campo nombre y `AutofillHints.newPassword` en contraseña.
- Si se migra a `AppTextField` (tarea UI-2.2), añadir soporte para `autofillHints` en el widget.

**Impacto**: Reduce fricción en login/registro. El gestor de contraseñas sugerirá credenciales guardadas. Esfuerzo bajo.

---

### M14. Indicador de total de items en listas paginadas

**Origen**: UX-5

**Problema**: Las listas con infinite scroll no muestran cuántos items hay en total. El usuario no sabe si quedan 5 o 500 items por cargar.

**Tarea**:
- La API ya devuelve `X-Total-Count` en las respuestas de listas. Recuperar este header en los datasources y exponerlo en los estados `Loaded` de los cubits.
- Mostrar en la UI: "Mostrando 20 de 150" o similar en un `Text` pequeño bajo la barra de búsqueda o en el footer de la lista.
- Aplicar en: WarehouseDetail, ProductList, WarehouseList, StockHistory, Notifications.
- Si el backend no expone `X-Total-Count` para algún endpoint, estimar con `hasMore` (indicador cualitativo).

**Impacto**: El usuario sabe cuánto contenido esperar. Reduce la incertidumbre del infinite scroll. Esfuerzo medio.

---

### M15. Tooltips en todos los IconButton

**Origen**: UI-6 / UX-9

**Problema**: Algunos `IconButton` tienen `tooltip`, otros no. Sin tooltip, el usuario no sabe qué hace el botón hasta que lo prueba (o hace long-press para ver el tooltip nativo en Android).

**Tarea**:
- Auditar todos los `IconButton` de la app y añadir `tooltip` descriptivo donde falte.
- Priorizar botones de acción: añadir/quitar stock, eliminar, checklist, compartir, menú contextual.
- Los tooltips ya presentes son correctos; verificar que no haya ninguno en inglés por error.
- Si un `IconButton` está acompañado de un `Text` (ej: `TextButton.icon`), el tooltip es redundante y puede omitirse.

**Impacto**: Mejora la accesibilidad y la descubribilidad de acciones. Esfuerzo bajo.

---

### M16. Semantics labels en elementos interactivos

**Origen**: UX-9

**Problema**: La app no tiene soporte para lectores de pantalla. Los usuarios con discapacidad visual no pueden usar la app.

**Tarea**:
- Añadir `Semantics` widgets en:
  - Cards de almacén y producto: `label` con el nombre y cantidad.
  - Stat buttons del dashboard: `label` descriptivo (ej: "Bajo stock: 5 productos").
  - Checkbox de shopping list: `label` con el nombre del producto.
  - Botones +/- de stock: `label` con la acción y producto.
  - Navegación: items del drawer, tabs.
- Usar `excludeFromSemantics: true` en elementos puramente decorativos (iconos de fondo, shadows, dividers).
- Verificar el orden de lectura con `SemanticsSortOrder` o `MergeSemantics` donde sea necesario.

**Impacto**: Hace la app usable con TalkBack/VoiceOver. Esfuerzo medio (auditoría por pantalla).

---

### M17. AnimatedTheme para cambio claro/oscuro

**Origen**: UI-7

**Problema**: El cambio entre tema claro y oscuro es instantáneo. No hay transición visual; la pantalla "parpadea" al nuevo tema.

**Tarea**:
- Envolver `MaterialApp` con `AnimatedTheme` en lugar de cambiar directamente el `theme`/`darkTheme`.
- Configurar `duration: Duration(milliseconds: 400)` y `curve: Curves.easeOut`.
- Esto requiere que `ThemeCubit` emita el `ThemeData` completo (claro u oscuro) que `AnimatedTheme` animará.
- Alternativa si `AnimatedTheme` es demasiado complejo: usar `themeAnimationDuration` y `themeAnimationCurve` en `MaterialApp` (Flutter 3.22+).

**Impacto**: Transición suave entre temas que se siente premium. Esfuerzo bajo.

---

### M18. AnimatedList en warehouse detail para cambios de stock

**Origen**: UX-5 / UI-9

**Problema**: Al añadir o quitar stock con los botones +/- en WarehouseDetail, la lista se recarga completamente desde la API. Los items "saltan" a su nueva posición sin animación.

**Tarea**:
- Reemplazar `ListView.separated` por `AnimatedList` en WarehouseDetail.
- Al hacer quickUpdate (+/-), en lugar de recargar toda la lista desde la API, actualizar solo el item modificado con animación.
- La animación puede ser un `FadeTransition` + `SizeTransition` sutil en el item actualizado.
- Mantener la recarga desde API solo en pull-to-refresh y cambios de filtro.

**Impacto**: Los cambios de stock se sienten fluidos e instantáneos. Esfuerzo alto.

---

### M19. Eliminación optimista con revert

**Origen**: UX-2

**Problema**: Las eliminaciones bloquean la UI con "Eliminando…" mientras se procesan. El usuario espera sin feedback hasta que la operación completa.

**Tarea**:
- Implementar eliminación optimista: remover el item de la UI inmediatamente al confirmar, y luego:
  - Si la API responde OK: mostrar SnackBar con "Deshacer" (complementa tarea A9).
  - Si la API falla: revertir el item a la lista y mostrar SnackBar de error.
- Esto evita el estado "Eliminando…" con spinner bloqueante.
- Aplicar en: WarehouseDetail, ProductList, WarehouseList, BrandList, CategoryList, StoreList.
- Para eliminaciones batch: aplicar el mismo patrón — desaparecer todos los items, revertir en grupo si falla.

**Impacto**: La app se siente instantánea. Las eliminaciones no bloquean la UI. Esfuerzo alto (implica cambios en los cubits).

---

### M20. Diálogo de confirmación al salir de formularios

**Origen**: UX-3 / UX-4

**Problema**: Solo `RegisterScreen` tiene confirmación al intentar salir con datos escritos. Los formularios de crear/editar producto, almacén, marca, categoría y tienda no protegen contra pérdida de datos.

**Tarea**:
- Añadir `WillPopScope` (o `PopScope` en Flutter 3.12+) en:
  - `ProductFormScreen`
  - `WarehouseFormScreen`
  - Diálogos de edición de marca/categoría/tienda
- El callback debe detectar si hay cambios sin guardar (comparar valores iniciales con actuales) y mostrar `ConfirmDialog`:
  - "¿Salir sin guardar? Los cambios se perderán."
  - Botones: "Descartar" / "Seguir editando".
- Si no hay cambios, permitir salir directamente sin diálogo.

**Impacto**: Previene pérdida de datos en formularios largos. Esfuerzo medio.

---

### M21. Notificaciones locales con deep-link

**Origen**: UX-3

**Problema**: Las notificaciones locales (`showLowStockNotification`, `showExpiryNotification`) muestran alertas en el sistema pero al tocarlas solo abren la app, no navegan al producto afectado.

**Tarea**:
- Añadir `payload` a las notificaciones locales con el `productId` y `warehouseId`.
- En el handler de notificaciones (cuando el usuario toca la notificación), leer el payload y navegar a la pantalla correspondiente:
  - Low stock: `/products/:warehouseProductId/detail?warehouseId=X`
  - Expiry: misma ruta con scroll a sección de lotes.
- Esto requiere que `NotificationService` tenga acceso al `AppNavigator` o que el handler esté en `main.dart`/`app.dart`.

**Impacto**: Las notificaciones del sistema se convierten en atajos directos a la acción. Esfuerzo medio.

---

## Prioridad Baja

Mejoras de pulido, detalles premium y funcionalidades aspiracionales. Implementar cuando las prioridades alta y media estén cubiertas.

---

### B1. Indicador de fortaleza de contraseña en registro

**Origen**: UX-4 / UI-14

**Tarea**: Añadir una barra de progreso bajo el campo de contraseña en `RegisterScreen` que indique la fortaleza (débil, media, fuerte) basada en longitud, mayúsculas, números y caracteres especiales. La barra usa colores semánticos: rojo → ámbar → verde.

**Impacto**: Mejora la seguridad y da feedback inmediato. Esfuerzo bajo.

---

### B2. TextInputAction.next en formularios

**Origen**: UX-4

**Tarea**: En Login: `TextInputAction.next` en email → foco a contraseña. En Register: `TextInputAction.next` en nombre → email → contraseña → confirmar. En ProductForm: `next` entre campos. Esto requiere `FocusNode` y `onFieldSubmitted` para mover el foco.

**Impacto**: Ahorra taps al rellenar formularios. Esfuerzo bajo.

---

### B3. "Seleccionar todo" / "Deseleccionar todo" en shopping list

**Origen**: NAV-17 / UX-8

**Tarea**: Añadir opciones "Seleccionar todo" y "Deseleccionar todo" en el menú ⋮ de ambas tabs de shopping list. Al seleccionar, todos los checkboxes visibles (respetando filtros activos) se marcan. Esto acelera el flujo de compra cuando el usuario quiere comprar todo.

**Impacto**: Ahorra taps en listas grandes. Esfuerzo bajo.

---

### B4. Búsqueda local en warehouse detail

**Origen**: NAV-13

**Tarea**: Actualmente la búsqueda en WarehouseDetail hace una llamada a la API con debounce 400ms. Para búsquedas sobre datos ya cargados (página actual), filtrar localmente en memoria para respuesta instantánea. Solo ir a API si se busca algo que no está en los datos locales. Hacer lo mismo para ProductList y WarehouseList.

**Impacto**: Búsqueda instantánea en la mayoría de casos. Esfuerzo medio.

---

### B5. Barra de búsqueda en ayuda

**Origen**: NAV-22

**Tarea**: Añadir un `TextField` de búsqueda en `HelpScreen` que filtre las preguntas/respuestas por palabra clave. Buscar en los títulos de sección y en el texto de las preguntas. Expandir automáticamente la sección que contiene el match.

**Impacto**: El usuario encuentra respuestas rápido sin leer toda la ayuda. Esfuerzo bajo.

---

### B6. Biometría en login

**Origen**: NAV-7 / UI-14

**Tarea**: Añadir autenticación biométrica (huella / Face ID) en `LoginScreen`. Usar el paquete `local_auth`. Al detectar biometría disponible, mostrar un botón con icono de huella bajo "Iniciar sesión". La biometría desbloquea usando el token JWT almacenado. Si el token expiró, pedir login manual. Requiere guardar las credenciales de forma segura en el primer login exitoso.

**Impacto**: Comodidad para usuarios frecuentes. Esfuerzo medio (requiere configuración nativa en iOS y Android).

---

### B7. Hero animations

**Origen**: UX-6 / UI-9

**Tarea**: Implementar `Hero` animation en transiciones donde haya un elemento visual compartido:
- Icono/imagen de warehouse del dashboard → warehouse detail.
- Imagen de producto de la lista → detalle de producto.
- Icono de producto de search → detalle.
Usar `tag` único (ej: `'warehouse-${id}'`, `'product-${id}'`). Envolver el elemento origen y destino con `Hero` widget.

**Impacto**: Da continuidad visual y profesionalismo. Esfuerzo bajo (por transición).

---

### B8. Coach marks en shopping list (primer uso)

**Origen**: UX-8

**Tarea**: La primera vez que un usuario entra a ShoppingList, mostrar tooltips/coach marks que señalen elementos clave: "Toca el check para marcar productos a comprar", "Usa +/- para ajustar cantidades", "Pulsa ✨ para generar la lista automáticamente". Usar una implementación simple con `Overlay`. Guardar en `StorageService` que ya se mostró el tutorial.

**Impacto**: Onboarding contextual sin abrumar. Esfuerzo medio.

---

### B9. Preview de generación automática de lista

**Origen**: UX-8

**Tarea**: Antes de ejecutar `generate()` o `generateAll()` en ShoppingList, hacer una llamada preview (si la API lo soporta) o generar localmente y mostrar un diálogo con: "Se generarán 12 productos para comprar: Leche (3 uds), Pan (2 uds)..." con opción de confirmar o cancelar.

**Impacto**: Transparencia y control sobre la generación automática. Esfuerzo medio.

---

### B10. Ilustraciones SVG en onboarding

**Origen**: UI-13

**Tarea**: Reemplazar los iconos de Material en `WelcomeScreen` (círculo con icono) por ilustraciones SVG custom que representen visualmente cada slide: persona escaneando producto, almacén organizado, gráficos de stock, app en mano. Las ilustraciones deben seguir la paleta de la app (verde + púrpura).

**Impacto**: Onboarding más atractivo y memorable. Esfuerzo alto (requiere diseño gráfico).

---

### B11. NavigationRail en tablets

**Origen**: UI-8

**Tarea**: En pantallas con ancho >= 600dp, reemplazar el drawer + bottom nav por un `NavigationRail` lateral fijo. Los destinos son los mismos que el bottom nav. Esto aprovecha el espacio horizontal de tablets. Requiere `MediaQuery` o `LayoutBuilder` para detectar el ancho.

**Impacto**: Experiencia óptima en tablets y desktop. Esfuerzo alto.

---

### B12. Logo animado en splash screen

**Origen**: UI-10

**Tarea**: Reemplazar el logo estático + spinner en `SplashScreen` por una animación: logo con `ScaleTransition` (de 0.8 a 1.0) + `FadeTransition` del nombre "InvesVault" apareciendo debajo. Duración total ~1.5s. Si la verificación de auth tarda más, la animación se completa y luego se muestra un spinner pequeño.

**Impacto**: Primera impresión pulida y profesional. Esfuerzo medio.

---

### B13. Unificar _DeleteModeBar de shopping list con DeleteModeBar

**Origen**: UI-12

**Tarea**: ShoppingList tiene su propio `_DeleteModeBar` (widget privado) que duplica la funcionalidad de `DeleteModeBar` (widget compartido). Migrar para usar el widget compartido. Si hay diferencias necesarias, extender `DeleteModeBar` con parámetros adicionales en lugar de duplicar.

**Impacto**: Mantenibilidad y consistencia. Esfuerzo bajo.

---

### B14. Migrar _EmptyState de search a EmptyView

**Origen**: UI-12

**Tarea**: `GlobalSearchScreen` usa su propio widget `_EmptyState` inline en lugar del `EmptyView` compartido. Migrar para usar `EmptyView` con los parámetros adecuados (icono, mensaje, acción opcional "Crear nuevo producto").

**Impacto**: Consistencia de estados vacíos. Esfuerzo bajo.

---

### B15. Modo offline básico

**Origen**: UX-7

**Tarea**: Cachear los datos del dashboard y las últimas listas consultadas en `SharedPreferences` o `Hive`. Si no hay conexión, mostrar los datos cacheados con un indicador "Sin conexión — datos del [fecha/hora]" y un botón de reintentar. No implementar cola de operaciones offline (demasiado complejo). Solo lectura offline.

**Impacto**: La app es usable sin conexión para consulta. Esfuerzo alto.

---

## Resumen por Categoría

| Categoría | Alta | Media | Baja | Total |
|-----------|------|-------|------|-------|
| Navegación global | 1 | 1 | 1 | 3 |
| Pantallas auth | 2 | 2 | 2 | 6 |
| Estados de carga/feedback | 4 | 1 | — | 5 |
| Feedback y prevención errores | 1 | 4 | — | 5 |
| Animaciones | 1 | 3 | 1 | 5 |
| Componentes y consistencia | 2 | 3 | 2 | 7 |
| Flujos específicos | 2 | 1 | 2 | 5 |
| Diseño visual y tema | 2 | 3 | 1 | 6 |
| Accesibilidad | 2 | 2 | — | 4 |
| Premium / Detalles | — | — | 6 | 6 |
| **Total** | **17** | **21** | **14** | **52** |

---

## Orden de Ejecución Recomendado

### Fase 1 — Correcciones rápidas (Alta, esfuerzo bajo) ✅
Ejecutadas:
~~A1~~, ~~A3~~, ~~A6~~, ~~A7~~, ~~A8~~, ~~A11~~, ~~A12~~, ~~A13~~

### Fase 2 — Funcionalidad core (Alta, esfuerzo medio)
A2, ~~A4~~, ~~A5~~, ~~A9~~, A10, A14, ~~A15~~

### Fase 3 — Consistencia y pulido (Media)
M2, M4, M5, M9, M11, M12, M13, M15, M16, M17

### Fase 4 — Mejoras estructurales (Media, esfuerzo alto)
M1, M3, M6, M7, M8, M10, M14, M18, M19, M20, M21

### Fase 5 — Detalles premium (Baja)
B1 a B15 en orden de valor-impacto, priorizando B3, B6, B7, B13, B14 por su bajo esfuerzo.
