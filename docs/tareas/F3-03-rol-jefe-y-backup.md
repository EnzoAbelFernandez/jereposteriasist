# F3-03 – Gestión de rol Jefe/Empleado y Backup exportable en Configuración

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 1 (`F1-20`, `F1-21`)

## Objetivo
1. Permitir en `EquipoPermisosPantalla` que un Jefe pueda **cambiar el rol** de otro miembro del equipo entre `Rol.empleado` y `Rol.jefe` (para poder nombrar otro Jefe al entregar el software o delegar administración).
2. Agregar en `ConfiguracionPantalla` una tarjeta o botón de **"Exportar copia de seguridad (JSON)"** usando `configuracionRepositorioProvider.exportarBackupJson()` y `mostrarDialogoExportacion`.

## Leer antes de empezar
- `AGENTS.md`
- `app/lib/features/equipo/equipo_permisos_pantalla.dart`
- `app/lib/features/equipo/configuracion_pantalla.dart`
- `app/lib/data/repositorios/alertas_equipo_repositorio.dart` (`cambiarRol`, `exportarBackupJson`)

## Alcance de archivos
- **Modificar únicamente:**
  - `app/lib/features/equipo/equipo_permisos_pantalla.dart`
  - `app/lib/features/equipo/configuracion_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Métodos disponibles (`package:jereposteria/data/data.dart` y `compartido.dart`)
- `equipoRepositorioProvider`:
  - `Future<void> cambiarRol(String perfilId, Rol rol)`
- `perfilActualProvider` → `AsyncValue<Perfil?>` (para saber si `perfil.id == perfilActual?.id` y no permitir cambiarse el rol a uno mismo)
- `configuracionRepositorioProvider`:
  - `Future<String> exportarBackupJson()`
- `mostrarDialogoExportacion(BuildContext context, {required String titulo, required String nombreArchivo, required String contenido})`

## Comportamiento esperado

### 1. En `EquipoPermisosPantalla` (`app/lib/features/equipo/equipo_permisos_pantalla.dart`)
- Al principio de `_construirCuerpo(Perfil perfil, Map<Modulo, NivelPermiso> permisos)`:
  - Observar `final miPerfil = ref.watch(perfilActualProvider).value;`
  - Si `miPerfil?.id != perfil.id`, mostrar dentro de una `TarjetaSeccion(titulo: 'Rol en el equipo', children: [...])`:
    - Texto descriptivo actual: `perfil.esJefe ? 'Rol actual: Jefe (acceso total a todos los módulos)' : 'Rol actual: Empleado (acceso según permisos por módulo)'`.
    - `Separacion.chica`
    - Un `OutlinedButton.icon` (deshabilitado si `_procesando`):
      - Ícono: `Icons.admin_panel_settings_outlined`
      - Etiqueta: `perfil.esJefe ? 'Pasar a empleado' : 'Convertir en jefe'`
      - Al pulsarlo, pide confirmación con `confirmar(context, titulo: perfil.esJefe ? 'Pasar a empleado' : 'Convertir en jefe', mensaje: perfil.esJefe ? '¿Seguro que querés pasar a ${perfil.nombre} al rol de empleado?' : '¿Seguro que querés darle rol de jefe con acceso total a ${perfil.nombre}?', textoConfirmar: 'Confirmar', peligroso: perfil.esJefe)` y ejecuta `ref.read(equipoRepositorioProvider).cambiarRol(perfil.id, perfil.esJefe ? Rol.empleado : Rol.jefe)` con `ejecutarConManejo(..., mensajeExito: 'Rol actualizado')`.

### 2. En `ConfiguracionPantalla` (`app/lib/features/equipo/configuracion_pantalla.dart`)
- Agregar en `acciones` de `PantallaBase(titulo: 'Configuración', acciones: [...])` (o al final de `campos` dentro de `FormularioResponsivo`) un botón `'Exportar respaldo'` con ícono `Icons.backup_outlined`:
  - Al presionarlo:
    1. Llama a `final json = await ref.read(configuracionRepositorioProvider).exportarBackupJson();`
    2. Si `mounted`, abre `mostrarDialogoExportacion`:
       ```dart
       await mostrarDialogoExportacion(
         context,
         titulo: 'Copia de seguridad (JSON)',
         nombreArchivo: 'respaldo_jereposteria.json',
         contenido: json,
       );
       ```

## Criterios de aceptación
- [ ] En `EquipoPermisosPantalla` un jefe puede convertir a otro usuario en jefe o pasarlo a empleado previa confirmación.
- [ ] Un jefe no ve el botón de cambiar su propio rol cuando entra a su propio perfil.
- [ ] En `ConfiguracionPantalla` se puede exportar la copia de seguridad en JSON con `mostrarDialogoExportacion`.
- [ ] Sin errores de análisis ni de formato.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/equipo/equipo_permisos_pantalla.dart","app/lib/features/equipo/configuracion_pantalla.dart"
```
