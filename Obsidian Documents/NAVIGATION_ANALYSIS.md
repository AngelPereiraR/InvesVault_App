# Análisis de Experiencia de Navegación — InvesVault App

---

## Metodología

Este análisis examina la **experiencia visual de navegación** pantalla por pantalla: qué elementos navegables ve el usuario, cómo los descubre, la claridad de los affordances, y posibles puntos de fricción. No analiza el código de rutas, sino lo que el usuario percibe al moverse por la app.

---

## 1. Splash Screen

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Logo + nombre de la app | Centrado, prominente | Inmediata |
| Spinner de carga | Bajo el logo | Inmediata |

### Experiencia

El usuario ve la identidad de la app durante ~1-2 segundos mientras se verifica la autenticación. Es una pantalla de transición automática: el usuario no toma ninguna decisión de navegación.

### Puntos de mejora

- El spinner es genérico. Un **skeleton animado del logo** (p.ej. pulso sutil) reforzaría identidad y reduciría percepción de espera.
- Sin indicador de progreso. Si la verificación tarda (red lenta), el usuario no sabe si la app funciona.

---

## 2. Welcome Screen (Onboarding)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Logo + versión | Superior izquierda | Alta |
| Icono de ajustes ⚙️ | Superior derecha | Alta, pero no funciona |
| Slides con PageView | Centro (swipe horizontal) | Media: sin indicador de swipe |
| Dot indicators | Inferior (barra púrpura) | Alta |
| Botón "Comienza Ahora" | Inferior (barra púrpura) | Alta |

### Experiencia

El usuario llega aquí en su primer uso. El **swipe horizontal** entre slides es el mecanismo principal de navegación, pero **no hay ninguna pista visual** que lo indique: ni flechas, ni texto "Desliza", ni botón "Siguiente". Los dots animados son el único feedback.

El botón "Comienza Ahora" está permanentemente visible — en los slides 1-3 ocupa espacio en la barra púrpura sin contexto (el usuario podría no entender qué acción realiza). El icono ⚙️ de ajustes es un **botón muerto** que genera expectativa rota.

### Puntos de mejora

- **Indicador de swipe**: flecha animada o texto "Desliza para continuar →" en el primer slide.
- **Botón "Siguiente"** junto a los dots para usuarios que prefieren taps a swipes.
- **Ocultar "Comienza Ahora"** hasta el último slide, o cambiar su label a "Siguiente" en slides intermedios.
- **Implementar o eliminar** el icono de ajustes. Un botón sin función daña la confianza.

---

## 3. Login Screen

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Logo + nombre de app | Centrado superior | Alta |
| Campos email/contraseña | Centro, formulario | Alta |
| Toggle visibilidad contraseña 👁️ | Dentro del campo | Media (icono pequeño) |
| "¿Olvidaste tu contraseña?" | Bajo el campo contraseña, alineado derecha | Media |
| Botón "Iniciar sesión" | Centro, ancho completo, púrpura | Alta |
| Botón "Crear cuenta" | Bajo el botón login, outlined | Alta |
| Icono de ajustes ⚙️ | Superior derecha | Alta, pero no funciona |

### Experiencia

El formulario es el centro de atención. La navegación visual es **vertical descendente**: logo → título → campos → botones. Es un flujo natural.

El enlace "¿Olvidaste tu contraseña?" es un **TextButton sin acción**: el usuario hace tap y no pasa nada. Esto es peor que no tenerlo, porque **rompe la expectativa** y genera frustración.

Los dos botones (Iniciar sesión + Crear cuenta) tienen buena diferenciación visual: uno filled púrpura, otro outlined con borde púrpura. Sin embargo, el botón "Crear cuenta" usa `replaceWithAuthRoute` que **borra todo el historial de navegación** — si el usuario pulsa atrás en registro, no vuelve al login (va a la pantalla del sistema).

### Puntos de mejora

- **Implementar "¿Olvidaste tu contraseña?"** con flujo de recuperación, o eliminar el enlace.
- **Implementar o eliminar** el icono ⚙️.
- El botón "Crear cuenta" debería ser un **push** normal, no un `replaceAll`, para que el back button funcione como el usuario espera.
- Añadir **biometría** (huella/Face ID) como alternativa de login — botón con icono de huella bajo "Iniciar sesión".

---

## 4. Register Screen

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Flecha atrás ← | Superior izquierda | Alta |
| Icono de ajustes ⚙️ | Superior derecha | Alta, pero no funciona |
| Logo + nombre de app | Centro superior | Alta |
| 4 campos de formulario | Centro, scrollable | Alta |
| Toggle visibilidad 🔒 | Dentro de campos contraseña | Media |
| Checkbox "Acepto términos" | Bajo los campos | Alta |
| Botón "Registrar" | Centro, púrpura, ancho completo | Alta |
| Enlace "¿Ya tienes cuenta?" | Bajo el botón | Alta |

