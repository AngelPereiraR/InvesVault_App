# Spec: Fechas de Caducidad por Lotes en Productos de Almacén

**Fecha:** 2026-03-24
**Estado:** Aprobado
**Repositorios afectados:** `invesvault_api`, `InvesVault_App`

---

## Resumen

Implementar un sistema de lotes (batches) por producto en cada almacén, donde cada lote tiene su propia cantidad y fecha de caducidad opcional. El sistema genera notificaciones (backend + push local) cuando un lote caduca en 7 días o menos.

---

## 1. Base de Datos y Modelos (Backend)

### Nueva tabla: `warehouse_product_batches`

| Campo | Tipo | Restricciones |
|---|---|---|
| `id` | INTEGER | PK, autoincrement |
| `warehouse_product_id` | INTEGER | FK → `warehouse_products.id`, CASCADE DELETE |
| `quantity` | DECIMAL(10,2) | NOT NULL |
| `expiry_date` | DATE | nullable |
| `notes` | VARCHAR(255) | nullable |
| `created_at` | TIMESTAMP | NOT NULL, default NOW |

> Sequelize model: `timestamps: false`, `createdAt: 'created_at'` (sin `updatedAt`).

### Cambios en `warehouse_products`
- El campo `quantity` se mantiene como **suma cacheada** de los lotes asociados.
- Se actualiza dentro de una transacción en cada operación de lote (create/update/delete).

### Cambios en `notifications`
- Añadir campo `type` ENUM(`low_stock`, `expiry_warning`), NOT NULL, default `low_stock`.
- Añadir campo `batch_id` INTEGER nullable, FK → `warehouse_product_batches.id`, SET NULL on delete.
- Retrocompatible: las notificaciones existentes tendrán `batch_id = NULL` y `type = low_stock`.

### Cron Job
- Librería: `node-cron`
- Frecuencia: diaria (ej. cada día a las 08:00)
- Destinatarios: todos los miembros del almacén con rol `editor` o `admin` (los `viewer` no reciben notificaciones de caducidad).
- Lógica de deduplicación: antes de crear una notificación de caducidad, verificar que no existe ya una con el mismo `batch_id` + `type: expiry_warning` creada en las últimas 24h.

---

## 2. Endpoints API

### Lotes

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/warehouse-products/:id/batches` | Lista todos los lotes de un WarehouseProduct |
| `POST` | `/warehouse-products/:id/batches` | Crea un nuevo lote; actualiza `quantity` en transacción |
| `PUT` | `/warehouse-product-batches/:id` | Edita cantidad, fecha de caducidad o notas |
| `DELETE` | `/warehouse-product-batches/:id` | Elimina lote; recalcula `quantity` del WarehouseProduct |

**Autorización en PUT y DELETE:** el backend resuelve la cadena `batch → warehouse_product → warehouse → warehouse_users` para verificar que el usuario autenticado tiene rol `editor` o `admin` en ese almacén.

### Endpoint de chequeo manual (debug/tests)

| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/notifications/check-expiry` | Dispara manualmente el chequeo de caducidades |

### Cambios en endpoints existentes
- `POST /warehouse-products`: si `quantity > 0` en la creación, auto-crear un lote inicial sin fecha de caducidad.
- `GET /warehouses/:id/products`: añadir campo computado `has_expiring_batch: boolean` (true si algún lote del producto tiene `expiry_date` entre hoy y +7 días). El resto de la respuesta no cambia.
- Respuestas de notificaciones: incluir campos `type` y `batch_id` en el JSON de respuesta.

---

## 3. UI en la App (Flutter)

### Vista de almacén (lista de productos)
- El producto sigue mostrando la cantidad total como ahora.
- Si `has_expiring_batch === true`, mostrar badge/icono de advertencia naranja (el valor viene del endpoint existente, sin carga adicional).

### Vista de detalle del producto en almacén
Al expandir un producto en el almacén, se muestra la lista de lotes debajo:

```
📦 Producto: Leche entera  — 6 unidades
  └─ Lote 1:  2 uds   vence 28/03/2026  ⚠️
  └─ Lote 2:  3 uds   vence 15/04/2026
  └─ Lote 3:  1 ud    sin fecha
     [+ Añadir lote]
```

Cada lote tiene acciones de **editar** y **eliminar**.

### Dialog de añadir/editar lote
- Campos: `quantity` (requerido), `expiry_date` (date picker, opcional), `notes` (opcional).
- Implementado como `BottomSheet` o `AlertDialog`.

### Notificaciones
- Añadir `showExpiryNotification()` al `NotificationService` existente con un nuevo canal `expiry_channel`.
- Al abrir la app, el cubit de notificaciones consulta el backend; las notificaciones de tipo `expiry_warning` disparan push local **solo si su `id` no está ya registrado en SharedPreferences como "ya notificado"**. Se persiste el conjunto de IDs de notificaciones ya disparadas para evitar repetición al reabrir la app.
- En la pantalla de notificaciones, las alertas de caducidad muestran icono 📅 diferenciado del icono de stock bajo.

### Nuevos archivos Flutter

| Archivo | Propósito |
|---|---|
| `lib/data/models/batch_model.dart` | Modelo de datos para lote |
| `lib/data/datasources/batch_remote_datasource.dart` | Llamadas API de lotes |
| `lib/data/repositories/batch_repository.dart` | Repositorio de lotes |
| `lib/presentation/cubits/batch/batch_cubit.dart` | Cubit de gestión de lotes |
| `lib/presentation/cubits/batch/batch_state.dart` | Estados del cubit |
| `lib/presentation/dialogs/add_edit_batch_dialog.dart` | Dialog de añadir/editar lote |

---

## 4. Flujo Completo

```
Usuario añade stock → POST /warehouse-products/:id/batches
  → Crea lote en DB
  → Recalcula quantity en warehouse_products (transacción)
  → App refresca lista de lotes

Cron job diario (08:00)
  → Busca lotes con expiry_date en [hoy, hoy+7]
  → Para cada lote: si no existe notificación con batch_id + expiry_warning en últimas 24h
      → Crea notificación para cada miembro con rol editor/admin del almacén

Usuario abre la app
  → App consulta /notifications
  → Notificaciones expiry_warning con id no registrado → disparan push local + guardan id en SharedPreferences
  → Badge naranja aparece en productos con has_expiring_batch = true
```

---

## 5. Consideraciones Técnicas

- **Transacciones**: toda operación de lote que modifique `quantity` debe usar `sequelize.transaction()`.
- **Sin duplicados en notificaciones**: clave de deduplicación = `batch_id` + `type: expiry_warning` en ventana de 24h.
- **Retrocompatibilidad**: campo `type` con default `low_stock` y `batch_id` nullable; los clientes existentes no se ven afectados.
- **Lote inicial**: al crear un `WarehouseProduct` con `quantity > 0`, se genera un lote automático sin fecha para mantener la consistencia.
- **`has_expiring_batch`**: campo virtual calculado en el servicio backend al listar productos de almacén; no se almacena en BD.
- **Deduplicación push local**: usar `shared_preferences` para persistir el set de `notification.id` ya disparados como push local.
