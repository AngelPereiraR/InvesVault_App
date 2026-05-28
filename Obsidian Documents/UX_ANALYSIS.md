# Análisis UX — InvesVault App

## 1. Navegación y Arquitectura de la Información

### Estado actual

| Aspecto | Descripción |
|---------|-------------|
| Navegación principal | **Drawer lateral** (hamburger menu) accesible desde `app_shell.dart` |
| Rutas | 30+ rutas nombradas con regex para rutas dinámicas (`app_router.dart:335`) |
| Shell | `IndexedStack` preserva estado entre secciones, navegación auxiliar para detalle |
| Profundidad | Hasta 3 niveles: Shell > Lista > Detalle/Formulario |

### Pros actuales

- **IndexedStack** conserva el estado de scroll y datos entre pestañas — excelente para productividad
- Las rutas auxiliares (`openAuxiliaryRoute`) separan conceptualmente flujos principales de detalles/edit
- Navegación bi-direccional (`loadMore` + `loadPrevious`) es inusual y sofisticada
- `AppNavigator` singleton proporciona navegación programática desacoplada del BuildContext

### Contras actuales

- Drawer lateral requiere 2 taps (abrir > seleccionar) vs 1 tap en bottom nav bar
- Sin breadcrumb ni indicador de ubicación ("¿dónde estoy?")
- Las secciones del drawer no cambian visualmente al estar activas (sin highlight del item actual)
- La mezcla de `push`, `go`, `replaceAll` crea inconsistencia en el historial de navegación
- Sin gestos de swipe entre secciones principales

### Propuesta de mejora

- **Bottom Navigation Bar** con 4-5 secciones principales + drawer para secundarias
- Añadir **indicador visual** en el drawer del destino activo
- Unificar el patrón de navegación (usar `go()` consistentemente dentro del shell)
- Soporte de **swipe gesture** entre tabs principales (usando `PageView` en lugar de `IndexedStack`)

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Acceso instantáneo a secciones frecuentes | Menos espacio vertical disponible |
| Descubribilidad mucho mayor | Requiere repensar jerarquía de secciones |
| Patrón familiar (Instagram, WhatsApp, etc.) | Necesita iconos claros para cada tab |
| Swipe más rápido que drawer | Posible conflicto con gestos de lista horizontal |

---

## 2. Estados de Carga, Vacío y Error

### Estado actual

| Estado | Widget | Uso |
|--------|--------|-----|
| Carga | `LoadingIndicator` (CircularProgressIndicator centrado) | 16+ pantallas |
| Error | `ErrorView` (icono error + mensaje + botón reintentar) | 16+ pantallas |
| Vacío | `EmptyView` (icono + mensaje + acción opcional) | 12+ pantallas |
| Carga parcial | `LinearProgressIndicator` durante búsqueda | warehouse_detail, notifications |
| Batch | "Eliminando…" con spinner durante operaciones | delete_mode_bar |

### Pros actuales

- Consistencia total: las 3 vistas (loading/error/empty) se usan uniformemente en toda la app
- `ErrorView` incluye botón de reintento contextual
- `EmptyView` incluye acción sugerida (ej: "Añadir producto", "Generar automáticamente")
- `LinearProgressIndicator` mientras se busca es buen feedback de actividad
- Mensajes de error en español amigables (`error_messages.dart` traduce errores HTTP)

### Contras actuales

- **Sin skeleton screens**: carga full-screen con spinner = percepción de lentitud
- No hay diferenciación entre carga inicial y recarga (pull-to-refresh usa el mismo spinner)
- El `RefreshIndicator` existe solo en algunas pantallas (dashboard, warehouse_detail, notifications)
- Las operaciones de eliminación bloquean la UI con "Eliminando…" en lugar de eliminación optimista
- Sin indicador de progreso en operaciones batch (ej: eliminar 20 items — ¿cuántos van?)

### Propuesta de mejora

- Implementar **skeleton screens** (shimmer) en listas para carga inicial
- Usar eliminación **optimista** (remover item inmediatamente, revertir si falla) con SnackBar + Undo
- Pull-to-refresh en todas las listas
- Indicador de progreso `x/y` en operaciones batch
- `AnimatedSwitcher` entre estados para transiciones suaves

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Percepción de velocidad mucho mayor | Skeleton screens requieren diseño específico por layout |
| Eliminación optimista evita bloqueos | Riesgo de inconsistencia si falla (mitigado con undo) |
| Pull-to-refresh consistente da control al usuario | Más código boilerplate |