### Experiencia

Similar al login: flujo vertical descendente. La **flecha atrás** es el primer elemento de navegación real en la app — y funciona correctamente con un diálogo de confirmación si el usuario ha escrito datos.

La card con `borderRadius: 28` envuelve el formulario, creando una sensación de "tarjeta de bienvenida" agradable.

El checkbox de términos es un `GestureDetector` sobre el texto además del `Checkbox`, lo cual es buen detalle (aumenta el área táctil).

### Puntos de mejora

- La flecha atrás usa `replaceWithAuthRoute` → mismo problema que login: borra el historial. Un **push** normal sería más natural.
- El `TextInputAction.next` entre campos ahorraría taps (nombre → email → contraseña → confirmar).
- Sin indicador de fortaleza de contraseña.
- Mismo problema del ⚙️ muerto.

---

## 5. AppShell (contenedor principal)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Hamburguesa ☰ (drawer) | AppBar, izquierda | Alta |
| Título de sección | AppBar, centro-izquierda | Alta |
| Botón [+] crear | AppBar, derecha (según sección) | Alta |
| Botón [✨] generar lista | AppBar, derecha (solo en Tiendas) | Baja (aparece solo en 1 sección) |
| Campana 🔔 notificaciones | AppBar, derecha, con badge | Alta |

### Experiencia

La AppBar es el **centro de mando** de la app. Su contenido cambia según la sección activa, lo cual es eficiente pero puede ser **inconsistente**:

- En "Inventario" → solo botón [+]
- En "Tiendas" → botones [✨] y [+] (2 iconos)
- En "Catálogo" → solo botón [+]
- En "Historial" → sin botones (solo campana)

El usuario puede no notar la aparición/desaparición de iconos si no mira activamente la AppBar. El botón [✨] en Tiendas es particularmente **difícil de descubrir** porque solo existe en esa sección y su icono no es obvio (generar lista de compra desde Tiendas).

La campana de notificaciones es el único elemento **siempre visible** en la AppBar, lo cual es correcto por su importancia.

### Puntos de mejora

- Tooltip descriptivo en TODOS los iconos de la AppBar (el [✨] ya lo tiene, verificar el resto).
- Considerar un **FAB** o **botón más visible** para "Generar lista de compra" en lugar de esconderlo en la AppBar de Tiendas.
- El título de la AppBar cambia a "Almacén" en WarehouseDetail — buen detalle contextual. Podría aplicarse también en otras pantallas de detalle.

---

## 6. Drawer de Navegación

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Header púrpura (logo, nombre, email) | Superior del drawer | Inmediata al abrir |
| Sección "Menú inicial" (8 items) | Lista principal | Alta |
| Sección "Próximamente" (5 items) | Mitad inferior | Media |
| Sección "Soporte" (1 item activo) | Mitad inferior | Media |
| Sección "Soporte · Próximamente" (3 items) | Mitad inferior | Baja (confuso: 2 headers "Soporte") |
| Badge "Pronto"/"Próximamente" | En items deshabilitados | Alta |
| "Cerrar sesión" (rojo) | Final de la lista | Alta |

### Experiencia

El drawer es **el único mecanismo de navegación principal** entre secciones. El usuario debe: hamburguesa → buscar sección → tap. Son **2 interacciones** para cada cambio de sección.

La organización visual es buena:
- Header con identidad y datos del usuario
- Items activos vs deshabilitados claramente diferenciados (opacidad, badge "Pronto")
- "Cerrar sesión" en rojo al fondo (patrón familiar)

Pero hay **problemas de jerarquía**:
- Hay **dos secciones "Soporte"**: una con items activos y otra con "Próximamente". Es confuso.
- "Configuración" está dentro de "Próximamente" pero **es un item activo** (no tiene badge "Pronto"). Esto contradice el nombre de la sección.
- La sección "Próximamente" tiene 4 items de datos + 1 activo (Configuración) — mezcla conceptos.
- Hay **11 items "próximamente"** en total: esto comunica que la app está incompleta.

### Puntos de mejora

- **Reducir items "Próximamente"** a una sola sección con máximo 3-4 items, o eliminarlos y mostrarlos solo cuando existan.
- **Mover "Configuración"** a "Menú inicial" — es una sección real y funcional.
- Unificar las 2 secciones "Soporte" en una sola: "Soporte" con Ayuda (activo) y los demás como "Próximamente".
- El drawer tiene ~20 items. Considerar **agrupar secciones menos frecuentes** (Marcas, Categorías) bajo un submenú "Administración" o "Configuración".
- Añadir un **divisor visual consistente** entre secciones activas y "próximamente".

---

