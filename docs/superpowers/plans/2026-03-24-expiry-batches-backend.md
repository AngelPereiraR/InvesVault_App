# Expiry Dates & Batches — Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `warehouse_product_batches` table to track per-batch quantities and optional expiry dates, update the `notifications` table with `type`/`batch_id`, expose CRUD endpoints for batches, and add a daily cron job that generates expiry-warning notifications.

**Architecture:** Each `WarehouseProduct` gets a set of `WarehouseProductBatch` rows; the existing `quantity` column stays as a cached sum and is always recomputed in a Sequelize transaction on batch mutations. Notifications gain a `type` ENUM and nullable `batch_id` FK; old rows keep their defaults. `node-cron` fires daily at 08:00, finds batches expiring within 7 days, and creates de-duplicated notifications for editors/admins.

**Tech Stack:** Node.js (ESM), Express, Sequelize + PostgreSQL (Neon), node-cron, Jest + Supertest.

**Working directory:** `E:/Proyectos/invesvault_api`

---

## File Map

### New files
| Path | Responsibility |
|---|---|
| `src/database/models/warehouseProductBatch.js` | Sequelize model for `warehouse_product_batches` |
| `src/services/batchService.js` | Business logic: CRUD + quantity recalc + expiry check |
| `src/api/controllers/batchController.js` | HTTP handlers for batch endpoints |
| `src/api/routes/batchRoutes.js` | Route definitions for `/warehouse-products/:id/batches` and `/warehouse-product-batches/:id` |
| `src/api/validators/batchValidator.js` | Joi schemas for batch create/update |
| `src/api/middlewares/batchAuthMiddleware.js` | Resolves batch → warehouseProduct → warehouse and checks editor/admin role |
| `src/jobs/expiryCheckJob.js` | `node-cron` daily job + `checkExpiryBatches()` function |
| `tests/batch.test.js` | Integration tests for all batch endpoints |
| `tests/expiryCheck.test.js` | Integration tests for expiry notification logic |

### Modified files
| Path | Change |
|---|---|
| `src/database/models/notification.js` | Add `type` ENUM and `batch_id` INTEGER fields |
| `src/database/models/index.js` | Import `WarehouseProductBatch`, add associations, export it |
| `src/services/warehouseProductService.js` | `addProductToWarehouse` auto-creates initial batch if `quantity > 0`; `getWarehouseProducts` adds virtual `has_expiring_batch` |
| `src/services/notificationService.js` | Include `type` and `batch_id` in responses |
| `src/api/routes/notificationRoutes.js` | Add `POST /notifications/check-expiry` route |
| `src/api/controllers/notificationController.js` | Add `checkExpiry` handler |
| `src/index.js` | Mount batch routes + initialise cron job |
| `tests/testUtils.js` | Add `createTestBatch()` helper |

---

## Task 1: Model — `WarehouseProductBatch`

**Files:**
- Create: `src/database/models/warehouseProductBatch.js`
- Modify: `src/database/models/index.js`

- [ ] **Step 1: Create the model file**

```js
// src/database/models/warehouseProductBatch.js
import { DataTypes } from 'sequelize';
import { sequelize } from '../../config/sequelize.js';

const WarehouseProductBatch = sequelize.define('WarehouseProductBatch', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  warehouse_product_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  quantity: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  expiry_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  notes: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  created_at: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'warehouse_product_batches',
  timestamps: false,
});

export default WarehouseProductBatch;
```

- [ ] **Step 2: Register in index.js**

In `src/database/models/index.js`:
1. Add import after `WarehouseProduct`:
   ```js
   import WarehouseProductBatch from './warehouseProductBatch.js';
   ```
2. Add associations after the existing `Product - WarehouseProduct` block:
   ```js
   // WarehouseProduct - WarehouseProductBatch
   WarehouseProduct.hasMany(WarehouseProductBatch, {
     foreignKey: 'warehouse_product_id',
     as: 'batches',
     onDelete: 'CASCADE',
   });
   WarehouseProductBatch.belongsTo(WarehouseProduct, {
     foreignKey: 'warehouse_product_id',
     as: 'warehouseProduct',
   });
   ```
3. Add `WarehouseProductBatch` to the `export { ... }` list.

