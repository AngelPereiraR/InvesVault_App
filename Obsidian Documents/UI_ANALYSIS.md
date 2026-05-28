# Análisis UI — InvesVault App

---

## 1. Sistema de Diseño y Tokens

### Estado actual

| Token | Definición | Valor |
|-------|-----------|-------|
| Familia tipográfica | Roboto + Open Sans vía Google Fonts | `app_theme.dart:15-49` |
| Paleta verde | 6 tonos de menta a bosque | `AppGreens` (`app_colors.dart:4-11`) |
| Paleta púrpura | 6 tonos de lavanda a casi negro | `AppPurples` (`app_colors.dart:14-21`) |
| Paleta neutral | 6 tonos blanco a negro | `AppNeutrals` (`app_colors.dart:24-32`) |
| Radios de borde | 8px - 20px según componente | `app_theme.dart` |
| Sombras | `0.04`-`0.05` opacidad, blur 6-8, offset (0,2) | `app_colors.dart:64-65` |
| Material | Material 3 (`useMaterial3: true`) | `app_theme.dart:54` |

### Pros actuales

- **Sistema de tokens completo**: 3 paletas definidas (verde, púrpura, neutral) más colores semánticos con nombres descriptivos
- Las paletas tienen progresión tonal consistente (c100-c600) que facilita variaciones claro/oscuro
- `ColorScheme` de Material 3 completo con 12+ propiedades mapeadas en ambos temas
- Radios de borde usan valores convencionales (8, 10, 12, 14, 20) sin decimales arbitrarios
- Sombras sutiles y consistentes: mismo patrón `opacity + blur + offset` en todas las cards
- Separación clara entre colores de paleta (`AppGreens`, `AppPurples`) y colores semánticos (`AppColors`)

### Contras actuales

