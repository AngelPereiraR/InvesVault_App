# Design Spec: Listado de almacenes por producto

**Fecha:** 2026-03-23
**Proyecto:** Invesvault App + API
**Estado:** Aprobado

---

## Resumen

Desde el formulario de edición de un producto del catálogo (`/products/:id/edit`), el usuario puede navegar a una nueva pantalla que lista todos los almacenes del inventario donde ese producto está siendo utilizado. Desde esa lista puede acceder directamente al detalle del producto en cada almacén para editar su configuración específica (stock mínimo, precio, tienda).

---

## Motivación

Actualmente no existe forma de ver, desde el catálogo, en qué almacenes está un producto ni acceder a su configuración por almacén. El usuario tendría que ir almacén por almacén para encontrarlo. Esta feature cierra esa brecha de UX.

---

## Alcance

- **Backend (invesvault_api):** nuevo endpoint REST
- **Frontend (Invesvault_App):** nueva capa de datos, nuevo cubit, nueva pantalla, entrada desde `ProductFormScreen`

---

## Backend

### Nuevo endpoint

```
GET /api/v1/products/:id/warehouses
Authorization: Bearer <token>
x-api-key: <key>
```

**Respuesta:** array de `WarehouseProduct` con el almacén embebido.

```json
[
  {
    "id": 12,
    "warehouse_id": 3,
    "product_id": 7,
    "quantity": "5.00",
    "min_quantity": "2.00",
    "price_per_unit": "1.50",
    "store_id": 1,
    "last_updated": "2026-03-20T10:00:00.000Z",
    "warehouse": {
      "id": 3,
      "name": "Almacén Principal",
      "is_shared": false
    },
    "last_store": { "id": 1, "name": "Mercadona" },
    "product": { "id": 7, "name": "Leche", "default_unit": "l", "barcode": null, "brand": null }
  }
]
```

> **Nota:** el campo `last_store` sigue la convención existente del modelo `WarehouseProductModel.fromJson`, que ya parsea la tienda desde esa clave. El embed `product` se incluye para permitir mostrar `product.defaultUnit` en la tarjeta; el servicio backend debe incluir la asociación `Product` en el query (siguiendo el mismo patrón que `getProducts(warehouseId)`).

**Control de acceso:** se devuelven únicamente los almacenes donde el usuario autenticado es propietario (`Warehouse.owner_id`) O es miembro vía `WarehouseUser`, independientemente del valor de `is_shared`.

### Archivos a modificar (backend)

| Archivo | Cambio |
|---|---|
| `src/services/warehouseProductService.js` | Nueva función `getWarehousesByProduct(productId, userId)` |
| `src/api/controllers/warehouseProductController.js` | Nueva función `getByProduct` |
| `src/api/routes/productRoutes.js` | Nueva ruta `GET /:id/warehouses` con `authenticate` + `validateProductId` |

---

## Frontend

### Capa de datos

**`lib/core/constants/api_constants.dart`**
```dart
static String productWarehouses(int id) => '/products/$id/warehouses';
```

**`lib/data/models/warehouse_product_model.dart`**
- Añadir campo opcional `final String? warehouseName`
- `fromJson`: `warehouseName: (json['warehouse'] as Map<String, dynamic>?)?['name'] as String?`
- Incluir `warehouseName` en `props` de `Equatable`
- El getter `isLowStock` **ya existe** en el modelo: `bool get isLowStock => minQuantity != null && quantity < minQuantity!`. No requiere cambios.

**`lib/data/datasources/warehouse_product_remote_datasource.dart`**
- Nuevo método:
```dart
Future<List<WarehouseProductModel>> getWarehousesByProduct(int productId) async
```
Llama a `GET /products/$productId/warehouses`. Retorna lista vacía en 404.

**`lib/data/repositories/warehouse_product_repository.dart`**
- Nuevo método que delega al datasource:
```dart
Future<List<WarehouseProductModel>> getWarehousesByProduct(int productId) =>
    _datasource.getWarehousesByProduct(productId);
```

### Estado (Cubit)

Ubicación: `lib/presentation/cubits/product_warehouses/`