## 7. Dashboard (Inicio)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| 3 stat buttons (Bajo stock, Catálogo, Lista) | Superior, fila horizontal | Alta |
| Barra de búsqueda | Bajo stats | Alta (con icono QR) |
| Grid "Accesos rápidos" (3×2) | Centro | Alta |
| Sección "Mis almacenes" + "Ver todos" | Mitad inferior | Media (requiere scroll) |
| Sección "Stock crítico" + "Ver todos" | Final (tras scroll) | Baja (requiere scroll) |

### Experiencia

El dashboard es un **hub de navegación** muy bien diseñado visualmente. Los 3 stat buttons en la parte superior funcionan como **atajos** a información clave y son inmediatamente visibles al entrar.

La barra de búsqueda **no es una barra de búsqueda real**: es un `GestureDetector` decorado que navega a `/search`. El icono QR a la derecha insinúa funcionalidad de escáner, pero **no es cliqueable independientemente** — todo el rectángulo navega a búsqueda. El usuario podría intentar tocar solo el icono QR esperando abrir el escáner directamente.

El grid de "Accesos rápidos" (3×2) ofrece **6 destinos con iconos circulares**: Movimientos, Nuevo almacén, Tiendas, Marcas, Catálogo, Nuevo producto. Es una excelente metáfora visual. Sin embargo:
- No hay indicador de cuántos items hay en cada destino (ej: "3 almacenes").
- "Nuevo almacén" abre un **diálogo**, no una pantalla — esto no es evidente hasta que el usuario toca.
- "Catálogo" y "Nuevo producto" son dos tiles separados que van a la misma pantalla (Catálogo) con distinto comportamiento — el usuario podría no notar la diferencia.

Las secciones inferiores ("Mis almacenes" y "Stock crítico") tienen **badges numéricos** (ej: "[3]") que aportan contexto valioso. Pero el enlace "Ver todos" usa un `TextButton.icon` con `chevron_right` y texto — es pequeño y puede pasar desapercibido.

El scroll-down para ver "Stock crítico" es natural, pero el botón "Bajo stock" en los stats hace un `_scrollToLowStock()` animado — excelente detalle de navegación intra-pantalla.

### Puntos de mejora

- El icono QR en la search bar debería ser un **botón independiente** que abra el escáner directamente.
- Los tiles de "Accesos rápidos" podrían mostrar **contadores** (ej: "3 tiendas", "5 marcas").
- "Nuevo almacén" y "Nuevo producto" deberían tener un indicador visual (badge "+" pequeño) para diferenciarse de tiles de navegación.
- "Catálogo" y "Nuevo producto" van a la misma pantalla — fusionar en un tile con doble acción (tap = catálogo, long-press = crear) o diferenciarlos más.
- Los enlaces "Ver todos" son muy sutiles — podrían ser `Chip` o `FilledTonalButton` pequeños para mayor visibilidad.

---

## 8. Lista de Almacenes (Inventario)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Barra de búsqueda | Superior | Alta |
| Grid 2-columnas de cards | Centro | Alta |
| Menú contextual (⋮) en cada card | Esquina superior derecha de cada card | Media (icono pequeño, 18px) |
| Badge "Compartido" en cards | Bajo el nombre | Alta |
| FAB "Crear" (draggable) | Inferior derecha, móvil | Alta |
| Icono checklist (seleccionar para borrar) | Bajo la search bar, derecha | Media (solo visible si tienes almacenes propios) |
| DeleteModeBar (roja) | Superior (reemplaza toolbar) | Alta cuando está activa |

### Experiencia

El grid de cards usa `WarehouseCard` con un diseño limpio: icono circular + nombre + contador de productos + chip "Compartido". La navegación principal es **tap en la card → detalle del almacén**.

El **menú contextual (⋮)** en cada card contiene "Editar" y "Eliminar". Es un `PopupMenuButton` de 18px — bastante pequeño y fácil de pasar por alto. El usuario tiene que descubrir que existe este menú. Para un almacén compartido donde no eres owner, el menú no aparece, lo cual es correcto.

El **FAB draggable** es un detalle inusual y excelente: el usuario puede mover el botón "Crear" si estorba. Pero la etiqueta "Crear" en un `FloatingActionButton.extended` ocupa espacio — en pantallas pequeñas podría tapar contenido.

El botón de **checklist** (seleccionar para borrar) solo aparece si el usuario tiene almacenes propios. Es un `IconButton` solitario alineado a la derecha bajo la search bar. Su propósito no es obvio a primera vista (el tooltip ayuda, pero requiere long-press para verlo en mobile).

Cuando se activa el modo borrado, la **DeleteModeBar roja** aparece arriba reemplazando la toolbar — es muy visible y efectiva.

### Puntos de mejora

- El menú contextual (⋮) debería ser más visible — icono de 22-24px o usar `IconButton` con padding estándar.
- El botón checklist necesita mejor affordance: un `TextButton.icon` con label "Seleccionar" sería más claro que un icono solitario.
- El FAB "Crear" abre un **diálogo con tabs** (Info + Colaboradores). Esto es potente pero **no es obvio** — el usuario espera que "Crear" abra un formulario simple. La pestaña "Colaboradores" solo se activa tras crear, lo cual es correcto pero no se comunica.
- El diálogo de crear/editar almacén usa `barrierDismissible: false` — el usuario no puede cerrarlo tocando fuera. Obliga a usar el botón X, lo cual es seguro pero puede frustrar.

