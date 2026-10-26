# F1-22 – Centro de alertas

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar la pantalla de Alertas donde el usuario ve los avisos de cumpleaños próximos, stock bajo mínimo, entregas de mañana y tareas asignadas o vencidas, pudiendo marcarlas como leídas e ir al elemento correspondiente con un toque.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.11 Alertas**)
- `docs/catalogo-widgets.md` (`IconoAlerta`, `ChipsFiltro`)

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/alertas/alertas_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.** (El contador en la campana del menú ya está en el núcleo de la Fase 0).

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `alertasProvider` → `AsyncValue<List<Alerta>>`
- `cantidadAlertasNoLeidasProvider` → `AsyncValue<int>`
- `alertasRepositorioProvider`:
  - `Future<void> marcarLeida(String id)`
  - `Future<void> marcarTodasLeidas()`

## Comportamiento esperado

### `AlertasPantalla`
- `PantallaBase` con título `'Alertas'`.
- En `acciones`: si hay alertas sin leer, `TextButton` `'Marcar todas como leídas'` → `marcarTodasLeidas()`.
- Arriba: `FilterChip` `'Solo no leídas'` + `ChipsFiltro<TipoAlerta>` opcional por tipo.
- `ListaAsync<Alerta>` con `EstadoVacio(icono: Icons.notifications_none, mensaje: 'No tenés alertas pendientes')`.
- Cada fila (`ListTile`):
  - `leading: IconoAlerta(a.tipo)`
  - `title: Text(a.titulo)` (en negrita si `!a.leida`)
  - `subtitle`: `a.mensaje` + `formatearFechaHora(a.creadoEn)`
  - `onTap`:
    1. Si `!a.leida`, llama `marcarLeida(a.id)` (sin bloquear la navegación).
    2. Si `a.rutaDestino != null`, hace `context.push(a.rutaDestino!)`.

## Criterios de aceptación
- [ ] Tocar una alerta no leída la marca como leída y abre la ficha del cliente, insumo, pedido o tarea vinculada.
- [ ] "Marcar todas como leídas" deja el contador de no leídas en 0.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/alertas/alertas_pantalla.dart"
```
