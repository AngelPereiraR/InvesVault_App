# Product Warehouses List — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Desde el formulario de edición de un producto, poder navegar a la lista de almacenes donde ese producto está en uso y acceder al detalle editable por almacén.

**Architecture:** Se añade un endpoint REST `GET /api/v1/products/:id/warehouses` en el backend que devuelve los `WarehouseProduct` del producto filtrados por acceso del usuario. El frontend añade la capa de datos, un nuevo Cubit, una nueva pantalla y el punto de entrada en `ProductFormScreen`.

**Tech Stack:** Express.js + Sequelize (backend) · Flutter + BLoC/Cubit + Dio (frontend)

**Spec:** `docs/superpowers/specs/2026-03-23-product-warehouses-list-design.md`

---

## File Map

### Backend (`E:/Proyectos/invesvault_api`)

| Acción | Archivo |
|---|---|
| Modify | `src/services/warehouseProductService.js` |
| Modify | `src/api/controllers/warehouseProductController.js` |
| Modify | `src/api/routes/productRoutes.js` |
| Modify (test) | `tests/product.test.js` |

### Frontend (`E:/Proyectos/InvesVault_App`)

| Acción | Archivo |
|---|---|
| Modify | `lib/core/constants/api_constants.dart` |
| Modify | `lib/data/models/warehouse_product_model.dart` |
| Modify | `lib/data/datasources/warehouse_product_remote_datasource.dart` |
| Modify | `lib/data/repositories/warehouse_product_repository.dart` |
| Create | `lib/presentation/cubits/product_warehouses/product_warehouses_state.dart` |
| Create | `lib/presentation/cubits/product_warehouses/product_warehouses_cubit.dart` |
| Create | `lib/presentation/screens/products/product_warehouses_screen.dart` |
| Modify | `lib/core/router/app_router.dart` |
| Modify | `lib/app.dart` |
| Modify | `lib/presentation/screens/products/product_form_screen.dart` |

---

## PARTE 1 — Backend

### Task 1: Servicio — `getWarehousesByProduct`

**Files:**
- Modify: `src/services/warehouseProductService.js`

- [ ] **Step 1: Añadir la función al servicio**

Al final de `src/services/warehouseProductService.js`, antes del bloque de exports, añadir:

```js
/**
 * Obtiene todos los WarehouseProduct de un producto específico,
 * filtrados a los almacenes accesibles por el usuario.
 * @param {number} productId - El ID del producto.
 * @param {number} userId - El ID del usuario autenticado.
 * @returns {Promise<Array<object>>} Array de WarehouseProduct con warehouse, product y store embebidos.
 */
const getWarehousesByProduct = async (productId, userId) => {
  try {
    const memberRows = await WarehouseUser.findAll({ where: { user_id: userId } });
    const memberWarehouseIds = memberRows.map((r) => r.warehouse_id);

    const products = await WarehouseProduct.findAll({
      where: { product_id: productId },
      include: [
        {
          model: Warehouse,
          as: 'warehouse',
          required: true,
          where: {
            [Op.or]: [
              { owner_id: userId },
              { id: { [Op.in]: memberWarehouseIds.length ? memberWarehouseIds : [0] } },
            ],
          },
        },
        {
          model: Product,
          as: 'product',
          include: [{ model: Brand, as: 'brand' }],
        },
        { model: Store, as: 'last_store' },
      ],
    });
    return products;
  } catch (error) {
    throw error;
  }
};
```

> **Nota sobre `[0]`:** si el usuario no es miembro de ningún almacén, `[Op.in]: []` produce SQL inválido en Sequelize. El fallback `[0]` garantiza un array siempre válido (ningún almacén tendrá id 0).

- [ ] **Step 2: Verificar que `WarehouseUser` y `Op` están importados en el archivo**

Busca los imports al inicio del archivo. Si `WarehouseUser` no está importado, añadirlo:
```js
import WarehouseUser from '../database/models/warehouseUser.js';
```
`Op` y `Warehouse` ya deberían estar importados — confirma que están.

- [ ] **Step 3: Añadir `getWarehousesByProduct` al bloque de exports**

