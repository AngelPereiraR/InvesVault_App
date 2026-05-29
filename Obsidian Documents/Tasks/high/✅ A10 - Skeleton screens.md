# A10 — Skeleton screens

**Origen**: #UX-11
**Prioridad**: Alta | **Estado**: ✅ Completada | **Esfuerzo**: Medio

## Problema
Todas las listas muestran un `CircularProgressIndicator` genérico durante la carga inicial. El usuario no ve estructura anticipada, lo que incrementa la percepción de lentitud (UX_ANALYSIS.md:67, UI_ANALYSIS.md:864).

## Tarea
Implementar skeleton screens con shimmer en 5 pantallas clave:

1. **Dashboard** — 4 rectángulos de tarjeta (stat cards) + 2 filas de list item
2. **WarehouseList** — 5 filas de list item skeleton con avatar circular + 2 líneas de texto
3. **WarehouseDetail** — cabecera skeleton + 6 filas de producto (imagen 40x40 + 3 líneas)
4. **ProductList** — 6 filas de tarjeta de producto (imagen 56x56 + nombre + categoría + stock)
5. **ShoppingList** — 4 filas agrupadas con cabecera de categoría + 3 items por grupo

Requisitos:
- Usar `shimmer` package o `AnimatedContainer` con gradient animado
- Cada skeleton debe reflejar la forma real del contenido (card, list tile, image circle)
- Reemplazar `CircularProgressIndicator` en la carga inicial de estas 5 pantallas
- No aplicar skeleton en errores ni en loadMore — solo carga inicial
- Skeleton animado con shimmer (~1.5s ciclo, dirección izquierda→derecha)

## Impacto
Percepción de velocidad significativamente mejorada. UX más pulida y profesional. Esfuerzo medio.

---
→ [[Tasks/high]]

**Relaciones**: [[✅ A11 - AnimatedCrossFade]]