---

## 9. Detalle de Almacén (WarehouseDetail)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| LowStockBadge (contador rojo) | Superior izquierda | Alta |
| Botón "Compartir" | Superior derecha | Alta (solo admin) |
| Botón [+] añadir producto | AppBar/superior derecha | Alta |
| Botón checklist (borrar) | AppBar/superior derecha | Media |
| Barra de búsqueda | Bajo la toolbar | Alta |
| FilterChips de categorías | Bajo la búsqueda, scroll horizontal | Alta |
| Lista de productos con +/- | Centro | Alta |
| DeleteModeBar (roja) | Superior (modo borrado) | Alta (cuando activa) |

### Experiencia

La pantalla de detalle de almacén es la **más rica en navegación** de la app. El usuario puede:
- **Buscar** productos (barra de búsqueda con debounce)
- **Filtrar** por categoría (chips horizontales)
- **Añadir/Quitar stock** con botones +/- en cada item
- **Eliminar producto** del almacén (menú contextual ⋮ en el tile)
- **Ver detalle del producto** (tap en el item)
- **Añadir nuevo producto** (botón + en toolbar o bottom sheet)
- **Activar modo borrado múltiple** (icono checklist)
- **Compartir almacén** (botón Compartir, solo admin)
- **Pull-to-refresh** para recargar

Los **botones +/- en cada item** de producto son el punto fuerte: permiten ajustar stock sin salir de la lista. Cada tap hace una llamada a la API y muestra un `CircularProgressIndicator` inline mientras se procesa — buen feedback.

Los **FilterChips de categorías** son nativos de Material 3 y funcionan bien, pero el chip "Todas" no tiene indicador visual de que es el estado por defecto.

El **botón "Compartir"** navega a una pantalla de gestión de colaboradores — es una pantalla separada, no un diálogo. Esto es correcto por la complejidad de la funcionalidad.

El **menú contextual (⋮)** en `ProductListTile` solo tiene la opción "Eliminar del almacén" — para un menú de un solo item, sería mejor un `IconButton` directo (la papelera roja ya visible).

### Puntos de mejora

- El menú ⋮ con una sola opción es **sobre-ingeniería**: reemplazar por `IconButton` de papelera directamente visible.
- Los FilterChips deberían tener un **indicador de cantidad** (ej: "Bebidas (12)").
- El bottom sheet "Añadir producto" incluye un enlace "Crear nuevo producto" que **cierra el sheet y navega a otra pantalla** — esto puede desorientar (el usuario pierde el contexto del almacén).
- La **búsqueda no muestra resultados parciales** mientras se escribe (debounce 400ms + llamada API) — parecería lento. Un filtrado local sobre los datos ya cargados sería instantáneo.
- Sin indicador del **total de productos** en el almacén (solo se ve el badge de low stock).

---

## 10. Lista de Productos (Catálogo)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Barra de búsqueda | Superior | Alta |
| FilterChips de categorías | Bajo la búsqueda, scroll horizontal | Alta |
| Icono checklist (borrar múltiple) | Junto a los chips | Media |
| Grid 2-columnas de cards | Centro | Alta |
| Botón papelera 🗑️ en cada card | Esquina superior derecha | Media (icono 18px) |
| DeleteModeBar (roja) | Superior (modo borrado) | Alta |

### Experiencia

Muy similar a la lista de almacenes, pero con cards que muestran nombre + marca + código de barras + unidad. El **tap en una card** lleva a **editar el producto** (no a detalle), lo cual es **sorprendente** — el usuario esperaría ver un detalle del producto, no un formulario de edición.

Cada card tiene un **icono de papelera🗑️** en la esquina superior derecha que elimina el producto directamente (con confirmación). Es bueno tener la acción visible, pero el icono es pequeño (18px) y fácil de tocar accidentalmente.

Los FilterChips de categorías funcionan igual que en warehouse detail, pero aquí están acompañados del botón checklist a la derecha en la misma fila — buena disposición.

No hay forma de **ver el detalle de un producto** desde esta pantalla: el tap lleva a editar. Para ver detalle, el usuario debe ir al almacén → producto. Esto es una **limitación de flujo** importante.

### Puntos de mejora

- El tap en la card debería llevar a un **detalle de producto** (quizás mostrando en qué almacenes está), con un botón "Editar" dentro.
- Si el tap se mantiene en editar, al menos añadir un **icono de información ℹ️** o "Ver detalle" como opción secundaria.
- La papelera en cada card es útil pero pequeña. Aumentar a 22px o usar `IconButton` con padding visible.
- Sin opción para ver en qué almacenes está un producto desde esta pantalla.