Al final del archivo, localiza el `export { ... }` y añade `getWarehousesByProduct`:
```js
export {
  getWarehouseProducts,
  addProductToWarehouse,
  updateWarehouseProduct,
  removeProductFromWarehouse,
  getLowStockProducts,
  getWarehousesByProduct,   // ← añadir
};
```

- [ ] **Step 4: Commit**

```bash
cd E:/Proyectos/invesvault_api
git add src/services/warehouseProductService.js
git commit -m "feat: add getWarehousesByProduct service function"
```

---

### Task 2: Controlador y Ruta

**Files:**
- Modify: `src/api/controllers/warehouseProductController.js`
- Modify: `src/api/routes/productRoutes.js`

- [ ] **Step 1: Añadir el controlador `getByProduct`**

En `src/api/controllers/warehouseProductController.js`:

1. Añadir `getWarehousesByProduct` al import del servicio:
```js
import {
  getWarehouseProducts,
  addProductToWarehouse,
  updateWarehouseProduct,
  removeProductFromWarehouse,
  getLowStockProducts,
  getWarehousesByProduct,   // ← añadir
} from '../../services/warehouseProductService.js';
```

2. Añadir la función controlador antes del bloque `export`:
```js
/**
 * Obtiene todos los almacenes donde un producto está en uso,
 * filtrados por acceso del usuario autenticado.
 */
const getByProduct = async (req, res) => {
  try {
    const productId = parseInt(req.params.id, 10);
    const userId = req.user.id;
    const items = await getWarehousesByProduct(productId, userId);
    res.status(200).json(items);
  } catch (error) {
    console.error('Error al obtener almacenes por producto:', error);
    res.status(500).json({ message: 'Error interno del servidor.' });
  }
};
```

3. Añadir `getByProduct` al bloque `export { ... }` al final del archivo.

- [ ] **Step 2: Añadir la ruta en `productRoutes.js`**

1. Añadir `getByProduct` al import del controlador:
```js
import {
  create,
  getAll,
  getById,
  update,
  remove,
  getByProduct,   // ← añadir
} from '../controllers/warehouseProductController.js';
```

> **Importante:** la ruta `/:id/warehouses` debe definirse **antes** de `/:id` para evitar que Express capture `warehouses` como un id numérico.

2. Insertar la ruta antes de `router.get('/:id', ...)`:
```js
/**
 * @route GET /api/products/:id/warehouses
 * @desc Obtiene todos los almacenes donde el producto está en uso (accesibles por el usuario).
 * @access Private (Auth)
 */
router.get('/:id/warehouses', authenticate, validateProductId, getByProduct);
```

- [ ] **Step 3: Commit**

```bash
cd E:/Proyectos/invesvault_api
git add src/api/controllers/warehouseProductController.js src/api/routes/productRoutes.js
git commit -m "feat: add GET /products/:id/warehouses endpoint"
```

---

### Task 3: Tests del endpoint

**Files:**
- Modify: `tests/product.test.js`

- [ ] **Step 1: Revisar el setup de `product.test.js`**

Abre el archivo y localiza cómo se monta el `app` de Express en los tests. Debería verse algo como:
```js
app.use('/api/products', productRoutes);
```
Si ya está montado así, la nueva ruta `/api/products/:id/warehouses` ya está accesible.

- [ ] **Step 2: Añadir bloque de tests al final del archivo**

Añadir al final de `tests/product.test.js` (antes del cierre del módulo si lo hay):

