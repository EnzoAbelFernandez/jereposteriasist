# F2-03 – Catálogo: costo estimado por receta y margen sugerido

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F2-01, F1-03

## Objetivo
Mostrar en el catálogo de productos y en el formulario de edición de un producto su costo estimado de materia prima (calculado desde su receta vinculada), el margen actual y un acceso rápido a `'Recetas'` desde la barra del catálogo.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.15 Recetas y costeo**, `costoProductoProvider` y `CostoProductoEstimado`)
- `docs/catalogo-widgets.md`
- `app/lib/features/catalogo/productos_lista_pantalla.dart`
- `app/lib/features/catalogo/producto_formulario_pantalla.dart`

## Alcance de archivos
- **Modificar únicamente:**
  - `app/lib/features/catalogo/productos_lista_pantalla.dart`
  - `app/lib/features/catalogo/producto_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers disponibles (`package:jereposteria/data/data.dart`)
- `costoProductoProvider(String productoId)` → `AsyncValue<CostoProductoEstimado?>`
  - `costoUnitario` (`Dinero`)
  - `margenUnitario` (`Dinero?`)
  - `margenPorcentaje` (`int?`, 0 a 100)
  - `precioSugerido({int multiplicadorCosto = 3})` (`Dinero`)
  - `tieneCostoCompleto` (`bool`)

## Comportamiento esperado

### 1. En `ProductosListaPantalla`
- Agregar en `acciones` de `PantallaBase` un botón `TextButton.icon` o `IconButton` `'Recetas'` (`Icons.menu_book_outlined`) que navegue a `context.push(Rutas.recetas)`.

### 2. En `ProductoFormularioPantalla`
- Cuando `esEdicion == true`, observar `costoProductoProvider(widget.id!)`.
- Si devuelve un `CostoProductoEstimado` no nulo, mostrar debajo del campo de precio una `TarjetaSeccion(titulo: 'Costeo según receta')` con:
  - `FilaDato(etiqueta: 'Receta vinculada', valor: costo.recetaNombre)`
  - `FilaDato(etiqueta: 'Costo estimado por unidad', valor: costo.costoUnitario.formatear())`
  - `FilaDato(etiqueta: 'Precio sugerido (×3)', valor: costo.precioSugerido().formatear())`
  - Si `costo.margenPorcentaje != null`: `FilaDato(etiqueta: 'Margen actual', valor: '${costo.margenPorcentaje}% (${costo.margenUnitario!.formatear()})')`
  - Si `!costo.tieneCostoCompleto`: aviso indicando que algún ingrediente de la receta todavía no tiene compras registradas.

## Criterios de aceptación
- [ ] Desde `ProductosListaPantalla` se puede abrir `Rutas.recetas`.
- [ ] Al editar un producto con receta vinculada se ve su costo estimado, margen y precio sugerido (todo con `Dinero`, sin `double`).

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/catalogo/productos_lista_pantalla.dart","app/lib/features/catalogo/producto_formulario_pantalla.dart"
```