---

## 11. Detalle de Producto

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Imagen del producto (si tiene) | Superior | Alta |
| Info card (stock, mínimo, precio, tienda) | Centro | Alta |
| Alerta "Stock bajo el mínimo" | Centro (condicional) | Alta |
| SegmentedButton (Entrada/Salida) | Dentro de card "Actualización rápida" | Alta |
| Botón Añadir/Quitar + QuantityStepper | Dentro de card | Alta |
| Sección "Fechas de caducidad" | Mitad inferior | Media (requiere scroll) |
| Botón "Asignar" lote | En la cabecera de caducidad | Media |
| Botón "Ver historial de cambios" | Bajo caducidad, outlined | Alta |
| Botones "Ajustes en almacén" / "Editar ficha" | Fila inferior, FilledTonalButton | Alta (requiere scroll) |
| Botones editar/eliminar en lotes | En cada fila de lote | Alta |

### Experiencia

Es la pantalla **más completa en un solo scroll**. El usuario desciende verticalmente por secciones bien delimitadas con `Card` widgets. La jerarquía es clara.

El `SegmentedButton` (Entrada/Salida) de Material 3 es una excelente elección para el toggle de tipo de operación: visualmente claro y táctilmente accesible. El `QuantityStepper` personalizado (+/- con número) complementa bien.

La sección de **lotes/caducidad** tiene su propio `BlocBuilder` con estados de carga independientes. Los botones de editar/eliminar en cada lote son iconos pequeños (18px) — funcionales pero podrían ser más prominentes dado que eliminar un lote **reduce el stock**.

Los 4 botones inferiores ("Ver historial", "Ajustes en almacén", "Editar ficha") son correctos pero **"Ajustes en almacén" y "Editar ficha"** suenan similares — el usuario podría no saber cuál usar. "Ajustes en almacén" edita la configuración del producto en ese almacén (mínimo, precio, tienda), mientras "Editar ficha" edita los datos base del producto (nombre, barcode, marca).

### Puntos de mejora

- Labels de botones más descriptivos: "Ajustes en este almacén" y "Editar datos del producto".
- Los botones de editar/eliminar lote (18px) deberían ser ≥ 22px para mejor accesibilidad táctil.
- La card de "Actualización rápida" con `SegmentedButton` + `ElevatedButton` + `QuantityStepper` tiene **3 elementos interactivos en una fila** en pantallas pequeñas — puede sentirse apretada.
- La sección de lotes muestra fecha como texto (ej: "vence 2025-12-31") — un `Chip` con color contextual (naranja si caduca pronto) sería más escaneable.

---

## 12. Búsqueda Global (Search)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Campo de búsqueda (autofocus) | AppBar completa | Inmediata |
| Botón limpiar (X) | AppBar, derecha | Alta (cuando hay texto) |
| Lista de resultados | Centro | Alta |
| Botón "Crear nuevo producto" | Centro (si no hay resultados) | Alta |
| FAB "Escanear" | Inferior derecha | Alta |

### Experiencia

La pantalla de búsqueda es **limpia y funcional**. El campo tiene `autofocus: true` — el teclado aparece inmediatamente, lo cual es correcto. Los resultados son cards con icono circular + nombre + metadata.

El **tap en un resultado** no navega a detalle: abre un **bottom sheet** con información del producto y un botón "Editar producto". Esto es inesperado — el usuario probablemente busca para encontrar, no para editar. El bottom sheet es informativo pero **rompe el flujo de búsqueda** (el usuario esperaba ir a la pantalla del producto).

El **FAB "Escanear"** abre el escáner de código de barras — excelente ubicación y visibilidad.

Cuando no hay resultados, aparece un botón "Crear nuevo producto" — buen manejo del estado vacío.

### Puntos de mejora

- El tap en un resultado debería **navegar al detalle del producto** (o a sus almacenes), no a un bottom sheet de edición.
- Si se mantiene el bottom sheet, añadir opción "Ver en almacenes" junto a "Editar producto".
- El FAB "Escanear" está en `extended` mode con label — en búsqueda consume espacio horizontal. Un `FloatingActionButton` normal (solo icono) sería suficiente.
- Los resultados no muestran **en qué almacenes está** el producto — información valiosa en contexto de búsqueda.

---

## 13. Shopping List

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Tabs "Tiendas" / "Almacenes" | Superior (sliding tab header) | Alta |
| Chips de filtro por tienda | Bajo tabs (solo en Tiendas) | Alta |
| Dropdown de almacén | Bajo tabs (solo en Almacenes) | Alta |
| Menú ⋮ (acciones) | Esquina derecha del toolbar | Media |
| Lista de items con checkbox + contadores | Centro | Alta |
| Botón "Comprar (X marcados)" | Inferior (animado) | Alta (cuando hay checks) |
| Botón papelera🗑️ por item | Derecha de cada card | Alta |
| Info dialog "Cómo funciona" | Vía menú ⋮ | Baja (oculto en menú) |
| DeleteModeBar (roja) | Superior (modo borrado) | Alta |