- [ ] **Step 3: Commit**
```bash
git add src/database/models/warehouseProductBatch.js src/database/models/index.js
git commit -m "feat: add WarehouseProductBatch model and associations"
```

---

## Task 2: Model — Update `Notification`

**Files:**
- Modify: `src/database/models/notification.js`
- Modify: `src/database/models/index.js`

- [ ] **Step 1: Add `type` and `batch_id` fields to `notification.js`**

Add after the `is_read` field:
```js
  type: {
    type: DataTypes.ENUM('low_stock', 'expiry_warning'),
    allowNull: false,
    defaultValue: 'low_stock',
  },
  batch_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
```

- [ ] **Step 2: Add association in `index.js`**

After the `Warehouse - Notification` block add:
```js
// WarehouseProductBatch - Notification
WarehouseProductBatch.hasMany(Notification, {
  foreignKey: 'batch_id',
  onDelete: 'SET NULL',
});
Notification.belongsTo(WarehouseProductBatch, {
  foreignKey: 'batch_id',
  as: 'batch',
});
```

- [ ] **Step 3: Commit**
```bash
git add src/database/models/notification.js src/database/models/index.js
git commit -m "feat: add type and batch_id fields to Notification model"
```

---

## Task 3: Test helper + database init

**Files:**
- Modify: `tests/testUtils.js`

- [ ] **Step 1: Add `createTestBatch` to testUtils.js**

```js
// Add import at top if not present
import { WarehouseProductBatch } from '../src/database/models/index.js';

export async function createTestBatch(warehouseProductId, overrides = {}) {
  return WarehouseProductBatch.create({
    warehouse_product_id: warehouseProductId,
    quantity: 5,
    expiry_date: null,
    notes: null,
    ...overrides,
  });
}
```

- [ ] **Step 2: Re-init test database**
```bash
npm run init-test-db
```
Expected: tables created without errors (including `warehouse_product_batches`).

- [ ] **Step 3: Commit**
```bash
git add tests/testUtils.js
git commit -m "test: add createTestBatch helper and reinit test DB"
```

---

## Task 4: `batchService.js` — core logic

**Files:**
- Create: `src/services/batchService.js`

- [ ] **Step 1: Write the service**

```js
// src/services/batchService.js
import { sequelize, WarehouseProductBatch, WarehouseProduct } from '../database/models/index.js';

export async function getBatchesByWarehouseProduct(warehouseProductId) {
  return WarehouseProductBatch.findAll({
    where: { warehouse_product_id: warehouseProductId },
    order: [['created_at', 'ASC']],
  });
}

export async function createBatch(warehouseProductId, data) {
  return sequelize.transaction(async (t) => {
    const batch = await WarehouseProductBatch.create(
      { warehouse_product_id: warehouseProductId, ...data },
      { transaction: t }
    );
    await recalcQuantity(warehouseProductId, t);
    return batch;
  });
}

export async function updateBatch(batchId, data) {
  const batch = await WarehouseProductBatch.findByPk(batchId);
  if (!batch) throw new Error('Lote no encontrado');
  return sequelize.transaction(async (t) => {
    await batch.update(data, { transaction: t });
    await recalcQuantity(batch.warehouse_product_id, t);
    return batch.reload({ transaction: t });
  });
}

export async function deleteBatch(batchId) {
  const batch = await WarehouseProductBatch.findByPk(batchId);
  if (!batch) throw new Error('Lote no encontrado');
  const warehouseProductId = batch.warehouse_product_id;
  return sequelize.transaction(async (t) => {
    await batch.destroy({ transaction: t });
    await recalcQuantity(warehouseProductId, t);
  });
}

async function recalcQuantity(warehouseProductId, transaction) {
  const batches = await WarehouseProductBatch.findAll({
    where: { warehouse_product_id: warehouseProductId },
    transaction,
  });
  const total = batches.reduce((sum, b) => sum + parseFloat(b.quantity), 0);
  await WarehouseProduct.update(
    { quantity: total },
    { where: { id: warehouseProductId }, transaction }
  );
}

export async function getBatchIdForWarehouseProduct(batchId) {
  const batch = await WarehouseProductBatch.findByPk(batchId);
  return batch ? batch.warehouse_product_id : null;
}
```