---

## 3. Feedback y Notificaciones al Usuario

### Estado actual

| Tipo | Implementación |
|------|---------------|
| SnackBar | Errores de formulario, confirmaciones (ej: "Perfil actualizado") |
| Diálogos | Confirmación de eliminación con `ConfirmDialog` (peligroso en rojo) |
| Local notifications | `showLowStockNotification()` y `showExpiryNotification()` |
| Badge | `NotificationBadge` en AppBar con contador de no leídas |
| Inline feedback | Cantidades que cambian a verde/naranja en shopping list |
| Progress | `CircularProgressIndicator` en botones durante submit |

### Pros actuales

- Diálogo de confirmación con variante `isDangerous` (rojo) para acciones destructivas — buena práctica
- Notificaciones locales nativas para alertas de stock bajo y caducidad
- Badge de notificaciones visible en AppBar
- Feedback visual en shopping list (compra completa = verde + tachado)
- Validación en tiempo real de formularios

### Contras actuales

- **SnackBars sin acción "Deshacer"**: al eliminar producto, se pierde sin recuperación
- Sin feedback háptico (vibración) en acciones importantes
- Sin toast/snackbar de éxito en operaciones create/update (solo "Perfil actualizado")
- Sin confirmación al navegar hacia atrás con datos sin guardar (excepto register screen)
- Notificaciones locales solo advierten, no navegan al producto clickeándolas
- El botón de ajustes en register_screen está vacío (`onPressed: () {}`)

### Propuesta de mejora

- SnackBar + **acción "Deshacer"** en eliminaciones (ej: eliminar producto de almacén)
- SnackBar de confirmación en creates/updates ("Producto añadido correctamente")
- **Feedback háptico** (`HapticFeedback.lightImpact()`) en taps de +/- stock
- Diálogo de confirmación al salir de formularios con cambios sin guardar (`WillPopScope`)
- Notificaciones locales con payload para **deep-link** al producto
- La acción de notificación local debería navegar al producto correspondiente

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Undo evita pérdida de datos accidental | Requiere mantener estado local para revertir |
| Confirmación al salir protege datos no guardados | Molesto si aparece muy frecuentemente |
| Deep-link desde notificación = flujo directo | Complejidad adicional en router |

---

## 4. Formularios y Entrada de Datos

### Estado actual

| Aspecto | Implementación |
|---------|---------------|
| Widget base | `AppTextField` reutilizable con label, hint, iconos, validación |
| Validación | `Validators.required()`, `.email()`, `.password()`, `.positiveNumber()` |
| Formularios | `login_screen`, `register_screen`, `product_form_screen`, `warehouse_form_screen` |
| Barcode | `BarcodeScannerScreen` con overlay frame, torch toggle, auto-pop al escanear |
| Búsqueda | Debounce 400ms en warehouse_detail y notifications |

### Pros actuales

- `AppTextField` reutilizable con buena API
- Barcode scanner con auto-detección, toggle de flash y cámara
- Términos y condiciones con checkbox en registro
- Formularios con scroll cuando el teclado está visible (`SingleChildScrollView`)
- `back_button_interceptor` en register para confirmar abandono
- Búsqueda con debounce evita llamadas excesivas a la API
- Validación de contraseñas coincidentes en registro

### Contras actuales

- **Sin autocompletado**: campos de email/contraseña no usan `autofillHints`
- Sin indicador de fortaleza de contraseña en registro
- El formulario de producto no muestra campos condicionales (ej: precio solo si tiene store)
- Sin teclado numérico contextual en campos de cantidad (a veces usa `TextInputType.number`)
- No hay `TextInputAction.next` para navegar entre campos del formulario
- El barcode scanner no tiene animación de escaneo exitoso
- Sin vista previa de la imagen del producto al seleccionarla

### Propuesta de mejora

- Añadir `autofillHints` en campos de login/registro
- Indicador visual de fortaleza de contraseña (barra de progreso)
- `TextInputAction.next` y `FocusNode` para navegación entre campos con "siguiente"
- Animación de éxito en scanner (flash verde + vibración)
- Teclado numérico con `.decimal` solo en campos de precio/cantidad donde aplique
- Preview de imagen seleccionada en product_form

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Autocompletado reduce fricción de login | Requiere iOS/Android configuration |
| Navegación entre campos con "next" ahorra taps | Código adicional para focus traversal |
| Indicador de fortaleza mejora seguridad | UI adicional que puede saturar |