```js
describe('GET /api/products/:id/warehouses - Almacenes por producto', () => {
  test('Debe devolver los almacenes del usuario donde está el producto', async () => {
    const user = await createTestUser({ role: 'admin' });
    const token = generateToken(user.id, user.email, user.role);
    const warehouse = await createTestWarehouse(user.id);
    const product = await createTestProduct();

    // Añadir el producto al almacén
    await request(app)
      .post('/api/warehouse-products')
      .set('Authorization', `Bearer ${token}`)
      .send({ warehouse_id: warehouse.id, product_id: product.id, quantity: 10 });

    const response = await request(app)
      .get(`/api/products/${product.id}/warehouses`)
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body.length).toBe(1);
    expect(response.body[0]).toHaveProperty('product_id', product.id);
    expect(response.body[0]).toHaveProperty('warehouse_id', warehouse.id);
    expect(response.body[0].warehouse).toHaveProperty('name', warehouse.name);
  });

  test('Debe devolver array vacío si el producto no está en ningún almacén', async () => {
    const user = await createTestUser({ role: 'admin' });
    const token = generateToken(user.id, user.email, user.role);
    const product = await createTestProduct();

    const response = await request(app)
      .get(`/api/products/${product.id}/warehouses`)
      .set('Authorization', `Bearer ${token}`);

    expect(response.status).toBe(200);
    expect(response.body).toEqual([]);
  });

  test('No debe devolver almacenes de otros usuarios', async () => {
    const owner = await createTestUser({ role: 'admin' });
    const otherUser = await createTestUser({ role: 'admin' });
    const ownerToken = generateToken(owner.id, owner.email, owner.role);
    const otherToken = generateToken(otherUser.id, otherUser.email, otherUser.role);
    const warehouse = await createTestWarehouse(owner.id);
    const product = await createTestProduct();

    await request(app)
      .post('/api/warehouse-products')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ warehouse_id: warehouse.id, product_id: product.id, quantity: 5 });

    // otherUser no tiene acceso al warehouse de owner
    const response = await request(app)
      .get(`/api/products/${product.id}/warehouses`)
      .set('Authorization', `Bearer ${otherToken}`);

    expect(response.status).toBe(200);
    expect(response.body).toEqual([]);
  });

  test('Debe requerir autenticación', async () => {
    const product = await createTestProduct();

    const response = await request(app)
      .get(`/api/products/${product.id}/warehouses`);

    expect(response.status).toBe(401);
  });
});
```

> **Nota:** si `product.test.js` no tiene montado `warehouseProductRoutes` en su app local, deberás añadir `app.use('/api/warehouse-products', warehouseProductRoutes)` en el setup del test para poder crear los `WarehouseProduct` de prueba. Revisa las importaciones al inicio del archivo.

- [ ] **Step 3: Ejecutar los tests nuevos**

```bash
cd E:/Proyectos/invesvault_api
npm test -- product.test.js
```

Expected: todos los tests del describe nuevo pasan. Si alguno falla, revisa el mensaje de error antes de continuar.

- [ ] **Step 4: Ejecutar suite completa para verificar no hay regresiones**

```bash
npm test
```

Expected: todos los tests pasan.

- [ ] **Step 5: Commit**

```bash
git add tests/product.test.js
git commit -m "test: add tests for GET /products/:id/warehouses endpoint"
```

---

## PARTE 2 — Frontend

### Task 4: Capa de datos

**Files:**
- Modify: `lib/core/constants/api_constants.dart`
- Modify: `lib/data/models/warehouse_product_model.dart`
- Modify: `lib/data/datasources/warehouse_product_remote_datasource.dart`
- Modify: `lib/data/repositories/warehouse_product_repository.dart`

- [ ] **Step 1: Añadir constante de API**

En `lib/core/constants/api_constants.dart`, dentro de la clase `ApiConstants`, añadir junto al resto de warehouse-products:
```dart
static String productWarehouses(int id) => '/products/$id/warehouses';
```

- [ ] **Step 2: Añadir campo `warehouseName` al modelo**

En `lib/data/models/warehouse_product_model.dart`:

1. Añadir campo al constructor:
```dart
final String? warehouseName;
```

2. Añadir al constructor nombrado (después de `this.store`):
```dart
this.warehouseName,
```

3. Añadir en `fromJson` (después de `store: storeJson != null ...`):
```dart
warehouseName: (json['warehouse'] as Map<String, dynamic>?)?['name'] as String?,
```

4. Añadir a `props` (al final de la lista):
```dart
warehouseName,
```

> **Backwards-compatible:** el campo es opcional. Todos los `fromJson` existentes lo recibirán como `null` sin problema.

- [ ] **Step 3: Añadir método al datasource**

En `lib/data/datasources/warehouse_product_remote_datasource.dart`, añadir al final de la clase:
```dart
Future<List<WarehouseProductModel>> getWarehousesByProduct(int productId) async {
  try {
    final response = await _dio.get(ApiConstants.productWarehouses(productId));
    return (response.data as List)
        .map((e) => WarehouseProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return [];
    rethrow;
  }
}
```

- [ ] **Step 4: Añadir método al repositorio**