- **Sin espaciado estandarizado**: paddings/margins varían libremente (10, 12, 14, 16, 20, 24...) sin sistema de escala
- Sin tipografía responsiva (`textScaler` se usa puntualmente en dashboard pero no globalmente)
- `GoogleFonts` carga fuentes bajo demanda (potencial flicker si no están cacheadas)
- `secondaryContainer` del tema claro usa `AppPurples.c500` (#5A189A) que genera bajo contraste con texto oscuro
- Sin definición de `scrim` en el tema (backdrop de diálogos usa el default de Material)
- No hay `iconTheme` global (los iconos heredan colores del `ColorScheme` o se definen ad-hoc)

### Propuesta de mejora

- Definir escala de espaciado: `xs=4, sm=8, md=12, lg=16, xl=24, xxl=32`
- `textScaler` global en el `ThemeData` para escalado consistente
- Precargar Google Fonts en `main()` con `GoogleFonts.config.allowRuntimeFetching = false` + assets
- Revisar `secondaryContainer` en tema claro para cumplir ratio de contraste AA
- Definir `iconTheme` en `ThemeData` con tamaño y color por defecto
- Añadir `scrimColor` al `dialogTheme` para oscurecer fondo de diálogos

| Pros propuesta | Contras propuesta |
|----------------|-------------------|
| Escala de espaciado = consistencia total | Refactor de todos los paddings existentes |
| Fuentes precargadas evitan flicker | Aumenta tamaño de bundle |
| `textScaler` global = accesibilidad | Puede romper layouts que no usan widgets flexibles |

---

## 2. Componentes Atómicos

### 2.1 Botones

#### Estado actual

| Variante | Widget | Estilo |
|----------|--------|--------|
| Primary | `AppButton(variant: primary)` | `ElevatedButton` verde, radius 10, padding 24x14, Roboto 16 Medium |
| Secondary | `AppButton(variant: secondary)` | `OutlinedButton` borde verde, mismo padding |
| Danger | `AppButton(variant: danger)` | `ElevatedButton` rojo error, texto blanco |
| Text | `AppButton(variant: text)` | `TextButton` hereda estilo de tema |
| FAB | `FloatingActionButton` directo | Verde primary, sin variante `small` |
| IconButton | `IconButton` nativo | Sin estilo personalizado global |

#### Pros actuales

- `AppButton` encapsula 4 variantes con soporte de `loading`, `icon` y `fullWidth`
- Estado `loading` reemplaza label por `CircularProgressIndicator` de 20x20
- Variante `danger` usa `colorScheme.error` consistente
- `FilledButton` usado en diálogos de generación (Material 3)

#### Contras actuales

- **Botones inconsistentes**: algunos usan `AppButton`, otros usan `ElevatedButton`/`TextButton`/`OutlinedButton` directamente con estilos inline
- Sin variante `tonal` de Material 3 (ideal para chips/acciones secundarias)
- Sin `minimumSize` ni `tapTargetSize` definidos globalmente en el theme
- Los `ElevatedButton` inline definen sus propios estilos (color, padding, shape) duplicando la configuración del tema
- Sin estado `disabled` personalizado (hereda opacidad default de Material)
- `PopupMenuButton` no estandarizado (sin `AppPopupMenu`)
- La elevación `2` en `ElevatedButton` es inconsistente con `AppBar` que usa `0`

#### Propuesta de mejora

- Migrar todos los botones inline a `AppButton` o crear `AppFilledButton`, `AppTonalButton`
- Añadir variante `AppButtonVariant.tonal` para `FilledTonalButton`
- Definir `buttonTheme` centralizado con `minimumSize`, `tapTargetSize`, `splashFactory`
- Estilo `disabled` personalizado con opacidad controlada
- Unificar elevación de botones: `elevation: 0` con sombras vía `surfaceTintColor`

| Pros | Contras |
|------|---------|
| Consistencia 100% en botones | Más wrapping de widgets |
| Fácil cambiar estilo global desde un punto | Rigidez si se necesita un botón muy específico |
| Tonal button nativo de M3 | Requiere migración progresiva |

---

### 2.2 Campos de Texto

#### Estado actual

| Contexto | Implementación |
|----------|---------------|
| Tema global | `InputDecorationTheme`: filled blanco, radius 10, borde gris, padding 16x14 |
| `AppTextField` | Wrapper de `TextFormField` con label, hint, prefix/suffix icons, validación |
| Campos inline | `TextField` directo (search bars, add product sheet, register screen) |
| Auth screens | Campos custom con `filled: true`, `fillColor: primaryContainer`, sin borde |

#### Pros actuales

- `InputDecorationTheme` centralizado define el estilo base
- `AppTextField` parametriza `label`, `hint`, `prefixIcon`, `suffixIcon`, `validator`, `maxLines`, etc.
- Campos enfocados tienen borde verde de 2px (buena señal visual)
- Auth screens usan `fillColor: primaryContainer` (verde menta) que da identidad propia

#### Contras actuales

- **Inconsistencia de estilos**: auth screens usan `OutlineInputBorder` sin borde (`BorderSide.none`) mientras el tema global usa `BorderSide(color: border)`
- Search bars usan `TextField` en lugar de `SearchBar`/`SearchAnchor` de Material 3
- Campos en `_AddProductSheet` no usan `AppTextField` sino `TextField` directo con estilos inline
- Sin `isDense` ni `isCollapsed` configurados; el padding es fijo
- Sin `errorMaxLines` configurado (errores largos pueden desbordar)
- Los hints y labels usan misma familia pero diferente peso/color entre auth screens y el resto

#### Propuesta de mejora

- Usar `AppTextField` en TODOS los formularios (eliminar `TextField` inline)
- Configurar `errorMaxLines: 2` en el tema global
- Unificar estilo de auth screens con el tema global (o crear `AppTextField` variant `filled`)
- Adoptar `SearchBar` de Material 3 en lugar de `TextField` + búsqueda manual
- Añadir `floatingLabelBehavior: always` para consistencia

| Pros | Contras |
|------|---------|
| Un solo componente para todos los inputs | `AppTextField` necesitaría más parámetros |
| `SearchBar` nativo = mejor animación e integración | Requiere refactor de la lógica de búsqueda |
| `floatingLabelBehavior` = mejor UX en Material 3 | Cambio visual notable |

---

### 2.3 Cards y Tarjetas

#### Estado actual

| Tipo | Radio | Sombra | Borde |
|------|-------|--------|-------|
| `CardTheme` global | 12px | elevation 2, shadowLight | No |
| Dashboard stat buttons | 14px | `0.05` opacidad, blur 6 | `secondary` con 0.15 opacidad |
| Dashboard quick actions | 20px | Sin sombra (color sólido) | No |
| Dashboard warehouse cards | 14px | `0.05` opacidad, blur 6 | `secondary` con 0.15 opacidad |
| Low stock cards | 14px | Sin sombra (color sólido) | Rojo con 0.3 opacidad |
| Search result cards | 14px | `0.04` opacidad, blur 6 | No |
| Shopping list cards | 14px | `0.04` opacidad, blur 6 | Solo en delete mode (rojo) |
| Stock change cards | 14px | `0.04` opacidad, blur 6 | No |

#### Pros actuales

- Consistencia de radio: 14px es el radio dominante en cards custom
- Sombras sutiles uniformes (`0.04-0.05` opacidad, blur 6-8)
- Variación de color contextual (rojo para low stock, verde/ámbar para shopping list)
- `CardTheme` global provee fallback para widgets que usan `Card()` nativo
- Cards con `BoxDecoration` manual en lugar de `Card` widget dan más control

#### Contras actuales

- **Sin `Card` widget**: todas las cards se construyen con `Container` + `BoxDecoration` manual, perdiendo beneficios de `Card`
- Inconsistencia de radio: el `CardTheme` define 12px pero las cards reales usan 14px y 20px
- Sin `surfaceTintColor` de Material 3 en cards (degradado sutil que aporta elevación)
- Las quick actions del dashboard usan `Ink` + `InkWell` dentro de `Material` en lugar de `Card`
- Sin separación clara entre "card de contenido" y "card de acción" (mismo patrón visual)
- No existe componente `AppCard` reutilizable

#### Propuesta de mejora

- Crear `AppCard` con variantes: `elevated`, `filled`, `outlined` (inspirado en M3)
- Unificar radio de borde: 14px para todas las cards
- Usar `Card` widget nativo de Flutter en lugar de `Container` manual
- Aplicar `surfaceTintColor` para el efecto de elevación tonal de M3
- Definir `cardTheme` más completo en `ThemeData`

| Pros | Contras |
|------|---------|
| `AppCard` = consistencia + reutilización | `Container` actual da más flexibilidad |
| `Card` nativo = surfaceTint + mejor integración M3 | Migración masiva de widgets |
| Radio unificado = armonía visual | Menos diferenciación entre tipos de cards |

---

### 2.4 Diálogos

#### Estado actual

| Tipo | Radio | Elevación | Implementación |
|------|-------|-----------|---------------|
| `DialogTheme` global | 20px | 4 | `app_theme.dart:170-176` |
| `ConfirmDialog` | Heredado (20px) | 4 | `AlertDialog` con `ElevatedButton` danger opcional |
| Generate dialog | 20px | Default | `Dialog` widget manual |
| Add to warehouse | N/A (bottom sheet) | N/A | `showModalBottomSheet` radius 24 |
| Product info sheet | N/A (bottom sheet) | N/A | `showModalBottomSheet` radius 24 |
| Info dialog (shopping list) | 16px | Default | `AlertDialog` con radio inline |

#### Pros actuales

- `DialogTheme` global con radio 20px y elevación 4
- `ConfirmDialog` reutilizable con variante peligrosa (rojo)
- Bottom sheets con radio 24px consistente
- `DraggableScrollableSheet` en "añadir producto" permite ajustar altura

#### Contras actuales

- **Radio inconsistente**: info dialog usa 16px, el tema global usa 20px
- Sin `barrierDismissible` configurado globalmente (algunos diálogos permiten dismiss, otros no)
- Sin animación de entrada/salida personalizada
- Sin `insetPadding` estandarizado (unos usan horizontal 24 + vertical 40, otros default)
- El botón de cerrar en diálogos no es consistente (algunos usan `TextButton`, otros omiten)
- Bottom sheets no usan `showModalBottomSheet` con `useSafeArea: true` de forma consistente

#### Propuesta de mejora

- `AppDialog` widget base que extienda `AlertDialog` con estilos predefinidos
- `AppBottomSheet` wrapper para `showModalBottomSheet`
- `insetPadding` constante en todos los diálogos
- `barrierDismissible: false` por defecto en diálogos de acción
- Animación `ScaleTransition` para entrada de diálogos en lugar del fade default

| Pros | Contras |
|------|---------|
| Consistencia total en diálogos | Abstracción adicional |
| Animación personalizada = más pulido | Puede sentirse "pesado" en diálogos de confirmación |

---

## 3. Jerarquía Visual y Layout

### 3.1 Dashboard

#### Estado actual (`dashboard_screen.dart:606`)

```
┌────────────────────────────┐
│  [Bajo stock] [Catálogo]   │  ← 3 stat buttons (IntrinsicHeight Row, 14px radius)
│      [Lista compra]        │     Distribución equitativa con Expanded
├────────────────────────────┤
│  🔍 Buscar productos…  📷  │  ← Search bar (toca para navegar a /search)
│  [Accesos rápidos]         │  ← SectionTitle (púrpura, negrita)
│  ┌──────┬──────┬──────┐   │
│  │ Mov  │Nuevo │ Tiend│   │  ← Quick actions 3x2 grid
│  │ Marc │ Catá │Nuevo │   │     childAspectRatio ajustado por textScale
│  └──────┴──────┴──────┘   │
│  Mis almacenes    [3] [>]  │  ← SectionTitle + badge count
│  ┌─────────┬─────────┐    │
│  │ Almacén │ Almacén │    │  ← Warehouse cards 2-col grid
│  │  5 prod │  8 prod │    │     childAspectRatio 2.25
│  └─────────┴─────────┘    │
│  Stock crítico    [5] [>]  │  ← SectionTitle + badge count
│  ┌─────────────────────┐  │
│  │ ⚠ Producto B       │  │  ← Low stock rows (fondo rosa/rojo)
│  │ Stock: 3 / Mín: 10  │  │
│  └─────────────────────┘  │
└────────────────────────────┘
```

#### Pros actuales

- **Jerarquía clara**: secciones con `_SectionTitle` (púrpura, 16px, Bold) + contador badge
- `IntrinsicHeight` en los 3 stat buttons mantiene altura uniforme
- `GridView.count` con `shrinkWrap: true` + `NeverScrollableScrollPhysics` permite scroll padre
- Color coding efectivo: rojo para bajo stock, púrpura para catálogo, verde para lista
- `childAspectRatio` ajustado dinámicamente con `textScaler` evita desbordamiento con fuentes grandes
- Search bar con icono de QR scanner insinúa funcionalidad de escaneo

#### Contras actuales

- **Sin separación visual clara** entre secciones: solo `SizedBox(height: 18-28)` como espaciador
- Los stat buttons muestran texto genérico si `lowStockCount == 0` (el botón "Bajo stock" no tiene valor)
- Quick actions no tienen indicador de estado (ej: no se sabe si ya hay almacenes creados)
- Sin `SliverAppBar` ni comportamiento de collapse al hacer scroll
- El `EmptyView` ("No hay productos bajos de stock") usa un check verde que podría confundirse con "todo bien" vs "no hay datos"
- `MediaQuery.textScalerOf` cálculo inline duplicado en dos `GridView.count`

#### Propuesta de mejora

- Añadir `Divider` o `_SectionDivider` entre secciones para separación visual
- Quick actions con indicadores de cantidad (ej: "3 almacenes" en tile de "Nuevo almacén")
- `CustomScrollView` + `SliverAppBar` con colapso al hacer scroll
- Extraer el cálculo de `childAspectRatio` a un helper reutilizable
- All-low-stock `EmptyView` con icono `shield_check` en lugar de `check_circle` para distinguir

| Pros | Contras |
|------|---------|
| Separadores mejoran escaneabilidad | Añade elementos visuales extra |
| `SliverAppBar` = experiencia más dinámica | Complejidad de `CustomScrollView` + delegates |
| Quick actions con datos = más informativo | Mayor densidad de información |

---

### 3.2 AppBar y Drawer

#### AppBar (`app_shell.dart:148-211`)

| Propiedad | Valor |
|-----------|-------|
| Color fondo | `#3C096C` (shellAppBar) — púrpura muy oscuro |
| Texto | Blanco, Roboto, 20px Medium para título; 16px Bold en detalle almacén |
| Elevación | 0 (sin sombra) |
| Iconos | Blancos vía `iconTheme` |
| Acciones | Context-sensitive: `+` (crear), `✨` (generar lista en stores), notificaciones badge |

#### Drawer (`app_drawer.dart:331`)

```
┌────────────────────────────┐
│ 🟣 Header púrpura oscuro   │  ← Mismo color que AppBar
│   InvesVault v1.0.12       │     Logo 44x44 + nombre + versión
│   Nombre Usuario           │     Nombre 15px/600, email 12px/60% opacidad
│   email@ejemplo.com        │
├────────────────────────────┤
│ MENÚ INICIAL               │  ← Section headers 10px, 700, uppercase, letterSpacing 1.2
│   🏠 Inicio                │
│   🏭 Inventario            │  ← Items: icono 22px + texto 14px
│   🏪 Tiendas               │     Selected: verde primary, bold, fondo mint
│   🏷️ Marcas                │     Unselected: gris, regular
│   📁 Categorías            │
│   📦 Catálogo              │
│   🛒 Lista de compra       │
│   📜 Historial de cambios  │
├────────────────────────────┤
│ PRÓXIMAMENTE               │
│   📤 Importar datos  [Pronto] │  ← ComingSoonTile: opacidad 0.5, badge "Pronto" verde
│   📥 Exportar datos  [Pronto] │
│   🗑️ Datos eliminados [Pronto]│
│   💾 Copia seguridad [Pronto] │
│   ⚙️ Configuración          │  ← Item activo (no "próximamente")
├────────────────────────────┤
│ SOPORTE                    │
│   ❓ Ayuda y tutoriales    │
│ SOPORTE · Próximamente     │
│   🎧 Asistencia   [Pronto] │
│   📰 Noticias     [Pronto] │
│   💡 Sugerencias  [Pronto] │
├────────────────────────────┤
│   🔄 Reiniciar   [Próximamente] │
│   🚪 Cerrar sesión (rojo)  │
└────────────────────────────┘
```

#### Pros actuales

- **Header con identidad**: logo + nombre de app + datos de usuario en púrpura corporativo
- Drawer con **secciones agrupadas** y headers en mayúsculas (buena organización)
- "Próximamente" con badge verde consistente y opacidad reducida (expectativa gestionada)
- Item activo con highlight visual: color primario, negrita, fondo mint
- "Cerrar sesión" en rojo para acción destructiva (consistente con el resto de la app)
- Divider personalizado (`_Divider`) con indent/endIndent 16px

#### Contras actuales

- **2 secciones "Próximamente"**: una para datos y otra para soporte — confuso, debería ser una sola
- "Soporte" tiene un item activo (Ayuda) y luego otro header "Soporte · Próximamente" — inconsistente
- "Reiniciar" tiene badge "Próximamente" (con tilde) mientras los ComingSoonTile usan "Pronto" — inconsistencia de texto
- El `_mintBg` del drawer en tema claro (`#F2FBF4`) es casi blanco — poca diferenciación del scaffold background (`#ECECEC`)
- Los iconos del drawer no coinciden exactamente con los iconos usados en las pantallas (ej: Inventory usa `warehouse_outlined` vs `inventory_2_outlined`)
- Sin `SafeArea` bottom en el drawer (los últimos items pueden quedar bajo la barra de navegación del sistema)
- El drawer scroll es `ListView` dentro de `SafeArea` sin `bottom: false` — comportamiento inconsistente

#### Propuesta de mejora

- Unificar secciones "Próximamente" en una sola
- Mover "Configuración" a una sección propia (no dentro de "Próximamente")
- Badge "Próximamente" con texto consistente (siempre con tilde o siempre sin)
- Iconos del drawer 100% coincidentes con los de las pantallas de destino
- Usar `ExcludeFocus` + `Semantics` para items deshabilitados
- `SafeArea` con `bottom: true` en todo el drawer

| Pros | Contras |
|------|---------|
| Consistencia en badges y secciones | Tiempo de refactor |
| Iconos matching = affordance visual | Cambiar iconos en pantallas de destino |
| SafeArea correcto en todos los dispositivos | Mínimo esfuerzo |

---

### 3.3 Shopping List Cards

#### Estado actual (card visual en `shopping_list_screen.dart`)

```
┌──────────────────────────────────────────────┐
│ [✓] Leche entera                      A comprar │
│     🏪 Supermercado Centro              [- 5 +]  │
│     Mínimo sugerido: 3 uds             Ahora     │
│     ✅ Compra completa · se eliminará   [- 3 +]  │
│                                        🗑️        │
└──────────────────────────────────────────────┘
```

- **Checkbox**: determina si el item se incluye en la compra
- **Nombre del producto**: 14px, `w600`, color secundario (púrpura); tachado si compra completa
- **Warehouse/tienda**: 11px, púrpura con 55% opacidad, `w500` (solo en tab Tiendas)
- **Mínimo sugerido**: 11px, aparece solo si `alertGap > 0`
- **Feedback de compra**: 11px, verde (completa) o ámbar (parcial)
- **A comprar**: contador +/- columna derecha, texto "A comprar" 10px gris
- **Ahora**: segunda columna de contador +/- (solo si checked), texto "Ahora" 10px verde
- **Delete**: `IconButton` rojo 20px al extremo derecho

#### Colores de fondo contextuales

| Estado | Fondo |
|--------|-------|
| Normal no checked | `surface` (blanco) |
| Checked + buyAll | Verde éxito con 15% opacidad |
| Checked + !buyAll | Ámbar warning con 15% opacidad |
| Delete mode seleccionado | `errorContainer` (rojo) + borde rojo 1.5px |

#### Pros actuales

- **Densidad de información bien gestionada**: 7 elementos en una card sin sentirse abrumadora
- Codificación por color + estado (fondo verde = completo, ámbar = pendiente, rojo = seleccionado para borrar)
- `AnimatedSize` en el botón "Comprar" da feedback de disponibilidad
- Checkbox + contadores independientes permiten granularidad fina (planificar vs ejecutar)
- Tachado del nombre cuando se completa la compra da cierre visual

#### Contras actuales

- **Card muy ancha en landscape** o tablets: no tiene `maxWidth`
- La segunda columna "Ahora" solo aparece si checked, causando **reflow del layout** (ancho de card cambia)
- Sin `ConstrainedBox` en la card: en pantallas pequeñas, los selectores de cantidad pueden quedar muy comprimidos
- Sin `Divider` entre nombre y metadata — todo es texto con diferente tamaño
- El `PopupMenuButton` con "Más acciones" (en ProductListTile) no existe en shopping list — inconsistencia
- La card está construida con `Row` anidado manual, no con un layout grid predecible

#### Propuesta de mejora

- `LayoutBuilder` o `maxWidth` constraint para cards en pantallas grandes
- Mantener el espacio para "Ahora" siempre visible (opacity 0 cuando no checked) para evitar reflow
- Añadir un `Divider` sutil entre el nombre y la metadata
- Extraer la card a un widget `ShoppingListItemCard` reutilizable
- `Wrap` en lugar de `Row` para los contadores en pantallas muy estrechas

| Pros | Contras |
|------|---------|
| Sin reflow = layout estable | Espacio reservado "vacío" cuando no se usa |
| Cards con maxWidth evitan estiramiento | Menos contenido visible en landscape |
| ShoppingListItemCard facilitaría tests | Refactor significativo |

---

## 4. Tipografía

### Estado actual (`app_theme.dart:8-49`)

| Rol | Familia | Tamaño | Peso | Uso |
|-----|---------|--------|------|-----|
| `displayLarge` | Roboto | 24px | 700 | Títulos de página |
| `titleLarge` | Roboto | 20px | 500 | Títulos de tarjeta/sección |
| `titleMedium` | Roboto | 18px | 500 | Títulos secundarios |
| `titleSmall` | Roboto | 16px | 500 | Subtítulos |
| `bodyLarge` | Open Sans | 16px | 400 | Cuerpo principal |
| `bodyMedium` | Open Sans | 14px | 400 | Texto de apoyo |
| `bodySmall` | Open Sans | 14px | 400 | Texto secundario |
| `labelLarge` | Open Sans | 14px | 500 | Etiquetas |
| `labelMedium` | Open Sans | 12px | 500 | Etiquetas pequeñas |
| `labelSmall` | Open Sans | 12px | 400 | Texto muy pequeño |

### Pros actuales

- **Dos familias con propósito claro**: Roboto para headings (geométrica, impacto), Open Sans para body (legibilidad)
- Escala tipográfica completa definida en `TextTheme`
- Pesos diferenciados: 700 (Bold), 500 (Medium), 400 (Regular)
- `bodyMedium` y `bodySmall` comparten mismo tamaño (14px) pero tienen diferente propósito semántico

### Contras actuales

- **`bodyMedium` y `bodySmall` son idénticos** (misma familia, tamaño, peso, color) — sin diferenciación real
- **Tipografía ad-hoc por toda la app**: muchos textos usan `TextStyle` inline en lugar de `Theme.of(context).textTheme.*`
- Inconsistencia de pesos: títulos de sección en dashboard usan `w700` con `fontSize: 16` (no coincide con `titleSmall`)
- Sin `headlineMedium` ni `headlineSmall` definidos (huecos en la escala)
- Los `fontSize` inline usan valores como 11, 13, 15, 17, 24, 26 sin correlación con la escala tipográfica
- No se usa `DefaultTextStyle` ni `AnimatedDefaultTextStyle` para transiciones
- Sin `TextHeightBehavior` configurado (puede causar problemas con fuentes no latinas)

#### Propuesta de mejora

- Diferenciar `bodySmall` (12px 400) de `bodyMedium` (14px 400)
- Migrar estilos inline a tokens del `TextTheme`
- Documentar uso de cada token tipográfico (cuándo usar `titleLarge` vs `titleMedium`)
- Definir `headlineMedium` (28px) y `headlineSmall` (24px)
- `TextHeightBehavior` con `applyHeightToFirstAscent` y `applyHeightToLastDescent`

| Pros | Contras |
|------|---------|
| Tipografía 100% basada en tokens | Migración de más de 200 estilos inline |
| Escala completa = flexibilidad | Los estilos inline actuales son "intencionales" |
| Documentación = onboarding de devs | Requiere mantenimiento del doc |

---

## 5. Color y Contraste

### Estado actual

#### Tema claro

| Elemento | Color | Contraste sobre blanco |
|----------|-------|----------------------|
| Primary (verde) | `#40916C` | 3.6:1 ⚠️ (sobre blanco) |
| Secondary (púrpura) | `#7B2FBE` | 6.5:1 ✅ |
| Texto primario | `#121212` | 18.1:1 ✅ |
| Texto secundario | `#424242` | 8.6:1 ✅ |
| Texto hint | `#9E9E9E` | 2.9:1 ❌ (sobre blanco) |
| Danger (rojo) | `#EF4444` | 4.1:1 ⚠️ |
| Success (verde) | `#74C69D` | 1.8:1 ❌ (sobre blanco) |
| AppBar fondo | `#3C096C` | — |
| AppBar texto | blanco | 13.4:1 ✅ (sobre #3C096C) |

#### Tema oscuro

| Elemento | Color | Contraste sobre `#1E1E1E` |
|----------|-------|--------------------------|
| Primary | `#74C69D` | 4.4:1 ⚠️ |
| Secondary | blanco | 14.7:1 ✅ |
| Error | `#FF8585` | 4.6:1 ⚠️ |
| Texto | `#F5F5F5` | 13.7:1 ✅ |
| surfaceContainerHighest | `#2C2C2C` | — |

#### Pros actuales

- Texto primario tiene excelente contraste en ambos temas (>13:1)
- AppBar con fondo oscuro + texto blanco = contraste seguro
- `secondaryContainer` del tema oscuro (`#10002B`) con texto blanco da buen contraste
- Paleta bien documentada con comentarios

#### Contras actuales

- **`AppColors.success` (`#74C69D`) no cumple AA**: ratio 1.8:1 sobre blanco — ilegible como texto
- `AppColors.primary` (`#40916C`) tiene ratio 3.6:1 — no cumple AA (4.5:1) como texto, aunque se usa como fondo de botones
- `textHint` (`#9E9E9E`) tiene ratio 2.9:1 — no cumple AA ni para texto grande (3:1)
- El `secondaryContainer` del tema claro (`#5A189A`) se usa como fondo de chips pero el texto `onSecondaryContainer` es blanco — el contraste real depende del contexto
- Las cards de low stock usan `#FDE2E4` (rosa claro) con texto negro en tema claro — contraste OK, pero en tema oscuro usan `errorContainer` (`#4A1515`) con `onSurface` (texto claro) — ratio depende
- El éxito/verde se usa como color de texto en shopping list pero `#74C69D` es demasiado claro para texto sobre fondo blanco
- Sin uso de `ColorFilter` o `BlendMode` para adaptar iconos coloreados en dark mode

#### Propuesta de mejora

- Oscurecer `AppColors.success` para texto (sugerido: `#2D6A4F` = `AppGreens.c500`)
- Usar `AppColors.primaryDark` (`#2D6A4F`) para texto sobre fondo claro
- `textHint` mínimo `#757575` para ratio AA (4.6:1 sobre blanco)
- Verificar `onPrimaryContainer` y `onSecondaryContainer` en todos los contextos de uso
- Test automatizado de contraste con paquete `contrast_checker`

| Pros | Contras |
|------|---------|
| Cumplimiento AA = accesibilidad | Cambio de colores puede alterar identidad visual |
| Texto legible para todos los usuarios | Oscurecer success lo acerca a primary |

---

## 6. Iconografía

### Estado actual

| Propiedad | Valor |
|-----------|-------|
| Librería | Material Icons (`Icons.*`) |
| Variante | `rounded` (sufijo `_rounded`) en muchos iconos, `outlined` en otros |
| Tamaños | Ad-hoc: 16, 18, 20, 22, 24, 26, 60 |
| Color | `colorScheme.*` según contexto |
| Tooltip | Presente en `IconButton` del shell, ausente en muchos otros |

### Pros actuales

- Material Icons = consistencia con el ecosistema Android
- Sufijos descriptivos: `_rounded` para iconos suaves, `_outlined` para iconos ligeros
- Iconos semánticos: `warning_amber_rounded` para alertas, `inventory_2_outlined` para productos
- Tamaños de icono apropiados para su contexto (20px en chips, 24px en stat buttons, 60px en welcome)

### Contras actuales

- **Inconsistencia de variante**: algunos iconos usan `_rounded`, otros `_outlined`, otros sin sufijo (filled) — sin criterio claro
- Sin tamaño de icono estándar: 18 en `PopupMenuButton`, 20 en search bar, 22 en drawer, 24 en stat buttons
- Los iconos del drawer (22px) vs los de la pantalla de destino (tamaño variable) no coinciden
- Sin `iconTheme` en `ThemeData` (los tamaños y colores se heredan del `IconTheme` default del tema padre)
- `CircleAvatar` se usa como contenedor de iconos en lugar de `IconButton` o `Icon` con `Container` circular — inconsistente
- Sin `icon` mapping dictionary (cada pantalla define sus iconos ad-hoc)

#### Propuesta de mejora

- Estandarizar variante: `_rounded` para acciones, `_outlined` para navegación/estado, filled para énfasis
- Tamaños estándar: `sm=16`, `md=20`, `lg=24`, `xl=32`
- Definir `iconTheme` en `ThemeData` con `size: 24` por defecto
- Crear `AppIcons` class con constantes para iconos reutilizados (ej: `AppIcons.warehouse`, `AppIcons.product`)
- Usar `IconButtonTheme` en el tema global

| Pros | Contras |
|------|---------|
| Consistencia visual total | Requiere auditoría de todos los iconos |
| `AppIcons` centraliza cambios | Rigidez si el diseño evoluciona |
| `iconTheme` global = menos estilo inline | Los casos especiales necesitan override |

---

## 7. Modo Oscuro

### Estado actual (`app_theme.dart:180-249`)

| Aspecto | Tema claro | Tema oscuro |
|---------|------------|-------------|
| Fondo scaffold | `#ECECEC` | `#1E1E1E` (surface) |
| Surface | `#FFFFFF` | `#1E1E1E` |
| surfaceContainerHighest | `#ECECEC` | `#2C2C2C` |
| AppBar | `#3C096C` | `AppPurples.c600` (`#10002B`) |
| Primary | `#40916C` | `AppGreens.c300` (`#74C69D`) |
| Secondary | `#7B2FBE` | blanco |
| secondaryContainer | `#5A189A` | `#10002B` |
| Error | `#EF4444` | `#FF8585` |
| Cards | `#FFFFFF` | `#2C2C2C` |
| ElevatedButton | Sin override en dark | Sin override (hereda de colorScheme) |
| InputDecoration | Sin override en dark | Sin override (hereda del claro o defaults) |

### Pros actuales

- `surface` y `scaffoldBackground` correctamente oscurecidos
- Colores de error adaptados (rojo más claro en dark mode para mejor contraste)
- `AppBar` oscurecida coherentemente (`#10002B` — casi negro)
- `ColorScheme` completo con 22 propiedades definidas en dark mode
- `textTheme` recibe `dark: true` y adapta colores de texto
- Quick actions del dashboard tienen colores de fondo específicos para dark mode (`quickActionCatalogDark`, etc.)

### Contras actuales

- **`surface` y `scaffoldBackground` son idénticos** (`#1E1E1E`) — no hay distinción entre fondo y superficie
- **Sin `ElevatedButton` override en dark mode**: hereda colores del `ColorScheme` pero sin padding/shape definidos
- **Sin `InputDecoration` fill color en dark mode**: los inputs heredan el fondo pero sin color explícito
- `secondaryContainer` en dark (`#10002B`) es casi indistinguible del `surface` (`#1E1E1E`)
- Sin `dividerColor` explícito en dark mode
- Sin `disabledColor` ni `hintColor` en `ColorScheme` dark — se usan defaults
- La transición claro/oscuro no usa `AnimatedTheme` (el cambio es instantáneo)
- `_mintBg` del drawer (`#F2FBF4`) no tiene equivalente dark y se usa `cs.surface` directamente

#### Propuesta de mejora

- `scaffoldBackgroundColor` más oscuro que `surface` (ej: `#121212` scaffold, `#1E1E1E` surface)
- `ElevatedButton` y `OutlinedButton` themes definidos en dark mode
- `inputDecorationTheme.fillColor` explícito en dark
- `dividerColor` definido en dark `ColorScheme`
- `AnimatedTheme` o `themeAnimationDuration`/`themeAnimationCurve` para transición suave
- Drawer con equivalente dark de `_mintBg` (ej: `#0D2818` — verde muy oscuro)

| Pros | Contras |
|------|---------|
| Scaffold ≠ surface = jerarquía de elevación | Percepción de "menos contraste" si muy oscuro |
| Transición animada = pulido | `AnimatedTheme` requiere reestructuración |
| Fill color explícito = inputs visibles | Color puede chocar con el diseño |

---

## 8. Responsive Design

### Estado actual

| Aspecto | Implementación |
|---------|---------------|
| Layout | `Row`/`Column` + `Expanded`/`Flexible` para distribución |
| Grid | `GridView.count` con `crossAxisCount` fijo (2 o 3 columnas) |
| Text scaling | `textScaler` aplicado a `childAspectRatio` en grids del dashboard |
| SafeArea | Usado alrededor de contenido principal, no consistente en diálogos |
| MediaQuery | Usado para calcular `pageLimit` y padding bottom |
| Orientación | No se maneja explícitamente |

### Pros actuales

- `Expanded` + `Flexible` permiten distribución proporcional en rows
- `GridView.count` con `crossAxisCount` fijo da previsibilidad
- `MediaQuery.of(context).size.height` para calcular items por página (carga eficiente)
- `MediaQuery.of(context).viewInsets.bottom` para manejar teclado en bottom sheets
- `childAspectRatio` dinámico en dashboard evita desbordamiento con texto grande

### Contras actuales

- **Sin `LayoutBuilder` en cards**: elementos como shopping list cards se estiran sin límite en landscape/tablets
- `crossAxisCount` fijo: 2 columnas en una tablet de 10" desperdicia espacio masivamente
- Sin `breakpoints` definidos (mobile < 600, tablet 600-900, desktop > 900)
- Sin `AdaptiveLayout` ni `NavigationRail` para pantallas grandes
- `MediaQuery.of(context).padding.bottom` se usa ad-hoc en welcome screen pero no en drawer
- Sin `OrientationBuilder` para adaptar layout en landscape
- `SafeArea` inconsistente: `top: false` en drawer pero no en bottom sheets

#### Propuesta de mejora

- Definir breakpoints: `AppBreakpoints.mobile`, `.tablet`, `.desktop`
- `LayoutBuilder` en pantallas principales para adaptar `crossAxisCount`:
  - Mobile: 2 columnas en grids
  - Tablet: 3-4 columnas
  - Desktop/web: 4-5 columnas con `maxWidth` constraint
- `NavigationRail` en lugar de drawer para tablets/desktop
- `OrientationBuilder` en dashboard y shopping list para layout alternativo en landscape
- Cards con `maxWidth: 600` para legibilidad en pantallas grandes

| Pros | Contras |
|------|---------|
| Experiencia óptima en tablets | Código condicional significativo |
| `NavigationRail` aprovecha espacio lateral | Implica doble implementación de navegación |
| Grid adaptable evita espacio desperdiciado | Mayor complejidad de testing |

---

## 9. Animaciones y Micro-interacciones

### Estado actual

| Animación | Ubicación | Implementación |
|-----------|-----------|---------------|
| Dot indicators | Welcome screen | `AnimatedContainer` (width animado entre 8 y 24) |
| Button "Comprar" | Shopping list | `AnimatedSize` + `AnimatedOpacity` (420ms, easeInOutCubic) |
| FilterChip color | Stock change history | `AnimatedContainer` (180ms) en `_TypeChip` |
| Scroll to section | Dashboard | `Scrollable.ensureVisible` (400ms, easeInOut) |
| Fade opacity | Shopping list buy button | `AnimatedOpacity` (380ms) |

### Pros actuales

- `AnimatedContainer` en welcome dots y type chips da feedback de selección suave
- `AnimatedSize` del botón comprar evita saltos bruscos en el layout
- `AnimatedOpacity` del botón comprar refuerza la acción disponible
- `Scrollable.ensureVisible` con animación en dashboard es buen detalle

### Contras actuales

- **Solo 5 animaciones en toda la app** de 30+ pantallas
- Sin animaciones de transición entre rutas (usa default de Material)
- Sin animación de carga (shimmer/skeleton)
- Sin `Hero` animations (ej: producto de lista a detalle)
- Sin `AnimatedList` para inserciones/eliminaciones
- Sin animaciones de micro-interacción: botones sin `InkWell` personalizado (solo default ripple)
- Sin `AnimatedSwitcher` entre estados de carga/contenido
- Sin animación en `Checkbox` (usa default)
- Sin animación en `Dismissible` de notificaciones (usa default)
- Sin animación de éxito/error en operaciones

#### Propuesta de mejora

- `pageTransitionsTheme` con `FadeUpwardsPageTransitionsBuilder` o `OpenUpwardsPageTransitionsBuilder`
- `Hero` en imágenes de producto (lista → detalle) y en warehouse icon (dashboard → detalle)
- `AnimatedSwitcher` entre `LoadingIndicator` → contenido cargado
- Shimmer/skeleton en todas las listas durante carga
- `AnimatedList` en warehouse detail para cambios de stock
- `ScaleTransition` en `Checkbox` de shopping list
- Animación de éxito: `ScaleTransition` + `FadeTransition` al completar compra
- `AnimatedContainer` en cards de shopping list al cambiar estado (checked/unchecked)

| Pros | Contras |
|------|---------|
| App se siente "viva" y profesional | Más código de animación = más complejidad |
| Hero crea continuidad visual | Solo útil si hay imagen/icono compartido |
| Shimmer mejora percepción de carga | Paquete adicional o implementación manual |

---

## 10. Branding e Identidad Visual

### Estado actual

| Elemento | Implementación |
|----------|---------------|
| Logo | `assets/logo.png` — usado en splash, welcome, drawer, register, login |
| Color corporativo | Púrpura oscuro `#3C096C` (AppBar, drawer header) |
| Color funcional | Verde `#40916C` (acciones, botones, primary) |
| Nombre | "InvesVault" — Roboto Bold |
| Versión | "v1.0.12" visible en welcome, drawer, y settings |

### Pros actuales

- Logo presente en todos los puntos de entrada/salida (splash, welcome, drawer)
- Púrpura corporativo consistente en AppBar, drawer header, y pantallas auth
- Nombre de app y versión visibles en drawer y welcome screen
- Paleta dual (verde funcional + púrpura identidad) bien diferenciada
- Sin estilos "genéricos de Flutter" — todo tiene identidad propia

### Contras actuales

- **Sin splash screen animado**: la pantalla de splash usa el logo estático + spinner
- Sin pantalla de carga con logo animado entre auth y shell
- El logo en drawer (44x44) vs welcome (40x40) tiene tamaños inconsistentes
- Sin variante "icon-only" del logo para notificaciones/favicon
- Sin `splashFactory` personalizado para `InkWell` (usa el default azul de Material)
- Sin consistencia en el espaciado alrededor del logo (welcome: 12px top, drawer: 20px top + 20px bottom)

#### Propuesta de mejora

- Splash screen animada: logo con `ScaleTransition` + fade in del nombre
- Transición animada splash → welcome/shell (crossfade)
- Logo tamaño consistente en todos los contextos (44x44 estándar)
- `splashFactory` personalizado con `InkRipple` del color primario
- Variante `logo_small.png` (24x24) para notificaciones

| Pros | Contras |
|------|---------|
| Splash animado = primera impresión pulida | Tiempo de carga de la animación |
| Transición suave = experiencia premium | Complejidad adicional |
| Logo consistente = identidad sólida | Requiere exportar assets en varios tamaños |

---

## 11. Estados Visuales

### 11.1 Empty State

| Contexto | Icono | Mensaje | Acción |
|----------|-------|---------|--------|
| Sin productos en almacén | `inbox_outlined` | "No hay productos en este almacén" | "Añadir producto" |
| Sin resultados búsqueda | `search_off` | 'Sin resultados para "query"' | Ninguna |
| Sin notificaciones | `notifications_none` | "No tienes notificaciones" | Ninguna |
| Stock crítico vacío | `check_circle_outline` | "No hay productos en stock crítico" | Ninguna |
| Shopping list vacía (tiendas) | `store_outlined` | "No hay productos..." | Sugiere pulsar ✨ |
| Shopping list vacía (almacenes) | `shopping_cart_outlined` | "La lista de compra está vacía" | "Generar automáticamente" |
| Sin almacén seleccionado | `history` | "Selecciona un almacén..." | Ninguna |
| Dashboard low stock vacío | `check_circle_outline` | "No hay productos bajos de stock" | Ninguna |

#### Pros actuales

- `EmptyView` widget reutilizable con icono + mensaje + acción opcional
- Iconos contextuales (cada empty state usa un icono relevante al contexto)
- Tono positivo en "éxito" (check_circle para "todo bien, sin stock crítico")
- Acciones sugeridas donde aplica (añadir, generar)

#### Contras actuales

- **Icono `check_circle_outline` ambiguo**: se usa tanto para "sin stock crítico" (positivo) como para otros empties — podría confundirse con "completado" en lugar de "vacío"
- Sin diferenciación visual entre "vacío porque no hay datos" y "vacío porque el filtro no encontró resultados"
- `EmptyView` no soporta ilustración (solo icono de Material)
- Sin animación de entrada para el empty state
- Tamaño de icono 72px en `EmptyView` pero 64px en `ErrorView` — inconsistencia

#### Propuesta de mejora

- `EmptyView` con `type` enum: `EmptyViewType.noData`, `.noResults`, `.allGood`
- Ilustración opcional (SVG) como alternativa al icono
- `FadeTransition` al aparecer el empty state
- Unificar tamaño de icono a 64px entre `EmptyView` y `ErrorView`

| Pros | Contras |
|------|---------|
| Estados vacíos más expresivos | Complejidad adicional |
| Ilustraciones = personalidad | Requiere diseño de ilustraciones |

---

### 11.2 Loading State

| Contexto | Indicador | Mensaje |
|----------|-----------|---------|
| Carga de datos | `CircularProgressIndicator` (default, ~36px) | "Cargando…" |
| Búsqueda | `LinearProgressIndicator` (minHeight: 2) | Ninguno |
| Operación batch | `CircularProgressIndicator` + "Eliminando…" | Texto contextual |
| Botón submit | `CircularProgressIndicator` (20x20, strokeWidth 2 o 2.5) | Ninguno |
| Scroll infinito | `CircularProgressIndicator` en footer (12px padding) | Ninguno |
| Splash screen | `CircularProgressIndicator` bajo el logo | Ninguno |

#### Contras actuales

- Spinner circular para TODO tipo de carga — sin skeleton/shimmers
- `strokeWidth` inconsistente: 2.5 en register, 2.2 en product_list_tile, 2 en app_button
- Sin animación de entrada/salida del loading (aparece/desaparece instantáneamente)
- `LinearProgressIndicator` solo se usa en búsqueda — podría usarse en más contextos

#### Propuesta de mejora

- Skeleton shimmer para carga inicial de listas
- `AnimatedSwitcher` con `FadeTransition` entre loading y contenido
- `strokeWidth` estándar: 2.5 para spinners de página, 2.0 para spinners inline
- `LinearProgressIndicator` para cargas incrementales (loadMore, refresh)

---

### 11.3 Error State

| Elemento | Valor |
|----------|-------|
| Icono | `Icons.error_outline` 64px, color `colorScheme.error` |
| Mensaje | Texto centrado, `bodyLarge` (16px, Open Sans) |
| Botón | `OutlinedButton.icon` "Reintentar" con `Icons.refresh` |

#### Contras actuales

- Mismo tratamiento visual para todos los errores (sin diferenciar "sin conexión" de "error del servidor")
- Sin sugerencia de acción alternativa (solo reintentar)
- Sin logging del error técnico visible para debugging
- Sin animación al aparecer

#### Propuesta de mejora

- `ErrorView` con `type`: `network`, `server`, `unknown`
- Icono contextual: `wifi_off` para red, `dns_outlined` para servidor, `error_outline` genérico
- Mensaje secundario con sugerencia (ej: "Verifica tu conexión a internet")
- Botón secundario "Reportar problema" (opcional)
- `FadeTransition` + leve `SlideTransition` al aparecer

---

## 12. Consistencia de Componentes entre Pantallas

### Matriz de consistencia

| Componente | Dashboard | Warehouse Detail | Products | Shopping List | Stock History | Settings |
|-----------|-----------|-----------------|----------|---------------|---------------|----------|
| Search bar | `GestureDetector` | `TextField` | `TextField` | — | — | — |
| Filter chips | — | `FilterChip` M3 | — | `_StoreChip` custom | `_TypeChip` custom | — |
| Cards | `Container` + `BoxDecoration` | — | `Container` + `BoxDecoration` | `Container` + `BoxDecoration` | `Container` + `BoxDecoration` | — |
| List items | — | `ProductListTile` | `_ProductSearchTile` | `_buildItemCard` | `ListTile` inline | `ListTile` inline |
| Delete mode | — | `DeleteModeBar` | `DeleteModeBar` | `_DeleteModeBar` custom | — | — |
| Empty | `EmptyView` | `EmptyView` | `_EmptyState` custom | `EmptyView` | `EmptyView` | — |
| Error | — | `ErrorView` | — | `ErrorView` | `ErrorView` | — |
| Loading | `LoadingIndicator` | `LoadingIndicator` | `CircularProgressIndicator` | `LoadingIndicator` | `LoadingIndicator` | — |
| FAB | — | — | `FloatingActionButton.extended` | — | — | — |

### Contras principales

- **Search bar implementada de 4 formas distintas** en diferentes pantallas
- **Filter chips**: `FilterChip` nativo vs `_StoreChip`/`_TypeChip` custom — mismo propósito, implementación diferente
- **Delete mode** tiene `DeleteModeBar` (widget compartido) vs `_DeleteModeBar` (copia local en shopping list)
- **Search screen** usa su propio `_EmptyState` en lugar de `EmptyView`
- Shopping list cards son completamente diferentes de las cards en otras pantallas

#### Propuesta de mejora

- `AppSearchBar` widget unificado
- `AppFilterChip` para reemplazar `_StoreChip`, `_TypeChip`, y `FilterChip` manual
- Unificar `_DeleteModeBar` de shopping list para usar `DeleteModeBar` compartido
- Migrar `_EmptyState` a `EmptyView`

---

## 13. Welcome Screen (Onboarding)

### Diseño visual (`welcome_screen.dart:292`)

```
┌────────────────────────────┐
│  ⚙️              (settings)│  ← Header: logo 40x40 + "InvesVault" + versión
│                            │
│        ┌─────────┐         │
│        │  🏭     │         │  ← Ícono en círculo verde menta 120x120
│        │ 60px    │         │     `primaryContainer` fondo + `secondary` icono
│        └─────────┘         │
│                            │
│   Controla tu stock al     │  ← Título: 26px, w700, secondary (púrpura)
│       instante             │
│                            │
│   Gestiona tu inventario   │  ← Subtítulo: 16px, w400, secondary 70% opacidad
│   sin complicaciones...    │     height 1.5, padding horizontal 40px
│                            │
├────────────────────────────┤
│       ● ● ● ●              │  ← Dot indicators animados (AnimatedContainer)
│                            │     Activo: 24px ancho, inactivo: 8px
│  ┌──────────────────────┐  │     Activo: primaryContainer (verde menta)
│  │   Comienza Ahora     │  │  ← CTA: fondo primaryContainer, texto secondary
│  └──────────────────────┘  │     radius 14, w700, 16px
│                            │     Fondo: púrpura secondary
└────────────────────────────┘
```

#### Pros

- Diseño limpio con 3 zonas claras: header, slides, CTA
- Círculo de icono con buen tamaño (120px) y contraste
- Dot indicators animados con `AnimatedContainer`
- CTA prominente al final con "Comienza Ahora"
- Fondo púrpura en zona inferior crea anclaje visual
- Soporte para mouse drag (web) vía `_WebScrollBehavior`

#### Contras

- **Sin swipe hint**: el usuario no sabe que puede deslizar (flechas o texto "Desliza para continuar")
- Sin botones "Saltar" ni "Siguiente" — solo dots y CTA
- El CTA solo aparece en el último slide; en slides anteriores el área púrpura está vacía (solo dots)
- Sin ilustraciones/imágenes — solo iconos (menos atractivo que ilustraciones custom)
- La paleta es muy púrpura-dominante en welcome (fondo púrpura + texto púrpura + icono en círculo verde)
- El botón de settings en la esquina no hace nada (`onPressed: () {}`)

#### Propuesta de mejora

- Botón "Saltar" en slides que no son el último
- Texto "Desliza →" o indicador de swipe en el primer slide
- Añadir botón "Siguiente" junto a los dots para navegación explícita
- Ilustraciones SVG custom en lugar de iconos genéricos
- Implementar acción de settings (llevar a pantalla de configuración o mostrar modal de tema)
- La zona púrpura inferior podría tener una forma curva (wave/arc) en lugar de recta

| Pros | Contras |
|------|---------|
| Swipe hint = mejor descubribilidad | Más elementos en pantalla |
| Ilustraciones = más atractivo | Requiere diseño gráfico |
| "Saltar" = respeta al usuario experto | Reduce inmersión en onboarding |

---

## 14. Login y Register

### Diseño visual (`login_screen.dart`, `register_screen.dart`)

#### Login
```
┌────────────────────────────┐
│                            │
│         (logo 80x80)       │
│       InvesVault           │
│                            │
│  ┌──────────────────────┐  │
│  │  Iniciar sesión      │  │
│  │                      │  │
│  │  📧 Email            │  │  ← Campos con fondo primaryContainer
│  │  🔒 Contraseña   👁️  │  │     Sin borde, radius 12
│  │                      │  │     Icono morado, texto morado
│  │  [¿Olvidaste la      │  │
│  │   contraseña?]       │  │
│  │                      │  │
│  │  [  Acceder  ]       │  │  ← Botón secondary (púrpura), radius 14
│  └──────────────────────┘  │     w700, 16px, elevation 0
│                            │
│     ¿No tienes cuenta?     │
│     Regístrate             │
└────────────────────────────┘
```

#### Register
```
┌────────────────────────────┐
│ ←               ⚙️ (ajustes)│
│       (logo 80x80)         │
│       InvesVault           │
│  ┌──────────────────────┐  │
│  │  Crear cuenta        │  │  ← Card con elevation 0, radius 28
│  │  Únete a InvesVault  │  │     Padding 24
│  │                      │  │
│  │  👤 Nombre completo  │  │
│  │  📧 Correo           │  │  ← Campos: filled primaryContainer
│  │  🔒 Contraseña   👁️  │  │     Sin borde, radius 12
│  │  🔒 Confirmar    👁️  │  │     Texto 15px secondary
│  │                      │  │
│  │  ☐ Acepto términos   │  │  ← Checkbox radius 4
│  │                      │  │
│  │  [   Registrar   ]   │  │  ← Botón secondary, radius 14
│  └──────────────────────┘  │
│   ¿Ya tienes cuenta?       │
│   Inicia sesión            │
└────────────────────────────┘
```

#### Pros

- Diseño limpio, centrado en la tarea (sin distracciones)
- Campos con fondo `primaryContainer` (verde menta) — identidad propia y diferenciación del resto de la app
- Toggle de visibilidad de contraseña con icono de ojo
- Checkbox con forma `RoundedRectangleBorder(radius: 4)` — detalle cuidado
- Card con radius 28 en registro da sensación de "tarjeta de bienvenida"
- `back_button_interceptor` con confirmación de abandono (protege datos ingresados)

#### Contras

- **Login y register usan estilos completamente diferentes**: login no tiene Card wrapper, register sí. Login tiene "¿Olvidaste la contraseña?", register no tiene equivalente
- **El botón de settings en register está roto** (`onPressed: () {}`) — muestra icono sin funcionalidad
- Sin botón "Volver" visible en login; solo navegación por sistema o link "Regístrate"
- Texto "¿Olvidaste la contraseña?" es un `TextButton` sin funcionalidad implementada — expectativa rota
- Los campos no usan `AppTextField` sino `_Field` (register) y `TextFormField` directo (login) — inconsistencia
- Sin `autofillHints` en campos de email/contraseña
- El espaciado entre campos es 14px — sutilmente diferente del estándar 16px del resto de la app
- Sin botón de login biométrico (huella/Face ID)

#### Propuesta de mejora

- Unificar diseño visual de login y register (ambos con Card wrapper o sin él)
- Implementar "¿Olvidaste la contraseña?" con flujo de recuperación
- Quitar botón de settings sin función o implementarlo
- Usar `AppTextField` en ambos formularios
- `autofillHints: [AutofillHints.email]` y `[AutofillHints.password]`
- Biometría opcional: `local_auth` para login rápido
- Espaciado 16px entre campos (consistente con el resto de la app)

| Pros | Contras |
|------|---------|
| Diseño unificado = credibilidad | Cambio grande si los usuarios ya están acostumbrados |
| Autofill = onboarding más rápido | Requiere configuración de dominio en iOS (apple-app-site-association) |
| Biometría = comodidad | Acceso a hardware del dispositivo |

---

## 15. Lista de Verificación de Pulido Visual

### Lo que está bien

- [x] Paleta de colores definida y documentada
- [x] Tema oscuro completo
- [x] Radios de borde consistentes por tipo de componente
- [x] Sombras sutiles y coherentes
- [x] `EmptyView`, `ErrorView`, `LoadingIndicator` reutilizables
- [x] Logo presente en puntos clave de la app
- [x] Drawer con header de identidad
- [x] Color coding semántico (rojo = peligro, verde = éxito)
- [x] `Material3` activado
- [x] `cached_network_image` para imágenes

### Lo que falta

- [ ] Skeleton screens / shimmer en cargas
- [ ] Animaciones de transición entre pantallas
- [ ] `Hero` animations
- [ ] `AnimatedSwitcher` entre estados
- [ ] `AnimatedList` en operaciones de lista
- [ ] `AnimatedTheme` para cambio claro/oscuro
- [ ] `pageTransitionsTheme` personalizado
- [ ] `splashFactory` personalizado
- [ ] `Semantics` labels
- [ ] `AutofillHints` en formularios
- [ ] Responsive layout (breakpoints, `NavigationRail`)
- [ ] Sistema de espaciado estandarizado
- [ ] `AppCard` widget reutilizable
- [ ] `AppSearchBar` widget unificado
- [ ] `AppFilterChip` widget unificado
- [ ] Iconos con tamaño estándar
- [ ] Contraste AA en todos los colores de texto

---

## Resumen de Prioridades UI

| Prioridad | Mejora | Impacto visual | Esfuerzo |
|-----------|--------|---------------|----------|
| **Alta** | Skeleton screens en listas | Muy alto | Medio |
| **Alta** | Unificar search bar (`AppSearchBar`) | Alto | Bajo |
| **Alta** | `AnimatedSwitcher` loading → contenido | Alto | Bajo |
| **Alta** | Corregir contraste de `textHint` y `success` | Medio | Bajo |
| **Alta** | `SafeArea` consistente en drawer | Medio | Bajo |
| **Media** | Animaciones de transición entre pantallas | Alto | Bajo |
| **Media** | `AppCard` widget reutilizable | Alto | Medio |
| **Media** | Sistema de espaciado estandarizado | Alto | Medio |
| **Media** | `Hero` animations (producto lista → detalle) | Medio | Bajo |
| **Media** | `AnimatedTheme` para dark mode | Medio | Bajo |
| **Media** | Unificar estilos de auth screens | Medio | Medio |
| **Media** | `AnimatedList` en warehouse detail | Medio | Medio |
| **Media** | Responsive grid (breakpoints) | Alto | Alto |
| **Baja** | Ilustraciones SVG en welcome | Alto | Alto |
| **Baja** | `splashFactory` personalizado | Bajo | Bajo |
| **Baja** | `NavigationRail` en tablets | Medio | Alto |
| **Baja** | Logo animado en splash | Medio | Medio |
| **Baja** | Biometría en login | Medio | Medio |

---

### Conclusión

La app tiene una **identidad visual sólida** con paleta de colores bien definida (verde + púrpura), tipografía cuidada (Roboto + Open Sans), y consistencia en radios de borde y sombras. El sistema de temas claro/oscuro está completo a nivel de `ColorScheme`. Los widgets reutilizables `EmptyView`, `ErrorView` y `LoadingIndicator` garantizan una experiencia uniforme en estados no ideales.

Las áreas de mejora más impactantes son: **(1) la falta de animaciones** — la app se siente "estática" al navegar, cargar datos y realizar operaciones; **(2) la inconsistencia de componentes** — search bars, filter chips, cards y campos de texto se implementan de formas distintas según la pantalla; y **(3) la ausencia de responsive design** — la app no aprovecha pantallas grandes (tablets) ni adapta layouts en landscape. Con inversión moderada en estas tres áreas, la UI pasaría de "correcta" a "pulida y adaptable".