**`product_warehouses_state.dart`**
```dart
abstract class ProductWarehousesState extends Equatable {}
class ProductWarehousesInitial extends ProductWarehousesState {}
class ProductWarehousesLoading extends ProductWarehousesState {}
class ProductWarehousesLoaded extends ProductWarehousesState {
  final List<WarehouseProductModel> items;
}
class ProductWarehousesError extends ProductWarehousesState {
  final String message;
}
```

**`product_warehouses_cubit.dart`**
```dart
class ProductWarehousesCubit extends Cubit<ProductWarehousesState> {
  final WarehouseProductRepository _repo;
  Future<void> load(int productId) async { ... }
}
```

El cubit depende de `WarehouseProductRepository` (ya existente). Se provee **globalmente** en `lib/app.dart` dentro del `MultiBlocProvider`, siguiendo el patrón de todos los demás cubits del proyecto.

### Pantalla

**`lib/presentation/screens/products/product_warehouses_screen.dart`**

- Constructor: `ProductWarehousesScreen({ required int productId, required String productName })`
- `AppBar` título: `'Almacenes con este producto'`
- `initState`: llama a `ProductWarehousesCubit.load(productId)`
- **Estados:**
  - Loading → `LoadingIndicator`
  - Error → `ErrorView` con retry
  - Loaded vacío → `EmptyView('Este producto no está en ningún almacén')`
  - Loaded con datos → `ListView` de tarjetas
- **Cada tarjeta muestra:**
  - Nombre del almacén (`wp.warehouseName`)
  - Stock actual + unidad (del `product.defaultUnit` embebido)
  - Cantidad mínima (si existe), con badge de alerta si `wp.isLowStock` (getter existente)
  - Precio/unidad (si existe)
  - Tienda (`wp.store?.name`, si existe)
  - Icono `Icons.chevron_right`
- **Tap en tarjeta** → navega a `/products/${wp.id}/detail` con `extra: {'warehouseId': wp.warehouseId}`
  > **Nota:** `wp.id` es el `WarehouseProductModel.id`, es decir, el id del registro join (`warehouseProductId`) que espera `ProductDetailScreen`. No confundir con `wp.productId`.

### Navegación

**`lib/core/router/app_router.dart`** — nuevo case en `_buildPage`:

```dart
final productWarehousesMatch =
    RegExp(r'^/products/(\d+)/warehouses$').firstMatch(route);
if (productWarehousesMatch != null) {
  final args = extra as Map<String, dynamic>?;
  return ProductWarehousesScreen(
    productId: int.parse(productWarehousesMatch.group(1)!),
    productName: args?['productName'] as String? ?? '',
  );
}
```

### Punto de entrada

**`lib/presentation/screens/products/product_form_screen.dart`** — en modo edición (`isEdit == true`), debajo del botón "Guardar cambios":

```dart
if (isEdit) ...[
  const SizedBox(height: 12),
  OutlinedButton.icon(
    icon: const Icon(Icons.warehouse_outlined),
    label: const Text('Ver en almacenes'),
    onPressed: () => context.openAuxiliaryRoute(
      '/products/${widget.productId}/warehouses',
      extra: {'productName': _nameCtrl.text},
    ),
  ),
]
```

> `context.openAuxiliaryRoute` es una extension existente en `AppNavigationContext` (`app_router.dart`).

---

## Flujo completo

```
Catálogo → [popup Editar] → ProductFormScreen (edit)
  → [botón "Ver en almacenes"] → ProductWarehousesScreen
    → [tap en almacén] → ProductDetailScreen (ya existente)
      → editar stock mínimo / precio / tienda / ajuste rápido
```

---

## Consideraciones

- `ProductDetailScreen` ya implementa toda la UI de edición por almacén (`_WarehouseDetailsEditor`). No se duplica lógica.
- El campo `warehouseName` en `WarehouseProductModel` es opcional y backwards-compatible; los usos existentes no se ven afectados.
- El getter `isLowStock` ya existe en el modelo; no requiere cambios.
- El nuevo endpoint filtra por acceso del usuario (propietario o miembro vía `WarehouseUser`), coherente con el resto de la API.
- El repositorio `WarehouseProductRepository` ya existe; solo se añade un método.