- [ ] **Step 2: Commit**
```bash
git add src/services/batchService.js
git commit -m "feat: add batchService with CRUD and quantity recalculation"
```

---

## Task 5: Batch validator + auth middleware

**Files:**
- Create: `src/api/validators/batchValidator.js`
- Create: `src/api/middlewares/batchAuthMiddleware.js`

- [ ] **Step 1: Validator**

```js
// src/api/validators/batchValidator.js
import Joi from 'joi';
import { validate } from './validate.js'; // reuse existing wrapper

const createBatchSchema = Joi.object({
  quantity: Joi.number().positive().required(),
  expiry_date: Joi.date().iso().allow(null).optional(),
  notes: Joi.string().max(255).allow(null, '').optional(),
});

const updateBatchSchema = Joi.object({
  quantity: Joi.number().positive().optional(),
  expiry_date: Joi.date().iso().allow(null).optional(),
  notes: Joi.string().max(255).allow(null, '').optional(),
}).min(1);

export const validateCreateBatch = validate(createBatchSchema, 'body');
export const validateUpdateBatch = validate(updateBatchSchema, 'body');
```

> **Note:** check the path for the existing `validate` wrapper — it may be `./validate.js` or inlined per-validator. Mirror whatever pattern the other validators use (look at `warehouseProductValidator.js`).

- [ ] **Step 2: Auth middleware**

```js
// src/api/middlewares/batchAuthMiddleware.js
import { WarehouseProductBatch, WarehouseProduct, WarehouseUser, Warehouse } from '../../database/models/index.js';

export async function authorizeBatchAction(req, res, next) {
  try {
    const userId = req.user.id;

    // For PUT/DELETE the batch id is in the route param
    let warehouseId;
    if (req.params.batchId) {
      const batch = await WarehouseProductBatch.findByPk(req.params.batchId);
      if (!batch) return res.status(404).json({ error: 'Lote no encontrado' });
      const wp = await WarehouseProduct.findByPk(batch.warehouse_product_id);
      if (!wp) return res.status(404).json({ error: 'Producto en almacén no encontrado' });
      warehouseId = wp.warehouse_id;
    } else {
      // For GET/POST the warehouseProductId is in the route param
      const wp = await WarehouseProduct.findByPk(req.params.warehouseProductId);
      if (!wp) return res.status(404).json({ error: 'Producto en almacén no encontrado' });
      warehouseId = wp.warehouse_id;
    }

    const warehouse = await Warehouse.findByPk(warehouseId);
    if (!warehouse) return res.status(404).json({ error: 'Almacén no encontrado' });

    if (warehouse.owner_id === userId) return next();

    const membership = await WarehouseUser.findOne({
      where: { warehouse_id: warehouseId, user_id: userId },
    });
    if (membership && ['editor', 'admin'].includes(membership.role)) return next();

    return res.status(403).json({ error: 'No tienes permiso para esta acción' });
  } catch (err) {
    return res.status(500).json({ error: 'Error al verificar permisos' });
  }
}
```

- [ ] **Step 3: Commit**
```bash
git add src/api/validators/batchValidator.js src/api/middlewares/batchAuthMiddleware.js
git commit -m "feat: add batch validator and auth middleware"
```

---

## Task 6: Batch controller + routes

**Files:**
- Create: `src/api/controllers/batchController.js`
- Create: `src/api/routes/batchRoutes.js`
- Modify: `src/index.js`

- [ ] **Step 1: Controller**

```js
// src/api/controllers/batchController.js
import * as batchService from '../../services/batchService.js';

export async function getBatches(req, res) {
  try {
    const batches = await batchService.getBatchesByWarehouseProduct(req.params.warehouseProductId);
    res.json(batches);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

export async function createBatch(req, res) {
  try {
    const batch = await batchService.createBatch(req.params.warehouseProductId, req.body);
    res.status(201).json(batch);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

export async function updateBatch(req, res) {
  try {
    const batch = await batchService.updateBatch(req.params.batchId, req.body);
    res.json(batch);
  } catch (err) {
    if (err.message === 'Lote no encontrado') return res.status(404).json({ error: err.message });
    res.status(500).json({ error: err.message });
  }
}

export async function deleteBatch(req, res) {
  try {
    await batchService.deleteBatch(req.params.batchId);
    res.status(204).send();
  } catch (err) {
    if (err.message === 'Lote no encontrado') return res.status(404).json({ error: err.message });
    res.status(500).json({ error: err.message });
  }
}
```