En `lib/data/repositories/warehouse_product_repository.dart`, añadir:
```dart
Future<List<WarehouseProductModel>> getWarehousesByProduct(int productId) =>
    _datasource.getWarehousesByProduct(productId);
```

- [ ] **Step 5: Verificar que la app compila**

```bash
cd E:/Proyectos/InvesVault_App
flutter analyze
```

Expected: sin errores nuevos (pueden existir warnings previos; no introducir nuevos).

- [ ] **Step 6: Commit**

```bash
cd E:/Proyectos/InvesVault_App
git add lib/core/constants/api_constants.dart \
        lib/data/models/warehouse_product_model.dart \
        lib/data/datasources/warehouse_product_remote_datasource.dart \
        lib/data/repositories/warehouse_product_repository.dart
git commit -m "feat: add data layer for product warehouses list"
```

---

### Task 5: Cubit y Estado

**Files:**
- Create: `lib/presentation/cubits/product_warehouses/product_warehouses_state.dart`
- Create: `lib/presentation/cubits/product_warehouses/product_warehouses_cubit.dart`

- [ ] **Step 1: Crear el archivo de estados**

Crear `lib/presentation/cubits/product_warehouses/product_warehouses_state.dart`:

```dart
part of 'product_warehouses_cubit.dart';

abstract class ProductWarehousesState extends Equatable {
  const ProductWarehousesState();

  @override
  List<Object?> get props => [];
}

class ProductWarehousesInitial extends ProductWarehousesState {}

class ProductWarehousesLoading extends ProductWarehousesState {}

class ProductWarehousesLoaded extends ProductWarehousesState {
  final List<WarehouseProductModel> items;
  const ProductWarehousesLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class ProductWarehousesError extends ProductWarehousesState {
  final String message;
  const ProductWarehousesError(this.message);

  @override
  List<Object?> get props => [message];
}
```

- [ ] **Step 2: Crear el cubit**

Crear `lib/presentation/cubits/product_warehouses/product_warehouses_cubit.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/warehouse_product_model.dart';
import '../../../data/repositories/warehouse_product_repository.dart';

part 'product_warehouses_state.dart';

class ProductWarehousesCubit extends Cubit<ProductWarehousesState> {
  final WarehouseProductRepository _repo;

  ProductWarehousesCubit(this._repo) : super(ProductWarehousesInitial());

  Future<void> load(int productId) async {
    emit(ProductWarehousesLoading());
    try {
      final items = await _repo.getWarehousesByProduct(productId);
      emit(ProductWarehousesLoaded(items));
    } catch (e) {
      emit(ProductWarehousesError('Error al cargar almacenes: ${e.toString()}'));
    }
  }
}
```

- [ ] **Step 3: Verificar compilación**

```bash
cd E:/Proyectos/InvesVault_App
flutter analyze
```

Expected: sin errores nuevos.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/cubits/product_warehouses/
git commit -m "feat: add ProductWarehousesCubit and states"
```

---

### Task 6: Pantalla `ProductWarehousesScreen`

**Files:**
- Create: `lib/presentation/screens/products/product_warehouses_screen.dart`

- [ ] **Step 1: Crear la pantalla**

Crear `lib/presentation/screens/products/product_warehouses_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/warehouse_product_model.dart';
import '../../cubits/product_warehouses/product_warehouses_cubit.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class ProductWarehousesScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const ProductWarehousesScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductWarehousesScreen> createState() =>
      _ProductWarehousesScreenState();
}

