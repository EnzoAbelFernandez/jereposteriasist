# F1-03 – Productos (catálogo): lista y formulario

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar el catálogo de productos que vende la repostería (tortas, tartas, mesas dulces, otros): lista con búsqueda y filtro por categoría, y formulario de alta/edición/archivado.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.3 Productos**)
- `docs/catalogo-widgets.md` (`ChipsFiltro`, `CampoDinero`, `TextoDinero`)
- `docs/pantallas-y-rutas.md`
- Ejemplo a imitar: `app/lib/features/clientes/`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/catalogo/productos_lista_pantalla.dart`
  - `app/lib/features/catalogo/producto_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `productosProvider(FiltroProductos(busqueda: ..., categoria: ...))` → `AsyncValue<List<Producto>>`
- `productoProvider(String id)` → `AsyncValue<Producto?>`
- `productosRepositorioProvider`:
  - `Future<String> crear(ProductoDatos datos)`
  - `Future<void> actualizar(String id, ProductoDatos datos)`
  - `Future<void> archivar(String id)`

## Comportamiento esperado

### 1. `ProductosListaPantalla`
- `PantallaBase` con título `'Catálogo de productos'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.catalogo, nivel: NivelPermiso.cargar, ...)`, botón `'Nuevo producto'` → `Rutas.productoNuevo`.
- Arriba:
  - `CampoBusqueda(hint: 'Buscar producto...')`
  - `ChipsFiltro<CategoriaProducto>` con `opciones: CategoriaProducto.values`, `multiple: false` (tocar la categoría activa la deselecciona para ver todas).
- `ListaAsync<Producto>` con `EstadoVacio(icono: Icons.cake_outlined, mensaje: 'Todavía no hay productos en el catálogo')`.
- Cada fila (`ListTile`):
  - `title: Text(p.nombre)`
  - `subtitle`: `Text(p.categoria.etiqueta)` (y descripción resumida en 1 línea si tiene)
  - `trailing`: si `p.precioBase != null`, `TextoDinero(p.precioBase!)`
  - `onTap`: si tiene `catalogo:editar`, navega a `Rutas.productoEditar(p.id)`

### 2. `ProductoFormularioPantalla` (`this.id` opcional)
- Título: `'Nuevo producto'` o `'Editar producto'`.
- Acción de archivar en edición (con `RequierePermiso` `catalogo:editar` y `confirmar`).
- Campos en `FormularioResponsivo`:
  - `CampoTexto` `'Nombre'` (`obligatorio: true`, ej. Torta Rogel, Lemon Pie, Mesa dulce 30 personas)
  - `SelectorOpcion<CategoriaProducto>` `'Categoría'` (`opciones: CategoriaProducto.values`, `etiquetaDe: (c) => c.etiqueta`, `obligatorio: true`, por defecto `CategoriaProducto.torta`)
  - `CampoDinero` `'Precio sugerido (opcional)'` (`obligatorio: false`)
  - `CampoTexto` `'Descripción / notas'` (`maxLineas: 3`)
- `BotonGuardar` → `crear` o `actualizar` → `mostrarExito(context, 'Producto guardado')` → `context.pop()`.

## Criterios de aceptación
- [ ] El filtro por categoría y la búsqueda funcionan juntos.
- [ ] El precio usa `Dinero` y `CampoDinero` (nunca `double`).

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/catalogo/*"
```
