# ✅ A3 — Menú contextual a botón directo
**Origen**: #NAV-13
**Prioridad**: Alta | **Estado**: ✅ Completada | **Esfuerzo**: Bajo
## Problema
El `ProductListTile` en el detalle de almacén tiene un `PopupMenuButton` (⋮) que contiene una sola opción: "Eliminar del almacén". Un menú de 1 item es sobre-ingeniería que oculta la acción.
## Tarea
- Reemplazar el `PopupMenuButton` por un `IconButton` con `Icons.delete_outline` en color rojo directamente visible en el tile.
- Mantener el diálogo de confirmación `ConfirmDialog` con `isDangerous: true` antes de ejecutar la eliminación.
- Verificar que no haya duplicación con el icono de papelera ya existente en el `trailing` del tile en modo normal.
## Impacto
Reduce un tap innecesario (abrir menú → seleccionar) y hace la acción más descubrible. Esfuerzo bajo.
---
→ [[Tasks/high]]

**Relaciones**: [[✅ A9 - SnackBar Deshacer]]