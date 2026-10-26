# F1-19 – Tareas: formulario para crear, asignar y editar

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-18

## Objetivo
Implementar el formulario para crear o editar una tarea. El jefe puede asignarla a cualquier persona del equipo; un empleado crea tareas para sí mismo.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.10 Tareas**)
- `docs/catalogo-widgets.md` (`SoloJefe`, `SelectorPerfil`, `SelectorOpcion`, `CampoFecha`, `SelectorPedido`)

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/tareas/tarea_formulario_pantalla.dart`
  - `app/lib/features/tareas/tareas_pantalla.dart` (agregar navegación a editar cuando el usuario es el jefe o el creador de la tarea)
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart` y `core/sesion/sesion.dart`)
- `perfilActualProvider` → `AsyncValue<Perfil?>`
- `permisosActualesProvider` → `PermisosUsuario` (`esJefe`)
- `tareaProvider(String id)` → `AsyncValue<TareaResumen?>`
- `tareasRepositorioProvider`:
  - `Future<String> crear(TareaDatos datos)`
  - `Future<void> actualizar(String id, TareaDatos datos)`

## Comportamiento esperado

### `TareaFormularioPantalla` (`this.id` opcional)
- Título: `'Nueva tarea'` o `'Editar tarea'`.
- Campos en `FormularioResponsivo`:
  1. `CampoTexto` `'Título'` (`obligatorio: true`, ej. "Comprar 10 kg de azúcar impalpable")
  2. `SelectorOpcion<TipoTarea>` `'Tipo'` (`opciones: TipoTarea.values`, por defecto `TipoTarea.otro`)
  3. `SelectorOpcion<PrioridadTarea>` `'Prioridad'` (`opciones: PrioridadTarea.values`, por defecto `PrioridadTarea.media`)
  4. Envuelto en `SoloJefe`: `SelectorPerfil` `'Asignar a'` (`perfilId: _asignadoA`, `obligatorio: true`). Si el usuario no es jefe, `_asignadoA` se fija automáticamente al `id` del usuario actual (`perfilActualProvider`).
  5. `CampoFecha` `'Fecha de vencimiento (opcional)'`
  6. `SelectorPedido` `'Pedido relacionado (opcional)'`
  7. `CampoTexto` `'Descripción / notas (opcional)'` (`maxLineas: 3`)
- `BotonGuardar` → `crear` o `actualizar` → `mostrarExito(context, 'Tarea guardada')` → `context.pop()`.

## Criterios de aceptación
- [ ] El selector "Asignar a" solo le aparece al jefe.
- [ ] El jefe o quien creó la tarea puede tocarla en `TareasPantalla` para editarla (`Rutas.tareaEditar(id)`).

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/tareas/tarea_formulario_pantalla.dart","app/lib/features/tareas/tareas_pantalla.dart"
```
