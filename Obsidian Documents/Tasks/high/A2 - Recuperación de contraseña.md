# A2 — Recuperación de contraseña
**Origen**: #NAV-7
**Prioridad**: Alta | **Estado**: Pendiente | **Esfuerzo**: Medio
## Problema
El `TextButton` "¿Olvidaste tu contraseña?" en Login es un placeholder sin implementar. El usuario hace tap y no obtiene respuesta.
## Tarea
- Implementar un flujo completo de recuperación:
  - Diálogo que solicita el email del usuario.
  - Llamada a un endpoint de la API para solicitar reset de contraseña (a coordinar con el backend si no existe todavía).
  - Mostrar confirmación: "Si el email existe, recibirás un enlace de recuperación".
- Si el backend no tiene endpoint de reset todavía, esta tarea incluye la coordinación para añadirlo.
- El botón ya tiene buena visibilidad y ubicación; solo falta la funcionalidad.
## Impacto
Completa una funcionalidad esencial de auth que los usuarios esperan encontrar. Esfuerzo medio (incluye coordinación con backend).
---
→ [[Tasks/high]]

**Relaciones**: [[M12 - Unificar Login y Register]] [[B6 - Biometría login]]