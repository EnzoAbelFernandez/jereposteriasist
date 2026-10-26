# F1-02 – Insumos: formulario de alta y edición

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar el formulario para crear, editar y archivar un insumo (materia prima), incluyendo su unidad de medida, stock mínimo y stock inicial opcional al crearlo.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.4 Insumos y stock**)
- `docs/catalogo-widgets.md` (en especial `SelectorOpcion` y `CampoCantidad`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/stock/insumo_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.** (La lista de stock es la tarea F1-05).

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `insumoConStockProvider(String id)` → `AsyncValue<InsumoConStock?>`
- `insumosRepositorioProvider`:
  - `Future<String> crear(InsumoDatos datos, {int stockInicial = 0})`
  - `Future<void> actualizar(String id, InsumoDatos datos)` (lanza `ErrorDeNegocio` si se intenta cambiar la unidad de un insumo que ya tiene movimientos)
  - `Future<void> archivar(String id)`

## Comportamiento esperado

### `InsumoFormularioPantalla` (`this.id` opcional)
- Título: `'Nuevo insumo'` o `'Editar insumo'`.
- Si es edición, acción en la barra para **archivar** (`Icons.archive_outlined`), envuelta en `RequierePermiso(modulo: Modulo.stock, nivel: NivelPermiso.editar, ...)`, con `confirmar(...)` → `archivar(id!)` → `mostrarExito` → `context.pop()`.
- Campos en `FormularioResponsivo`:
  1. `CampoTexto` `'Nombre'` (`obligatorio: true`, ej. Harina 0000, Dulce de leche repostero, Huevos)
  2. `SelectorOpcion<Unidad>` `'Unidad de medida'`:
     - `opciones: Unidad.values`, `etiquetaDe: (u) => u.etiqueta`, `obligatorio: true`
     - Por defecto `Unidad.gramos`.
  3. `CampoCantidad` `'Stock mínimo (para avisar faltante)'`:
     - `unidad: _unidad`, `permitirCero: true`, valor por defecto `0`
  4. **Solo al crear (`id == null`):** `CampoCantidad` `'Stock actual (opcional)'`:
     - `unidad: _unidad`, `permitirCero: true`, valor por defecto `0`
     - Si es `> 0`, se pasa como `stockInicial` a `crear(...)`.
  5. `CampoTexto` `'Categoría (opcional)'` (ej. Secos, Lácteos, Chocolates, Descartables)
  6. `CampoTexto` `'Notas'` (`maxLineas: 3`)
- `BotonGuardar`: llama `crear` o `actualizar`, muestra `mostrarExito(context, 'Insumo guardado')` y hace `context.pop()`.

## Criterios de aceptación
- [ ] Al cambiar la unidad de medida en el selector, `CampoCantidad` actualiza su sufijo (g/kg, ml/l, u.).
- [ ] En modo edición no aparece el campo "Stock actual (opcional)" (el stock de un insumo existente se ajusta desde F1-06).
- [ ] Si `actualizar` lanza `ErrorDeNegocio` (por cambiar la unidad teniendo movimientos), `BotonGuardar` lo muestra en pantalla.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/stock/insumo_formulario_pantalla.dart"
```
