# F2-02 – Producción: autocompletar insumos desde receta

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F2-01, F1-17

## Objetivo
Permitir en `ProduccionFormularioPantalla` elegir una receta (`SelectorReceta`) y autocompletar automáticamente la lista de insumos consumidos multiplicados por la cantidad producida.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (secciones **4.9 Producción** y **4.15 Recetas y costeo**)
- `docs/catalogo-widgets.md` (`SelectorReceta`)
- `app/lib/features/produccion/produccion_formulario_pantalla.dart`

## Alcance de archivos
- **Modificar únicamente:**
  - `app/lib/features/produccion/produccion_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `SelectorReceta({String? recetaId, required ValueChanged<RecetaResumen?> onChanged})`
- `recetasRepositorioProvider.observarDetalle(String id)` (podés obtener el detalle con `await ref.read(recetasRepositorioProvider).observarDetalle(recetaId).first`)
- `RecetaDetalle.escalarConsumos({int lotes = 1})` → devuelve `List<ConsumoDatos>`
- `ProduccionDatos(..., recetaId: _recetaId, ...)`

## Comportamiento esperado
1. Agregar en `ProduccionFormularioPantalla` (debajo de `SelectorProducto` o junto a `'Qué se produjo'`) un `SelectorReceta` `'Receta base (opcional)'` (`recetaId: _recetaId`).
2. Al seleccionar una receta:
   - Guardar `_recetaId = resumen?.receta.id`.
   - Si `_descripcion` está vacía, autocompletar con `resumen.receta.nombre`.
   - Si `_productoId == null` y `resumen.receta.productoId != null`, autocompletar `_productoId = resumen.receta.productoId`.
   - Mostrar un botón `FilledButton.tonalIcon` `'Cargar insumos de la receta'`:
     - Al pulsarlo, lee el `RecetaDetalle` (`await ref.read(recetasRepositorioProvider).observarDetalle(_recetaId!).first`), toma `detalle.escalarConsumos(lotes: _cantidad)` y reemplaza los renglones de insumos utilizados por los de la receta, mostrando `mostrarExito(context, 'Insumos cargados desde la receta')`.
3. Al guardar la producción en `ProduccionDatos`, pasar `recetaId: _recetaId`.

## Criterios de aceptación
- [ ] Elegir una receta y tocar `'Cargar insumos de la receta'` completa los insumos multiplicados por la cantidad producida.
- [ ] El usuario puede seguir editando o agregando insumos manualmente antes de guardar.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/produccion/produccion_formulario_pantalla.dart"
```