### Experiencia

La pantalla más compleja de la app. La navegación se organiza en **dos niveles de tabs**:

1. **Tab principal**: "Tiendas" (vista global agrupada por tienda) y "Almacenes" (vista por almacén específico).
2. **Sub-navegación**: en Tiendas, chips de filtro por tienda. En Almacenes, dropdown de almacén.

El **menú ⋮** esconde 7-8 acciones: generar automáticamente, añadir producto, ordenar (alfabético/categoría), info, seleccionar para borrar, limpiar lista. Es un menú **sobrecargado** — varias de estas acciones merecen estar visibles:
- "Generar automáticamente" (✨) es una acción frecuente y está oculta
- "Cómo funciona" es ayuda contextual y está oculta
- El toggle de ordenación es una preferencia, no una acción

Cada card de item es **muy densa**: checkbox + nombre + almacén/tienda + mínimo sugerido + feedback de compra + 2 selectores de cantidad + papelera. En pantallas pequeñas, esto es **abrumador**. El usuario necesita tiempo para entender qué hace cada elemento.

El **botón "Comprar"** aparece/desaparece con `AnimatedSize` — excelente feedback. Dice "Comprar (3 marcados)" mostrando el conteo.

El **info dialog** es una ayuda contextual excelente... pero está **oculta en el menú ⋮**. Un usuario nuevo nunca lo encontrará sin explorar.

### Puntos de mejora

- **Sacar acciones frecuentes del menú ⋮**: "Generar" (✨) como botón visible en el toolbar de Tiendas, el botón ya existe en AppBar pero solo en la sección Tiendas. En la pantalla shopping list no está.
- **Info dialog accesible**: un icono ℹ️ en la cabecera de tabs, no escondido en menú.
- **Tooltip o coach mark** la primera vez: "Toca el check para marcar lo que vas a comprar".
- Simplificar la card: ocultar "Mínimo sugerido" si no es relevante, mostrar "Ahora" solo cuando el item está checked.
- Añadir **"Seleccionar todo"** en el menú para compras rápidas.
- Los chips de filtro por tienda usan un estilo custom (`_StoreChip`) en lugar de `FilterChip` — unificar para consistencia visual.

---

## 14. Historial de Cambios (Stock)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Dropdown de almacén | Superior, fondo `primaryContainer` | Alta |
| Chips de filtro (Todos/Entradas/Salidas/Ajustes) | Bajo el dropdown, scroll horizontal | Alta |
| Lista de movimientos | Centro | Alta |

### Experiencia

La pantalla tiene un **flujo guiado**: primero seleccionas almacén, luego aparecen los filtros, luego la lista. El estado vacío inicial ("Selecciona un almacén para ver su historial") es claro y dirige al usuario.

Los **chips de filtro** son custom (`_TypeChip`) en lugar de `FilterChip` de Material 3. Visualmente son similares pero usan `AnimatedContainer` para el color — buen detalle. La codificación de color es semántica: verde = entradas, rojo = salidas, ámbar = ajustes.

Cada card de movimiento muestra: icono coloreado + producto + badge de cantidad (+/-/=/=X) + razón + usuario + fecha. La información está bien jerarquizada.

No hay **pull-to-refresh** — solo carga inicial y scroll infinito. Si el usuario quiere recargar, debe cambiar el filtro o re-seleccionar el almacén.

### Puntos de mejora

- Pull-to-refresh para recargar los datos actuales.
- Los chips custom (`_TypeChip`) deberían unificarse con los `FilterChip` del resto de la app o migrar el resto a este estilo.
- El dropdown de almacén usa `filled: true, fillColor: primaryContainer` — estilo inconsistente con otros dropdowns (shopping list también lo usa así, pero otros no).

---

## 15. Notificaciones

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Botón "Marcar todo leído" | AppBar, texto | Alta |
| Botón "Borrar todas" 🗑️ | AppBar, icono | Alta |
| Barra de búsqueda | Superior | Alta |
| Lista de notificaciones | Centro | Alta |
| Swipe-to-delete | En cada item (deslizar izquierda) | Baja (sin indicador visual) |
| Tap para marcar leída | En cada item no leído | Media (cambia el fondo, pero sin affordance claro) |

### Experiencia

La única pantalla con **swipe-to-delete** (Dismissible). El swipe muestra un fondo rojo con icono de papelera — el patrón es estándar pero **no hay indicación visual** de que se puede deslizar. El usuario lo descubre por accidente o por familiaridad con el patrón.

Las notificaciones no leídas tienen **fondo `primaryContainer` con opacidad** — diferenciación sutil pero efectiva. El tap en una notificación no leída la marca como leída, pero **no navega a ningún lado**. Esto es una oportunidad perdida: una notificación de "Stock bajo de Leche" debería llevar al detalle de ese producto.

