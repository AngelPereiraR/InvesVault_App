# ✅ A1 — Acceso a settings en auth

**Origen**: #NAV-5 #NAV-6 #NAV-7
**Prioridad**: Alta | **Estado**: ✅ Completada | **Esfuerzo**: Bajo

## Problema

El icono de ajustes aparece en la esquina superior derecha de Login, Register y Welcome pero su `onPressed` está vacío. Es una funcionalidad pendiente que rompe la expectativa del usuario al no responder.

## Tarea

- Implementar la acción del botón en las 3 pantallas. Debe mostrar un modal con las opciones de tema (claro/oscuro/sistema) usando el `ThemeCubit`, permitiendo al usuario configurar la apariencia incluso antes de autenticarse.
- El modal debe ser ligero: un `showModalBottomSheet` o `Dialog` con los 3 radio options y un botón "Cerrar".
- Verificar que no quede ningún otro `onPressed: () {}` pendiente en la app.

## Impacto

Completa una funcionalidad esperada. Permite al usuario ajustar el tema antes de hacer login. Esfuerzo bajo.

---

→ [[Tasks/high]]
