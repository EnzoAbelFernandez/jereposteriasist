# F1-04 – Categorías de gasto

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar la pantalla para administrar las categorías de gasto (crear, renombrar, archivar y restaurar categorías archivadas).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.8 Gastos**)
- `docs/catalogo-widgets.md` (`pedirTexto`, `confirmar`, `ejecutarConManejo`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/gastos/categorias_gasto_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `categoriasGastoProvider(bool incluirArchivadas)` → `AsyncValue<List<CategoriaGasto>>`
- `gastosRepositorioProvider`:
  - `Future<String> crearCategoria(String nombre)`
  - `Future<void> renombrarCategoria(String id, String nombre)`
  - `Future<void> archivarCategoria(String id)`
  - `Future<void> desarchivarCategoria(String id)`

## Comportamiento esperado

### `CategoriasGastoPantalla`
- `PantallaBase` con título `'Categorías de gasto'`.
- En `acciones`: `IconButton` o `FilterChip` `'Ver archivadas'` (`_incluirArchivadas`).
- `botonFlotante`: botón `'Nueva categoría'` que abre `pedirTexto(context, titulo: 'Nueva categoría', etiqueta: 'Nombre', textoConfirmar: 'Crear')` y, si devuelve texto, ejecuta `crearCategoria(nombre)` con `ejecutarConManejo`.
- `ListaAsync<CategoriaGasto>` con `EstadoVacio(icono: Icons.category_outlined, mensaje: 'No hay categorías')`.
- Cada fila (`ListTile`):
  - `title: Text(c.nombre)`
  - Si `c.archivada`: `subtitle: const Text('Archivada')` y botón `'Restaurar'` que llama `desarchivarCategoria(c.id)`.
  - Si no está archivada:
    - Botón editar (`Icons.edit_outlined`): abre `pedirTexto` con el nombre actual y llama `renombrarCategoria(c.id, nuevoNombre)`.
    - Botón archivar (`Icons.archive_outlined`): pide `confirmar(...)` y llama `archivarCategoria(c.id)`.

## Criterios de aceptación
- [ ] Las categorías iniciales (Alquiler, Servicios, etc.) se ven en la lista.
- [ ] Se puede crear, renombrar, archivar y restaurar sin salir de la pantalla.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/gastos/categorias_gasto_pantalla.dart"
```
