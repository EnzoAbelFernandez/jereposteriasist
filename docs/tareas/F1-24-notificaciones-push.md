# F1-24 – Notificaciones push (Android FCM + notificaciones locales en Windows)

- **Dificultad:** 🔴 (**solo para modelo fuerte**, no asignar a un modelo flash)
- **Depende de:** F1-22 + proyecto Firebase configurado (`google-services.json`)

## Objetivo
Conectar el registro de tokens del dispositivo en la tabla `dispositivos`, la Edge Function `enviar-push` de Supabase y la recepción de notificaciones push en Android (Firebase Cloud Messaging) y notificaciones locales en Windows cuando entra una alerta nueva.

## Alcance
Esta tarea toca configuración nativa (`android/app/google-services.json`), `supabase/functions/enviar-push/` y `app/lib/core/notificaciones/`. Por eso está reservada al modelo fuerte al final de la Fase 1.