- [ ] **Step 2: Routes**

```js
// src/api/routes/batchRoutes.js
import { Router } from 'express';
import { authenticate } from '../middlewares/authMiddleware.js';
import { authorizeBatchAction } from '../middlewares/batchAuthMiddleware.js';
import { validateIdParam } from '../validators/warehouseProductValidator.js';
import { validateCreateBatch, validateUpdateBatch } from '../validators/batchValidator.js';
import * as batchController from '../controllers/batchController.js';

const router = Router();

// GET /warehouse-products/:warehouseProductId/batches
router.get(
  '/warehouse-products/:warehouseProductId/batches',
  authenticate,
  authorizeBatchAction,
  batchController.getBatches
);

// POST /warehouse-products/:warehouseProductId/batches
router.post(
  '/warehouse-products/:warehouseProductId/batches',
  authenticate,
  authorizeBatchAction,
  validateCreateBatch,
  batchController.createBatch
);

// PUT /warehouse-product-batches/:batchId
router.put(
  '/warehouse-product-batches/:batchId',
  authenticate,
  authorizeBatchAction,
  validateUpdateBatch,
  batchController.updateBatch
);

// DELETE /warehouse-product-batches/:batchId
router.delete(
  '/warehouse-product-batches/:batchId',
  authenticate,
  authorizeBatchAction,
  batchController.deleteBatch
);

export default router;
```

- [ ] **Step 3: Mount routes in `src/index.js`**

Find the block where routes are mounted (e.g. `app.use('/api/v1/warehouse-products', warehouseProductRoutes)`) and add after it:
```js
import batchRoutes from './api/routes/batchRoutes.js';
// ...
app.use('/api/v1', batchRoutes);
```

- [ ] **Step 4: Commit**
```bash
git add src/api/controllers/batchController.js src/api/routes/batchRoutes.js src/index.js
git commit -m "feat: add batch controller, routes and mount in index"
```

---

## Task 7: Integration tests — batch CRUD

**Files:**
- Create: `tests/batch.test.js`

- [ ] **Step 1: Write failing tests**

```js
// tests/batch.test.js
import request from 'supertest';
import app from '../src/app.js'; // or wherever the express app is exported
import {
  createTestUser,
  createTestWarehouse,
  createTestProduct,
  createTestBatch,
  generateToken,
} from './testUtils.js';
import { WarehouseProduct, WarehouseProductBatch } from '../src/database/models/index.js';

let user, warehouse, wp, token;

beforeEach(async () => {
  user = await createTestUser();
  warehouse = await createTestWarehouse(user.id);
  const product = await createTestProduct(user.id);
  wp = await WarehouseProduct.create({
    warehouse_id: warehouse.id,
    product_id: product.id,
    quantity: 0,
  });
  token = generateToken(user.id, user.email, user.role);
});

describe('GET /api/v1/warehouse-products/:id/batches', () => {
  test('returns empty array when no batches', async () => {
    const res = await request(app)
      .get(`/api/v1/warehouse-products/${wp.id}/batches`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  test('returns list of batches', async () => {
    await createTestBatch(wp.id, { quantity: 3 });
    const res = await request(app)
      .get(`/api/v1/warehouse-products/${wp.id}/batches`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].quantity).toBe('3.00');
  });
});

describe('POST /api/v1/warehouse-products/:id/batches', () => {
  test('creates batch and updates parent quantity', async () => {
    const res = await request(app)
      .post(`/api/v1/warehouse-products/${wp.id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ quantity: 5, expiry_date: '2026-12-01', notes: 'test' });
    expect(res.status).toBe(201);
    expect(res.body.quantity).toBe('5.00');

    const updated = await WarehouseProduct.findByPk(wp.id);
    expect(parseFloat(updated.quantity)).toBe(5);
  });

  test('rejects missing quantity', async () => {
    const res = await request(app)
      .post(`/api/v1/warehouse-products/${wp.id}/batches`)
      .set('Authorization', `Bearer ${token}`)
      .send({ expiry_date: '2026-12-01' });
    expect(res.status).toBe(400);
  });
});

