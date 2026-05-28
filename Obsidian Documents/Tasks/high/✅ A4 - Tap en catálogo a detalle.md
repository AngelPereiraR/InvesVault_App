# ✅ A4 — Tap en catálogo a detalle

**Origen**: #NAV-14
**Prioridad**: Alta | **Estado**: ✅ Completada | **Esfuerzo**: Medio

## Problema

En `ProductListScreen` (Catálogo), el tap en una card de producto navega directamente al formulario de edición (`/products/:id/edit`). El usuario espera ver información del producto, no editarlo. Para consultar cualquier detalle hay que ir a un almacén específico, lo cual es un rodeo innecesario.

## Tarea

- Cambiar el destino del tap en las cards de `ProductListScreen`: de `/products/:id/edit` a una pantalla de detalle del producto.
- La pantalla de detalle debe mostrar: nombre, marca, barcode, unidad, categorías, imagen, y la lista de almacenes con sus cantidades.
- Incluir un botón "Editar producto" dentro de la pantalla de detalle.
- Mantener el icono de papelera en la card para eliminación rápida.

## Impacto

Corrige una expectativa rota fundamental. Los usuarios pueden consultar productos sin pasar por un almacén. Esfuerzo medio.

---

→ [[Tasks/high]]
