# F1-21 – Equipo: matriz de permisos por módulo

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-20

## Objetivo
Permitirle al jefe configurar qué módulos puede ver, cargar o editar cada empleado (`Sin acceso` / `Ver` / `Cargar` / `Editar`). Los cambios funcionan incluso sin conexión y al sincronizarse actualizan tanto los permisos como los datos que recibe el dispositivo del empleado.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.12 Equipo** y enums `Modulo`, `NivelPermiso`)
- `docs/catalogo-widgets.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/equipo/equipo_permisos_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `perfilProvider(String perfilId)` → `AsyncValue<Perfil?>`
- `permisosDePerfilProvider(String perfilId)` → `AsyncValue<Map<Modulo, NivelPermiso>>`
- `equipoRepositorioProvider.cambiarPermiso(String perfilId, Modulo modulo, NivelPermiso nivel)`

## Comportamiento esperado

### `EquipoPermisosPantalla` (`required this.perfilId`)
- Observa `perfilProvider(perfilId)` y `permisosDePerfilProvider(perfilId)`.
- `PantallaBase` con título `'Permisos de ${perfil.nombre}'`.
- Si `perfil.esJefe`: mostrar aviso `'El jefe tiene acceso total a todos los módulos'` y los controles deshabilitados.
- Si es empleado:
  - Botones de atajo arriba (con confirmación):
    - `'Solo producción y stock'` (pone `produccion: cargar`, `stock: cargar`, `pedidos: ver`, el resto `ninguno`)
    - `'Atención de pedidos'` (pone `pedidos: cargar`, `clientes: cargar`, `catalogo: ver`, el resto `ninguno`)
    - `'Quitar todos los permisos'` (todos en `ninguno`)
  - Lista de los 9 valores de `Modulo.values`:
    - Para cada `Modulo`: mostrar su ícono (`modulo.icono`), nombre (`modulo.etiqueta`) y un `SegmentedButton<NivelPermiso>` o `SelectorOpcion<NivelPermiso>` con los 4 niveles (`ninguno`, `ver`, `cargar`, `editar`).
    - Al cambiar un nivel, llamar inmediatamente a `cambiarPermiso(perfilId, modulo, nuevoNivel)` con `ejecutarConManejo`.

## Criterios de aceptación
- [ ] Cambiar un permiso actualiza el estado en pantalla de inmediato.
- [ ] Los atajos aplican la combinación de permisos correspondiente sobre todos los módulos.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/equipo/equipo_permisos_pantalla.dart"
```
