# F1-01 – Proveedores: lista y formulario

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar la lista de proveedores con búsqueda y el formulario de alta/edición/archivado de un proveedor.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.2 Proveedores**)
- `docs/catalogo-widgets.md`
- `docs/pantallas-y-rutas.md`
- Ejemplo a imitar: `app/lib/features/clientes/`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/proveedores/proveedores_lista_pantalla.dart`
  - `app/lib/features/proveedores/proveedor_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `proveedoresProvider(String busqueda)` → `AsyncValue<List<Proveedor>>`
- `proveedorProvider(String id)` → `AsyncValue<Proveedor?>`
- `proveedoresRepositorioProvider`:
  - `Future<String> crear(ProveedorDatos datos)`
  - `Future<void> actualizar(String id, ProveedorDatos datos)`
  - `Future<void> archivar(String id)`

## Comportamiento esperado

### 1. `ProveedoresListaPantalla`
- `PantallaBase` con título `'Proveedores'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.compras, nivel: NivelPermiso.cargar, ...)`, botón `'Nuevo proveedor'` que navega a `Rutas.proveedorNuevo`.
- Arriba: `CampoBusqueda` con `hint: 'Buscar proveedor...'`.
- Abajo: `ListaAsync<Proveedor>` con `EstadoVacio(icono: Icons.local_shipping_outlined, mensaje: 'Todavía no cargaste proveedores')`.
- Cada fila (`ListTile`):
  - `leading: Avatar(p.nombre)`
  - `title: Text(p.nombre)`
  - `subtitle`: teléfono si tiene (o email si no tiene teléfono)
  - `trailing`: si tiene teléfono, `IconButton` de WhatsApp (`abrirWhatsApp(p.telefono!)`) y de llamar (`llamar(p.telefono!)`)
  - `onTap`: si tiene `compras:editar`, navega a `Rutas.proveedorEditar(p.id)`

### 2. `ProveedorFormularioPantalla` (`this.id` opcional)
- Título: `'Nuevo proveedor'` si `id == null`, `'Editar proveedor'` si `id != null`.
- Si es edición, en `acciones` del `PantallaBase` incluir un `IconButton` de archivar (`Icons.archive_outlined`, tooltip `'Archivar'`) envuelto en `RequierePermiso(modulo: Modulo.compras, nivel: NivelPermiso.editar, ...)`:
  - Pide confirmación con `confirmar(context, titulo: 'Archivar proveedor', mensaje: '¿Querés archivar este proveedor? No se borra el historial de compras.', textoConfirmar: 'Archivar', peligroso: true)`.
  - Si confirma, llama `archivar(id!)`, muestra `mostrarExito(context, 'Proveedor archivado')` y hace `context.pop()`.
- `FormularioResponsivo` con:
  - `CampoTexto` `'Nombre'` (`obligatorio: true`)
  - `CampoTexto` `'Teléfono'` (`teclado: TextInputType.phone`)
  - `CampoTexto` `'Email'` (`teclado: TextInputType.emailAddress`)
  - `CampoTexto` `'Notas'` (`maxLineas: 3`)
- `BotonGuardar` que llama `crear` o `actualizar`, muestra `mostrarExito(context, 'Proveedor guardado')` y hace `context.pop()`.

## Criterios de aceptación
- [ ] No se puede guardar con el nombre vacío.
- [ ] Un usuario con `compras:ver` ve la lista pero no el botón "Nuevo proveedor" ni puede editar.
- [ ] Al archivar un proveedor desaparece de la lista.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/proveedores/*"
```