---

## 5. Listas, Grillas y Visualización de Datos

### Estado actual

| Patrón | Uso |
|--------|-----|
| GridView 2-columnas | warehouses, products, brands (parcial) |
| ListView con Divider | warehouse_detail, notifications, stock_history |
| ListView con cards | critical_stock, shopping_list, search |
| FilterChips horizontal | warehouse_detail (categorías), stock_history (tipo), shopping_list (tiendas) |
| Stat buttons | dashboard (3 cards horizontales con icono + valor) |
| Quick actions grid | dashboard (3x2 grid con icono circular + label) |

### Pros actuales

- FilterChips con scroll horizontal bien implementados
- Tarjetas con sombras consistentes y bordes redondeados (14-20px)
- Color coding semántico: stock bajo = rojo, éxito = verde, warning = naranja
- Shopping list con agrupación por categoría (opción de ordenamiento)
- Stat cards del dashboard con información clave resumida

### Contras actuales

- **Sin animaciones de lista**: añadir/eliminar items no tiene transición visual
- Sin **gestos de swipe** en listas (excepto notificaciones con Dismissible para borrar)
- Sin **sticky headers** en listas agrupadas por categoría (shopping list)
- Sin opción de cambiar vista (lista vs grid) — el usuario no puede elegir
- Las listas paginadas no muestran cuántos items totales hay
- Sin filtro de ordenación en warehouse_detail (solo search + category filter)
- Las imágenes de producto usan `Image.network` con `errorBuilder` pero sin placeholder mientras cargan
- Sin long-press para menú contextual (alternativa al tap-hold)

### Propuesta de mejora

- `AnimatedList` para inserciones/eliminaciones con animación
- Sticky headers en shopping list agrupada por categoría
- Toggle lista/grid persistente por preferencia de usuario
- Indicador de total de items ("Mostrando 20 de 150")
- Placeholder shimmer mientras cargan imágenes de producto
- Long-press para acciones rápidas (añadir stock, editar, eliminar)
- Swipe-to-action en listas (swipe izquierda = eliminar, swipe derecha = editar)

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Animaciones mejoran percepción de respuesta | Complejidad en AnimatedList |
| Vista configurable = personalización | Añade preferencia a persistir |
| Long-press y swipe agilizan tareas frecuentes | Riesgo de activación accidental |

---

## 6. Diseño Visual y Tema

### Estado actual

| Aspecto | Detalle |
|---------|---------|
| Sistema | Material 3 con ColorScheme personalizado |
| Paleta | Verde (primary) + Púrpura (secondary) + Neutrales |
| Tipografía | Roboto (headings), Open Sans (body) via Google Fonts |
| Tema oscuro | Soportado con toggle en settings |
| Radios | Consistentes 12-20px |
| Sombras | Sutil (0.04-0.05 opacity, blur 6-8) |

### Pros actuales

- Paleta de color coherente y profesional (verde = inventario, púrpura = profesional)
- Soporte completo de tema oscuro persistiendo preferencia
- Cards con sombras ligeras dan profundidad sin exagerar
- Tipografía clara y legible
- Iconografía consistente (Material Icons rounded)
- Uso de `colorScheme` del tema en lugar de colores hardcodeados

### Contras actuales

- **Sin animaciones entre pantallas**: las transiciones son instantáneas (sin fade/slide)
- Sin animación de transición al cambiar tema claro/oscuro (parpadeo)
- La AppBar púrpura con texto blanco puede tener bajo contraste en algunos fondos
- Sin micro-interacciones (botones sin animación de presión, salvo InkWell por defecto)
- Sin animación de splash/ripple personalizada
- Los iconos del drawer no coinciden exactamente con los de las secciones
- Imagen de producto fallback es un `CircleAvatar` gris poco atractivo

### Propuesta de mejora

- `pageTransitionsTheme` con animaciones suaves (fade through, shared axis)
- `AnimatedTheme` para transición suave entre claro/oscuro
- Micro-animaciones: scale down en tap de botones, fade in en cards al aparecer
- Placeholder de imagen de producto con icono + inicial del nombre
- Iconos del drawer consistentes con los de las acciones principales
- Hero animation al navegar de lista a detalle de producto

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Transiciones pulidas = app más profesional | Más complejidad en router |
| Hero da continuidad visual al navegar | Solo útil si comparten elemento visual |
| Micro-animaciones mejoran feedback táctil | Pueden ralentizar dispositivos antiguos |