Los botones en AppBar ("Marcar todo leído" + "Borrar todas") son claros y accesibles. "Borrar todas" pide confirmación con diálogo — buena práctica.

### Puntos de mejora

- Las notificaciones deberían ser **navegables**: tap → pantalla relevante (producto, almacén).
- Indicador visual de swipe (ícono o texto "Desliza para eliminar" en el primer uso).
- Las notificaciones de tipo `expiry_warning` tienen un icono de calendario naranja — el color ayuda pero un **chip "Caduca pronto"** sería más informativo.
- Pull-to-refresh (ya tiene `RefreshIndicator`).

---

## 16. Marcas, Categorías y Tiendas

### Elementos de navegación visibles (comunes a las 3 pantallas)

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Barra de búsqueda | Superior (solo en Marcas y Tiendas) | Alta |
| Lista de items | Centro | Alta |
| Botón [+] en AppBar | AppBar derecha | Alta |
| Diálogo inline de crear/editar | Modal (al tap en item o [+]) | Alta |
| Icono checklist (borrar múltiple) | Lista | Media |
| DeleteModeBar (roja) | Superior (modo borrado) | Alta |

### Experiencia

Las 3 pantallas de entidades auxiliares (Marcas, Categorías, Tiendas) comparten el mismo patrón:
- Lista simple con `ListTile`
- El botón [+] en AppBar abre un **diálogo** de creación
- El tap en un item abre un **diálogo** de edición (con campo de nombre + botón guardar)
- Modo borrado múltiple con checklist

Este patrón es **consistente y efectivo** para entidades simples. Crear/editar en diálogo evita navegación innecesaria a pantallas completas.

La **diferencia entre ellas** es mínima: Tiendas tiene un campo extra "ubicación" en el diálogo. Marcas y Categorías son idénticas visualmente (solo cambia el nombre).

**Categorías no tiene barra de búsqueda** — inconsistencia con Marcas y Tiendas que sí la tienen.

### Puntos de mejora

- Añadir barra de búsqueda en Categorías (consistencia).
- Los diálogos de crear/editar usan `AlertDialog` simple — podrían beneficiarse de un diseño consistente (como el diálogo de almacén con título púrpura y tabs).
- El diálogo de Tiendas pide "Nombre" y "Ubicación", pero el de Marcas solo "Nombre" — sin embargo usan la misma función `showStoreDialog`/`showBrandDialog` exportadas desde sus respectivas pantallas. La diferencia está clara, pero el espaciado podría unificarse.

---

## 17. Pantalla de Ajustes (Settings)

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Formulario de perfil (nombre, email) | Superior | Alta |
| Botón "Guardar cambios" | Bajo el formulario | Alta |
| Toggle "Modo oscuro" | Mitad, SwitchListTile | Alta |
| Info "Acerca de" (versión) | Mitad inferior | Alta |
| Botón "Cerrar sesión" (rojo) | Final | Alta |

### Experiencia

Pantalla simple y directa. El **formulario de perfil** permite cambiar nombre y email — pero no hay indicador de si los datos se guardaron correctamente más allá del SnackBar "Perfil actualizado".

El **toggle de modo oscuro** es un `SwitchListTile` estándar — correcto y familiar.

El **botón "Cerrar sesión"** es danger (rojo) al fondo — consistente con el drawer y buena práctica de diseño (acción destructiva al final).

No hay **navegación dentro de esta pantalla** — es puramente configuraciones. El usuario sale por el drawer.

### Puntos de mejora

- Feedback visual en el formulario: botón "Guardar cambios" debería deshabilitarse hasta que haya cambios reales (dirty check).
- El toggle de modo oscuro no muestra **preview** del cambio — sería ideal usar `AnimatedTheme` para transición suave.
- Añadir **foto de perfil** (avatar editable) arriba del formulario.

---

## 18. Pantalla de Ayuda

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Lista de secciones con ExpansionTile | Centro | Alta |
| Preguntas/respuestas dentro de cada tile | Expandible | Alta |

### Experiencia

Ayuda usa `ExpansionTile` para organizar contenido en secciones colapsables: "Primeros pasos", "Panel", "Almacenes", "Productos", etc. Esto permite **navegación vertical con scanning rápido** — el usuario ve todas las secciones, expande la que le interesa.

Cada tile expandido muestra preguntas frecuentes con respuestas. Es un patrón limpio y familiar.

No hay **barra de búsqueda** en ayuda — el usuario debe scannear visualmente todas las secciones para encontrar su pregunta.

### Puntos de mejora

- Añadir **barra de búsqueda** en ayuda para encontrar preguntas por palabra clave.
- Enlaces a pantallas específicas desde las respuestas (ej: "Ve a Ajustes > Modo oscuro" con link navegable).
- Alguna pregunta/respuesta podría incluir **captura de pantalla** o ilustración.

