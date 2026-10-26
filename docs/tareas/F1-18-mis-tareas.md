# F1-18 – Tareas: "Mis tareas" y cambio de estado

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar la pantalla de tareas donde cada usuario ve sus tareas pendientes, puede marcarlas como "En progreso" o "Hecha", y el jefe puede alternar para ver las tareas de todo el equipo.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.10 Tareas**)
- `docs/catalogo-widgets.md` (`SoloJefe`, `SelectorPerfil`, `InsigniaEstado`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/tareas/tareas_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `misTareasProvider(bool incluirTerminadas)` → `AsyncValue<List<TareaResumen>>`
- `tareasProvider(FiltroTareas(...))` → `AsyncValue<List<TareaResumen>>` (jefe)
- `tareasRepositorioProvider.cambiarEstado(String id, EstadoTarea estado)`

## Comportamiento esperado

### `TareasPantalla`
- `PantallaBase` con título `'Tareas'`.
- `botonFlotante`: botón `'Nueva tarea'` (`Icons.add`) → `Rutas.tareaNueva`.
- Controles superiores:
  - `FilterChip` `'Ver terminadas'` (`_incluirTerminadas`).
  - Envuelto en `SoloJefe`: `SegmentedButton` o `FilterChip` `'Mis tareas' / 'Todo el equipo'` (y cuando está en `'Todo el equipo'`, `SelectorPerfil` opcional para filtrar por empleado).
- `ListaAsync<TareaResumen>` con `EstadoVacio(icono: Icons.task_alt_outlined, mensaje: 'No tenés tareas pendientes')`.
- Cada fila (`ListTile` o `Card`):
  - `leading`: `Checkbox` (marcado si `r.tarea.estado == EstadoTarea.hecha`; al tocarlo alterna entre `hecha` y `pendiente` llamando a `cambiarEstado`).
  - `title`: `Text(r.tarea.titulo)` ( más `InsigniaEstado` con la prioridad si es `PrioridadTarea.alta`, y aviso `'Vencida'` en rojo si `r.tarea.vencida(hoy())`).
  - `subtitle`:
    - Tipo (`r.tarea.tipo.etiqueta`), fecha de vencimiento si tiene (`'Vence: ${formatearFecha(r.tarea.fechaVencimiento!)}'`) y, en la vista de todo el equipo, `'Asignada a: ${r.asignadoNombre}'`.
    - Descripción si tiene.
  - `trailing`: menú rápido (`PopupMenuButton<EstadoTarea>`) para cambiar entre `pendiente`, `enProgreso`, `hecha`, `cancelada`.

## Criterios de aceptación
- [ ] Un empleado ve sus tareas y puede marcarlas hechas con un toque.
- [ ] El jefe puede cambiar entre "Mis tareas" y "Todo el equipo".
- [ ] Las tareas vencidas se destacan en rojo.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/tareas/tareas_pantalla.dart"
```