---

## 7. Estado Persistido y Continuidad de Sesión

### Estado actual

| Dato | Persistencia |
|------|-------------|
| Token JWT | `FlutterSecureStorage` (encriptado) |
| Datos de usuario | Secure storage (id, name, email, role) |
| Tema | Secure storage (`theme_mode`) |
| Última actividad | Secure storage (7 días de expiración) |
| Estado de UI en shopping list | En memoria del cubit (no persiste entre kills) |
| Welcome visto | Secure storage (`welcome_seen`) |

### Pros actuales

- Token JWT almacenado de forma segura
- Renovación silenciosa de token via `X-Refreshed-Token`
- Expiración de sesión tras 7 días de inactividad (buena seguridad)
- Recordar preferencia de tema
- Recordar si ya vio el onboarding

### Contras actuales

- **Sin persistencia de estado de UI**: al matar la app, se pierden filtros seleccionados, orden, etc.
- Los datos del dashboard no se cachean — siempre se recargan
- No hay modo offline ni cola de operaciones pendientes
- El token refresh es silencioso: el usuario no sabe que su sesión se renovó
- No se guarda la última pantalla visitada (siempre vuelve al dashboard)
- Los `TextEditingController` no persisten su contenido entre navegaciones

### Propuesta de mejora

- Cachear datos del dashboard localmente (SharedPreferences/Hive) para carga instantánea
- Persistir filtros seleccionados y preferencias de ordenación (cubit state serialization)
- Insight de "última actualización" o "datos cacheados" con botón de refrescar
- Modo offline básico: cache de últimas listas consultadas

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Carga instantánea del dashboard | Datos pueden estar desactualizados |
| Recordar filtros ahorra re-configuración | Aumenta complejidad de estado |
| Offline = app usable sin conexión | Sincronización compleja (conflictos) |

---

## 8. Shopping List — Análisis Detallado

Esta es la pantalla más compleja (1891 líneas) y merece análisis separado.

### Estado actual

- **Dos tabs**: Tiendas (vista global) y Almacenes (vista por almacén)
- **Persistencia de UI en memoria**: cantidades planificadas, compradas, checks sobreviven a navegación
- **Debounced auto-save**: 800ms tras último tap de +/- se guarda al backend
- **Dos cantidades por item**: "A comprar" (plan) y "Ahora" (ejecución)
- **Feedback contextual**: verde si cubre el mínimo, tachado si compra completa
- **Multi-delete mode**: checkbox masivo + eliminar seleccionados
- **Info dialog**: explica cada funcionalidad con iconos
- **Sort modes**: alfabético y por categoría
- **Buy flow**: incrementa stock automáticamente y elimina de la lista

### Pros actuales

- Increíblemente completo y bien pensado
- Debounced auto-save sin recarga de UI = sensación instantánea
- Dos niveles de cantidad (plan vs ejecución) es un patrón de supermercado real
- Info dialog educativo (muchas apps no explican sus features)
- Persistencia de estado UI en memoria entre navegaciones
- El botón "Comprar" aparece/desaparece animado (`AnimatedSize`)
- Buy flow atómico: actualiza stock Y limpia la lista

### Contras actuales

- **Sin tutorial inicial**: el usuario descubre features explorando o leyendo el info dialog
- La UI es densa: 2 selectores de cantidad + checkbox + nombre + info en un card
- Sin animación al completar la compra (satisfacción visual)
- El mensaje "Compra parcial · quedarán X pendientes" puede confundir a usuarios nuevos
- Sin opción de "comprar todo" de un almacén sin marcar uno por uno
- La generación automática no muestra preview antes de ejecutar

### Propuesta de mejora

- **Tooltip/coach mark** la primera vez que se usa ("Toca el check para marcar lo que vas a comprar")
- "Seleccionar todo" / "Deseleccionar todo" en el menú de acciones
- Preview de generación automática antes de confirmar
- Animación de confetti o check animado al completar compra (gamificación ligera)
- Simplificar card: mostrar "A comprar" siempre, "Ahora" solo cuando está checked
- Resumen pre-compra: "Vas a comprar 8 productos de 3 tiendas por un total de 25 unidades"

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Coach marks guían sin abrumar | Requiere tracking de "first time" |
| Preview de generación evita sorpresas | Una llamada extra a la API |
| Select all ahorra taps en listas grandes | Puede activarse por error |
| Resumen pre-compra = confianza | UI adicional a mantener |