describe('PUT /api/v1/warehouse-product-batches/:id', () => {
  test('updates batch and recalculates parent quantity', async () => {
    const batch = await createTestBatch(wp.id, { quantity: 5 });
    const res = await request(app)
      .put(`/api/v1/warehouse-product-batches/${batch.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ quantity: 10 });
    expect(res.status).toBe(200);
    expect(res.body.quantity).toBe('10.00');

    const updated = await WarehouseProduct.findByPk(wp.id);
    expect(parseFloat(updated.quantity)).toBe(10);
  });

  test('returns 404 for non-existent batch', async () => {
    const res = await request(app)
      .put('/api/v1/warehouse-product-batches/99999')
      .set('Authorization', `Bearer ${token}`)
      .send({ quantity: 5 });
    expect(res.status).toBe(404);
  });
});

describe('DELETE /api/v1/warehouse-product-batches/:id', () => {
  test('deletes batch and recalculates parent quantity', async () => {
    const b1 = await createTestBatch(wp.id, { quantity: 3 });
    const b2 = await createTestBatch(wp.id, { quantity: 7 });
    // parent quantity should be 10 now
    await request(app)
      .delete(`/api/v1/warehouse-product-batches/${b1.id}`)
      .set('Authorization', `Bearer ${token}`);

    const updated = await WarehouseProduct.findByPk(wp.id);
    expect(parseFloat(updated.quantity)).toBe(7);

    const remaining = await WarehouseProductBatch.findAll({ where: { warehouse_product_id: wp.id } });
    expect(remaining).toHaveLength(1);
  });
});
```

- [ ] **Step 2: Run to confirm they fail**
```bash
npm test -- batch.test.js
```
Expected: several failures (routes not yet wired / DB not migrated).

- [ ] **Step 3: Run init-test-db**
```bash
npm run init-test-db
```

- [ ] **Step 4: Run tests again — expect pass**
```bash
npm test -- batch.test.js
```
Expected: all tests pass.

- [ ] **Step 5: Commit**
```bash
git add tests/batch.test.js
git commit -m "test: add batch CRUD integration tests"
```

---

## Task 8: `warehouseProductService` — initial batch on creation + `has_expiring_batch`

**Files:**
- Modify: `src/services/warehouseProductService.js`

- [ ] **Step 1: Auto-create initial batch in `addProductToWarehouse`**

Find the `addProductToWarehouse` function. After successfully creating/finding the WarehouseProduct, add:
```js
import { WarehouseProductBatch, sequelize } from '../database/models/index.js';
import { Op } from 'sequelize';

// Inside addProductToWarehouse, after wp is created/found:
if (parseFloat(data.quantity ?? 0) > 0) {
  await WarehouseProductBatch.create({
    warehouse_product_id: wp.id,
    quantity: data.quantity,
  });
}
```

> **Important:** wrap the entire create + batch creation in `sequelize.transaction()` if it isn't already.

- [ ] **Step 2: Add `has_expiring_batch` virtual field in `getWarehouseProducts`**

In `getWarehouseProducts`, after fetching the list of products, compute the virtual field:
```js
import { Op } from 'sequelize';

const today = new Date();
today.setHours(0, 0, 0, 0);
const sevenDaysLater = new Date(today);
sevenDaysLater.setDate(today.getDate() + 7);

// Add to the include array or post-process:
// Option A — post-process (simpler, no extra join needed):
const wpIds = products.map(p => p.id);
const expiringWpIds = new Set(
  (await WarehouseProductBatch.findAll({
    attributes: ['warehouse_product_id'],
    where: {
      warehouse_product_id: wpIds,
      expiry_date: { [Op.between]: [today, sevenDaysLater] },
    },
  })).map(b => b.warehouse_product_id)
);

return products.map(p => ({
  ...p.toJSON(),
  has_expiring_batch: expiringWpIds.has(p.id),
}));
```

- [ ] **Step 3: Run existing warehouse-product tests to verify no regression**
```bash
npm test -- warehouseProduct.test.js
```
Expected: all pass.

- [ ] **Step 4: Commit**
```bash
git add src/services/warehouseProductService.js
git commit -m "feat: auto-create initial batch and add has_expiring_batch virtual field"
```

---

## Task 9: Expiry cron job

**Files:**
- Create: `src/jobs/expiryCheckJob.js`
- Modify: `src/index.js`

- [ ] **Step 1: Install node-cron**
```bash
npm install node-cron
```

- [ ] **Step 2: Create job file**

```js
// src/jobs/expiryCheckJob.js
import cron from 'node-cron';
import { Op } from 'sequelize';
import {
  WarehouseProductBatch,
  WarehouseProduct,
  WarehouseUser,
  Warehouse,
  Notification,
  Product,
} from '../database/models/index.js';

export async function checkExpiryBatches() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const sevenDaysLater = new Date(today);
  sevenDaysLater.setDate(today.getDate() + 7);

  const expiringBatches = await WarehouseProductBatch.findAll({
    where: {
      expiry_date: { [Op.between]: [today, sevenDaysLater] },
    },
    include: [
      {
        model: WarehouseProduct,
        as: 'warehouseProduct',
        include: [
          { model: Warehouse, as: 'warehouse' },
          { model: Product, as: 'product' },
        ],
      },
    ],
  });

  for (const batch of expiringBatches) {
    const wp = batch.warehouseProduct;
    const warehouseId = wp.warehouse_id;
    const productId = wp.product_id;

    // Get all editors/admins of this warehouse
    const members = await WarehouseUser.findAll({
      where: {
        warehouse_id: warehouseId,
        role: { [Op.in]: ['editor', 'admin'] },
      },
    });
    // Also include the owner
    const ownerIds = [wp.warehouse.owner_id];
    const memberIds = members.map(m => m.user_id);
    const recipientIds = [...new Set([...ownerIds, ...memberIds])];

    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    for (const userId of recipientIds) {
      // Deduplication: skip if already notified in last 24h
      const existing = await Notification.findOne({
        where: {
          user_id: userId,
          batch_id: batch.id,
          type: 'expiry_warning',
          created_at: { [Op.gte]: oneDayAgo },
        },
      });
      if (existing) continue;

      const daysLeft = Math.ceil((new Date(batch.expiry_date) - today) / (1000 * 60 * 60 * 24));
      await Notification.create({
        user_id: userId,
        product_id: productId,
        warehouse_id: warehouseId,
        batch_id: batch.id,
        type: 'expiry_warning',
        message: `El lote de "${wp.product.name}" vence en ${daysLeft} día(s) (${batch.expiry_date}).`,
        is_read: false,
      });
    }
  }
}

export function startExpiryCheckJob() {
  // Every day at 08:00
  cron.schedule('0 8 * * *', async () => {
    console.log('[ExpiryCheck] Running daily expiry batch check...');
    try {
      await checkExpiryBatches();
      console.log('[ExpiryCheck] Done.');
    } catch (err) {
      console.error('[ExpiryCheck] Error:', err.message);
    }
  });
}
```

- [ ] **Step 3: Start the job in `src/index.js`**

```js
import { startExpiryCheckJob } from './jobs/expiryCheckJob.js';
// After DB connection established:
startExpiryCheckJob();
```

- [ ] **Step 4: Add `POST /notifications/check-expiry` to `notificationRoutes.js`**

```js
import { checkExpiry } from '../controllers/notificationController.js';
// ...
router.post('/check-expiry', authenticate, checkExpiry);
```

Add handler to `notificationController.js`:
```js
import { checkExpiryBatches } from '../../jobs/expiryCheckJob.js';

export async function checkExpiry(req, res) {
  try {
    await checkExpiryBatches();
    res.json({ message: 'Expiry check completed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}
```

- [ ] **Step 5: Commit**
```bash
git add src/jobs/expiryCheckJob.js src/index.js src/api/routes/notificationRoutes.js src/api/controllers/notificationController.js
git commit -m "feat: add expiry cron job and manual check endpoint"
```

---

## Task 10: Integration tests — expiry check

**Files:**
- Create: `tests/expiryCheck.test.js`

- [ ] **Step 1: Write tests**

```js
// tests/expiryCheck.test.js
import request from 'supertest';
import app from '../src/app.js';
import {
  createTestUser,
  createTestWarehouse,
  createTestProduct,
  createTestBatch,
  generateToken,
} from './testUtils.js';
import { WarehouseProduct, Notification } from '../src/database/models/index.js';

let user, warehouse, wp, token;

beforeEach(async () => {
  user = await createTestUser();
  warehouse = await createTestWarehouse(user.id);
  const product = await createTestProduct(user.id);
  wp = await WarehouseProduct.create({
    warehouse_id: warehouse.id,
    product_id: product.id,
    quantity: 0,
  });
  token = generateToken(user.id, user.email, user.role);
});

test('POST /check-expiry creates expiry_warning notification for expiring batch', async () => {
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + 3);
  await createTestBatch(wp.id, {
    quantity: 2,
    expiry_date: expiryDate.toISOString().split('T')[0],
  });

  const res = await request(app)
    .post('/api/v1/notifications/check-expiry')
    .set('Authorization', `Bearer ${token}`);
  expect(res.status).toBe(200);

  const notifications = await Notification.findAll({
    where: { warehouse_id: warehouse.id, type: 'expiry_warning' },
  });
  expect(notifications.length).toBeGreaterThanOrEqual(1);
  expect(notifications[0].batch_id).toBeTruthy();
});

test('POST /check-expiry does NOT duplicate notifications within 24h', async () => {
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + 3);
  await createTestBatch(wp.id, {
    quantity: 2,
    expiry_date: expiryDate.toISOString().split('T')[0],
  });

  await request(app)
    .post('/api/v1/notifications/check-expiry')
    .set('Authorization', `Bearer ${token}`);
  await request(app)
    .post('/api/v1/notifications/check-expiry')
    .set('Authorization', `Bearer ${token}`);

  const notifications = await Notification.findAll({
    where: { warehouse_id: warehouse.id, type: 'expiry_warning' },
  });
  // Should still be only 1 per user per batch
  const uniqueBatchUser = new Set(notifications.map(n => `${n.batch_id}-${n.user_id}`));
  expect(uniqueBatchUser.size).toBe(notifications.length);
});

test('POST /check-expiry ignores batches expiring beyond 7 days', async () => {
  const farDate = new Date();
  farDate.setDate(farDate.getDate() + 30);
  await createTestBatch(wp.id, {
    quantity: 2,
    expiry_date: farDate.toISOString().split('T')[0],
  });

  await request(app)
    .post('/api/v1/notifications/check-expiry')
    .set('Authorization', `Bearer ${token}`);

  const notifications = await Notification.findAll({
    where: { warehouse_id: warehouse.id, type: 'expiry_warning' },
  });
  expect(notifications).toHaveLength(0);
});
```

- [ ] **Step 2: Run tests**
```bash
npm test -- expiryCheck.test.js
```
Expected: all pass.

- [ ] **Step 3: Run full test suite to check for regressions**
```bash
npm test
```
Expected: all pass.

- [ ] **Step 4: Commit**
```bash
git add tests/expiryCheck.test.js
git commit -m "test: add expiry check integration tests"
```

---

## Task 11: Include `type` and `batch_id` in notification responses

**Files:**
- Modify: `src/services/notificationService.js`

- [ ] **Step 1: Verify `type` and `batch_id` are returned**

Open `notificationService.js` and find `getNotificationsByUserId`. The Sequelize model already has `type` and `batch_id`, so they will be included in `.findAll()` results automatically. Confirm the controller/service doesn't explicitly strip them via `attributes: [...]`.

If attributes are explicitly listed, add `'type'` and `'batch_id'` to the list.

- [ ] **Step 2: Run notification tests**
```bash
npm test -- notification.test.js
```
Expected: pass.

- [ ] **Step 3: Commit**
```bash
git add src/services/notificationService.js
git commit -m "feat: include type and batch_id in notification responses"
```

---

## Done

All backend tasks complete. The frontend plan (`2026-03-24-expiry-batches-frontend.md`) can now be started in parallel or sequentially.