class _ProductWarehousesScreenState extends State<ProductWarehousesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductWarehousesCubit>().load(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Almacenes con este producto'),
            if (widget.productName.isNotEmpty)
              Text(
                widget.productName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ProductWarehousesCubit, ProductWarehousesState>(
          builder: (context, state) {
            if (state is ProductWarehousesLoading ||
                state is ProductWarehousesInitial) {
              return const LoadingIndicator();
            }
            if (state is ProductWarehousesError) {
              return ErrorView(
                message: state.message,
                onRetry: () =>
                    context.read<ProductWarehousesCubit>().load(widget.productId),
              );
            }
            if (state is ProductWarehousesLoaded) {
              if (state.items.isEmpty) {
                return const EmptyView(
                  message: 'Este producto no está en ningún almacén',
                );
              }
              return RefreshIndicator(
                onRefresh: () => context
                    .read<ProductWarehousesCubit>()
                    .load(widget.productId),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    return _WarehouseTile(
                      wp: state.items[i],
                      productName: widget.productName,
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _WarehouseTile extends StatelessWidget {
  final WarehouseProductModel wp;
  final String productName;

  const _WarehouseTile({required this.wp, required this.productName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unit = wp.product?.defaultUnit ?? '';

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.warehouse_outlined, color: cs.primary, size: 20),
        ),
        title: Text(
          wp.warehouseName ?? 'Almacén #${wp.warehouseId}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Stock: ${wp.quantity.toStringAsFixed(2)} $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (wp.isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stock bajo',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (wp.minQuantity != null)
              Text(
                'Mínimo: ${wp.minQuantity!.toStringAsFixed(2)} $unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            if (wp.pricePerUnit != null)
              Text(
                'Precio: ${wp.pricePerUnit!.toStringAsFixed(2)} €/ud',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            if (wp.store != null)
              Text(
                'Tienda: ${wp.store!.name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.openAuxiliaryRoute(
          '/products/${wp.id}/detail',
          extra: {'warehouseId': wp.warehouseId},
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verificar compilación**

```bash
cd E:/Proyectos/InvesVault_App
flutter analyze
```

Expected: sin errores nuevos.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/products/product_warehouses_screen.dart
git commit -m "feat: add ProductWarehousesScreen"
```

---

### Task 7: Navegación, DI y punto de entrada

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/app.dart`
- Modify: `lib/presentation/screens/products/product_form_screen.dart`

- [ ] **Step 1: Registrar la ruta en `app_router.dart`**

En `lib/core/router/app_router.dart`:

1. Añadir el import de la nueva pantalla al inicio del archivo (junto a los demás imports de screens):
```dart
import '../../presentation/screens/products/product_warehouses_screen.dart';
```

2. En la función `_buildPage`, añadir el nuevo case **antes** del case `productDetailMatch` (para evitar conflictos de regex):
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

- [ ] **Step 2: Registrar `ProductWarehousesCubit` en `app.dart`**

En `lib/app.dart`:

1. Añadir el import del cubit al inicio (junto a los demás imports de cubits):
```dart
import 'presentation/cubits/product_warehouses/product_warehouses_cubit.dart';
```

2. Dentro del `MultiBlocProvider`, en la lista de `BlocProvider`s (por ejemplo, junto a `ProductDetailCubit`), añadir:
```dart
BlocProvider(
  create: (_) => ProductWarehousesCubit(_warehouseProductRepo),
),
```

> **Nota:** `_warehouseProductRepo` es la instancia de `WarehouseProductRepository` ya declarada en `app.dart` (usada por `ProductDetailCubit`). No crear una nueva instancia.

- [ ] **Step 3: Añadir botón en `ProductFormScreen`**

En `lib/presentation/screens/products/product_form_screen.dart`, dentro del `Column` del formulario, **después** del `AppButton` de guardar:

```dart
if (isEdit) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      icon: const Icon(Icons.warehouse_outlined),
      label: const Text('Ver en almacenes'),
      onPressed: () => context.openAuxiliaryRoute(
        '/products/${widget.productId}/warehouses',
        extra: {'productName': _nameCtrl.text},
      ),
    ),
  ),
],
```

- [ ] **Step 4: Verificar compilación completa**

```bash
cd E:/Proyectos/InvesVault_App
flutter analyze
```

Expected: sin errores.

- [ ] **Step 5: Smoke test manual**

1. Ejecutar la app: `flutter run`
2. Ir al Catálogo → popup de un producto → Editar
3. Verificar que aparece el botón "Ver en almacenes" al final del formulario
4. Tocar el botón → debe abrirse `ProductWarehousesScreen` con la lista de almacenes
5. Tocar un almacén → debe navegar a `ProductDetailScreen` con los datos correctos
6. Verificar que la UI muestra el badge "Stock bajo" si corresponde

- [ ] **Step 6: Commit final**

```bash
cd E:/Proyectos/InvesVault_App
git add lib/core/router/app_router.dart \
        lib/app.dart \
        lib/presentation/screens/products/product_form_screen.dart
git commit -m "feat: wire up ProductWarehousesScreen navigation and entry point"
```