---

## 9. Accesibilidad

### Estado actual

| Aspecto | Estado |
|---------|--------|
| Text scaling | Parcial (childAspectRatio ajusta, pero no todos los layouts) |
| Semantic labels | No implementados |
| Screen reader | No probado/optimizado |
| Contraste | Variable (texto blanco sobre púrpura es OK, gris claro puede fallar) |
| Touch targets | Mayormente >= 48px (IconButtons cumplen) |

### Contras actuales

- Sin `Semantics` widgets en elementos interactivos
- Sin `excludeFromSemantics` en elementos decorativos
- Sin soporte para `accessibilityFeatures` (reduce motion, bold text, etc.)
- Los colores como ÚNICO indicador de estado (rojo = bajo stock) fallan para daltónicos
- Sin alternativa textual a iconos en acciones críticas

### Propuesta de mejora

- Añadir `Semantics` labels en iconos interactivos y cards
- Usar icono + texto (no solo color) para estados críticos
- `tooltip` en todos los `IconButton` (algunos ya lo tienen, no todos)
- Respetar `MediaQuery.of(context).boldText` y reducir animaciones según accesibilidad
- Asegurar ratio de contraste WCAG AA (4.5:1 para texto normal)

---

## 10. Rendimiento Percibido

### Estado actual

- **Bi-directional infinite scroll** (carga hacia arriba y abajo) — excelente para rendimiento
- Debounced search (400ms)
- `IndexedStack` preserva estado entre tabs
- `cached_network_image` para imágenes
- `const` widgets donde es posible

### Contras actuales

- No hay `ScrollController` con `initialScrollOffset` para restaurar posición
- Sin lazy loading de pantallas (todas las rutas cargan al inicio)
- Recargas completas al volver de detalle (no se conserva la página exacta)
- `buildWhen`/`listenWhen` no se usan consistentemente en todos los BlocBuilders

### Propuesta de mejora

- `AutomaticKeepAliveClientMixin` en pantallas de lista para preservar scroll
- `PageStorageKey` para restaurar posición de scroll exacta
- Usar `buildWhen` en todos los `BlocBuilder` para evitar rebuilds innecesarios
- Precargar imágenes de la siguiente página en infinite scroll

---

## Resumen de Prioridades

| Prioridad | Mejora | Impacto | Esfuerzo |
|-----------|--------|---------|----------|
| **Alta** | Bottom navigation bar | Descubribilidad | Medio |
| **Alta** | Skeleton screens en lugar de spinners | Percepción de velocidad | Medio |
| **Alta** | SnackBar con "Deshacer" en eliminaciones | Prevención de errores | Bajo |
| **Alta** | Animaciones de transición entre pantallas | Pulido profesional | Bajo |
| **Alta** | Placeholder en carga de imágenes | Experiencia visual | Bajo |
| **Media** | Pull-to-refresh en todas las listas | Control de usuario | Bajo |
| **Media** | Sticky headers en listas agrupadas | Navegación en lista | Medio |
| **Media** | Semantics/accesibilidad básica | Inclusividad | Medio |
| **Media** | Persistencia de filtros/preferencias | Continuidad | Medio |
| **Media** | Eliminación optimista con revert | Velocidad percibida | Alto |
| **Baja** | Hero animations | Detalle visual | Bajo |
| **Baja** | Coach marks en shopping list | Onboarding | Medio |
| **Baja** | Preview generación automática | Confianza | Medio |
| **Baja** | Modo offline | Disponibilidad | Alto |

---

### Conclusión

La app tiene una base UX **sólida y consistente**: estados de carga/error/vacío uniformes, paleta de color coherente, patrones de búsqueda con debounce, formularios con validación, y una pantalla de shopping list excepcionalmente bien diseñada. Las áreas de mejora principales son: (1) la navegación con drawer que reduce descubribilidad, (2) la ausencia de skeleton screens y feedback optimista que impacta la percepción de velocidad, y (3) la falta de "deshacer" y confirmaciones de salida que protejan al usuario. Con mejoras incrementales enfocadas en estas 3 áreas, la experiencia pasaría de "funcional y correcta" a "pulida y profesional".
