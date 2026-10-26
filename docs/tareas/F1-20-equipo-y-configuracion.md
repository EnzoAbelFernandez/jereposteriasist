# F1-20 – Equipo y configuración del negocio (jefe)

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar para el jefe:
1. La pantalla de **Equipo**: lista de usuarios, invitar a un empleado nuevo y activar/desactivar empleados.
2. La pantalla de **Configuración**: nombre del negocio, días de anticipación para el aviso de cumpleaños y criterios de cliente habitual.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (secciones **4.12 Equipo** y **4.13 Configuración**)
- `docs/catalogo-widgets.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/equipo/equipo_lista_pantalla.dart`
  - `app/lib/features/equipo/configuracion_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `perfilesProvider(bool incluirInactivos)` → `AsyncValue<List<Perfil>>`
- `equipoRepositorioProvider`:
  - `Future<void> invitarEmpleado({required String nombre, required String email, String? telefono})` (requiere internet; si no hay, lanza `SinConexion`)
  - `Future<void> desactivar(String perfilId)`
  - `Future<void> reactivar(String perfilId)`
- `configuracionProvider` → `AsyncValue<Configuracion>`
- `configuracionRepositorioProvider.actualizar(Configuracion c)`

## Comportamiento esperado

### 1. `EquipoListaPantalla`
- `PantallaBase` con título `'Equipo'`.
- En `acciones`: `FilterChip` `'Ver inactivos'` y botón `'Configuración'` (`Icons.settings_outlined`) → `Rutas.configuracion`.
- `botonFlotante`: botón `'Invitar empleado'` que abre un diálogo con `CampoTexto` `'Nombre'` (`obligatorio: true`), `CampoTexto` `'Email'` (`obligatorio: true`, `TextInputType.emailAddress`), `CampoTexto` `'Teléfono (opcional)'` y `BotonGuardar(texto: 'Enviar invitación', ...)`.
- `ListaAsync<Perfil>`:
  - Cada fila muestra `Avatar(p.nombre)`, `p.nombre`, `p.rol.etiqueta`, teléfono y estado (`Inactivo` si `!p.activo`).
  - Si `!p.esJefe`:
    - `onTap`: navega a `Rutas.equipoPermisos(p.id)` (tarea F1-21).
    - Botón para `'Permisos'` (`Rutas.equipoPermisos(p.id)`) y para `'Desactivar'` / `'Reactivar'` (con `confirmar`).

### 2. `ConfiguracionPantalla`
- `VistaAsync<Configuracion>` sobre `configuracionProvider`.
- `FormularioResponsivo` con:
  - `CampoTexto` `'Nombre de la repostería'` (`obligatorio: true`)
  - Sección **Cumpleaños**:
    - `CampoEntero` `'Avisar con cuántos días de anticipación'` (`minimo: 1`, `maximo: 60`, `obligatorio: true`)
    - `SelectorOpcion<AlcanceAvisoCumple>` `'Avisar cumpleaños de'` (`opciones: AlcanceAvisoCumple.values`)
  - Sección **Cliente habitual automático**:
    - `CampoEntero` `'Mínimo de pedidos entregados'` (`minimo: 1`, `obligatorio: true`, por defecto 3)
    - `CampoEntero` `'En los últimos (meses)'` (`minimo: 1`, `maximo: 60`, `obligatorio: true`, por defecto 12)
- `BotonGuardar` → `actualizar(...)` → `mostrarExito(context, 'Configuración guardada')`.

## Criterios de aceptación
- [ ] Si se intenta invitar un empleado sin internet, `BotonGuardar` muestra el mensaje de `SinConexion`.
- [ ] Al tocar un empleado en la lista lleva a `Rutas.equipoPermisos(p.id)`.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/equipo/equipo_lista_pantalla.dart","app/lib/features/equipo/configuracion_pantalla.dart"
```