---

## 19. Escáner de Código de Barras

### Elementos de navegación visibles

| Elemento | Visibilidad | Descubribilidad |
|----------|-------------|-----------------|
| Visor de cámara | Pantalla completa | Inmediata |
| Recuadro guía | Centro, borde verde | Alta |
| Botón flash ⚡ | AppBar derecha | Alta |
| Botón cambiar cámara 🔄 | AppBar derecha | Alta |
| Texto instructivo | Inferior | Alta |

### Experiencia

El escáner es **automático**: detecta un código y hace pop inmediatamente devolviendo el valor. Sin embargo, **no hay animación de éxito** — el pop es instantáneo y puede sentirse abrupto. El usuario no tiene confirmación visual de que el escaneo fue exitoso antes de volver.

El recuadro guía (260×160, borde verde 2px) es claro. El texto "Coloca el código de barras dentro del recuadro" es útil para primeros usos.

Se usa `_scanned` flag para evitar múltiples detecciones del mismo código — buena práctica.

### Puntos de mejora

- **Animación de éxito**: flash verde + vibración háptica + breve pausa (300ms) antes del pop.
- Si el código escaneado no se encuentra en la base de datos, mostrar un **SnackBar o diálogo** ofreciendo crear un producto con ese barcode.
- El overlay frame podría tener **esquinas animadas** (pulso sutil) para indicar que está activo.

---

## 20. Resumen de Patrones de Navegación

### Patrones consistentes (bien)

| Patrón | Uso | Valoración |
|--------|-----|------------|
| Search bar + debounce | Warehouse detail, productos, warehouses, notificaciones | Consistente excepto en categorías |
| FilterChips horizontal | Warehouse detail, productos, stock history, shopping list | Bueno, con variaciones de estilo |
| EmptyView con acción | Todas las listas | Excelente |
| Diálogo de confirmación danger | Eliminaciones | Excelente |
| DeleteModeBar roja | Warehouse detail, productos, warehouses, shopping list, marcas, tiendas, categorías | Consistente |
| Pull-to-refresh | Dashboard, warehouse detail, notificaciones, productos | Inconsistente (falta en varias) |
| FAB para crear | Warehouses (draggable), Search (extended) | Inconsistente |
| Menú contextual ⋮ | Warehouses, warehouse detail, shopping list | Sobrecargado en shopping list |

### Anti-patrones (a mejorar)

| Anti-patrón | Ubicación | Problema |
|-------------|-----------|----------|
| Botón sin función | Login, Register, Welcome (⚙️) | Expectativa rota |
| Enlace sin acción | Login ("¿Olvidaste tu contraseña?") | Frustración |
| Menú con 1 sola opción | WarehouseDetail (⋮ solo "Eliminar") | Sobre-ingeniería |
| Menú con 7+ opciones | ShoppingList (⋮) | Sobrecarga cognitiva |
| Tap lleva a editar, no a detalle | ProductList → editar producto | Expectativa rota |
| Bottom sheet que cierra para navegar | AddProductSheet → "Crear nuevo" | Desorientación |
| Swipe sin indicador | Notificaciones | Descubribilidad nula |
| Notificación no navegable | NotificationList | Oportunidad perdida |
| Search bar falsa (GestureDetector) | Dashboard | Expectativa de input vs navegación |

---

## Resumen de Prioridades

| Prioridad | Mejora | Pantalla | Esfuerzo |
|-----------|--------|----------|----------|
| **Alta** | Tap en producto del catálogo → detalle, no editar | ProductList | Bajo |
| **Alta** | Notificaciones navegables al producto/almacén | Notifications | Bajo |
| **Alta** | Quitar botones muertos (⚙️ sin función) | Login, Register, Welcome | Bajo |
| **Alta** | Implementar o quitar "¿Olvidaste contraseña?" | Login | Medio |
| **Alta** | Indicador de swipe en onboarding | Welcome | Bajo |
| **Alta** | Menú ⋮ → papelera directa (1 sola opción) | WarehouseDetail | Bajo |
| **Media** | Sacar acciones frecuentes del menú ⋮ | ShoppingList | Medio |
| **Media** | Icono QR independiente en search bar | Dashboard | Bajo |
| **Media** | Animación de éxito en scanner | BarcodeScanner | Bajo |
| **Media** | Search bar en Categorías | CategoryList | Bajo |
| **Media** | Pull-to-refresh consistente | Varias pantallas | Bajo |
| **Media** | Unificar estilos de FilterChips | Varias pantallas | Medio |
| **Baja** | "Seleccionar todo" en shopping list | ShoppingList | Bajo |
| **Baja** | Búsqueda local en warehouse detail | WarehouseDetail | Medio |
| **Baja** | Barra de búsqueda en ayuda | Help | Bajo |
| **Baja** | Biometría en login | Login | Medio |
