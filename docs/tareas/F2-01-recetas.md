# F2-01 – Recetas: lista y formulario con ingredientes

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 1 (`F1-02`, `F1-03`)

## Objetivo
Implementar el catálogo de recetas (`RecetasListaPantalla` y `RecetaFormularioPantalla`) vinculadas opcionalmente a un producto del catálogo, indicando cuánto rinde la receta y la lista de insumos con sus cantidades en unidad base, mostrando el costo estimado según la última compra de cada insumo.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.15 Recetas y costeo**)
- `docs/catalogo-widgets.md` (`SelectorProducto`, `SelectorInsumo`, `CampoCantidad`, `CampoEntero`, `BotonGuardar`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/catalogo/recetas_lista_pantalla.dart`
  - `app/lib/features/catalogo/receta_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `recetasProvider(String busqueda)` → `AsyncValue<List<RecetaResumen>>`
- `recetaDetalleProvider(String id)` → `AsyncValue<RecetaDetalle?>`
- `recetasRepositorioProvider`:
  - `Future<String> crear(RecetaDatos datos)`
  - `Future<void> actualizar(String id, RecetaDatos datos)`
  - `Future<void> archivar(String id)`

## Comportamiento esperado

### 1. `RecetasListaPantalla`
- `PantallaBase` con título `'Recetas'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.produccion, nivel: NivelPermiso.cargar, ...)`, botón `'Nueva receta'` → `context.push(Rutas.recetaNueva)`.
- Cuerpo:
  - `CampoBusqueda(hint: 'Buscar receta o producto...', onChanged: ...)`
  - `ListaAsync<RecetaResumen>` con `EstadoVacio(icono: Icons.menu_book_outlined, mensaje: 'Todavía no cargaste recetas')`.
  - Cada fila (`ListTile`):
    - Título: `r.receta.nombre`
    - Subtítulo: combina `r.productoNombre` (si tiene), `r.receta.rindeTexto` y `'${r.cantidadIngredientes} ingrediente(s)'`.
    - `trailing`: si `r.costoTotalEstimado.esPositivo`, columna o texto con `TextoDinero(r.costoTotalEstimado)` (y si `!r.tieneCostoCompleto`, texto chico `'Costo parcial'`).
    - `onTap`: si tiene `produccion:editar`, `context.push(Rutas.recetaEditar(r.receta.id))`.

### 2. `RecetaFormularioPantalla` (`this.id` opcional)
- Si `id != null`, observar `recetaDetalleProvider(id!)` con `VistaAsync` y precargar una sola vez (`RecetaDatos.desde(detalle)`).
- En modo edición, botón `'Archivar'` en `acciones` (`RequierePermiso(modulo: Modulo.produccion, nivel: NivelPermiso.editar, ...)` → `confirmar` → `archivar(id!)`).
- Campos dentro de `FormularioResponsivo`:
  1. `CampoTexto` `'Nombre de la receta'` (`obligatorio: true`, ej. "Bizcochuelo vainilla 24 cm")
  2. `SelectorProducto` `'Producto vinculado (opcional)'` (`productoId: _productoId`). Si al elegir un producto el nombre de la receta está vacío, autocompletar con `producto.nombre`.
  3. `CampoEntero` `'Rinde (unidades/lotes)'` (`minimo: 1`, inicial `1`, `obligatorio: true`)
  4. `CampoTexto` `'Descripción del rendimiento (opcional)'` (ej. "1 torta de 24 cm / 20 porciones")
  5. `TarjetaSeccion(titulo: 'Ingredientes')`:
     - Lista dinámica de ingredientes (mínimo 1).
     - Cada renglón permite elegir `SelectorInsumo` (excluyendo los ya elegidos en otros renglones) y `CampoCantidad` con la `unidad` del insumo seleccionado, más botón para quitar renglón (si hay más de 1).
     - Botón `'Agregar ingrediente'`.
  6. `CampoTexto` `'Preparación / notas (opcional)'` (`maxLineas: 3`)
- `BotonGuardar`: llama `crear` o `actualizar`, muestra `mostrarExito(context, 'Receta guardada')` y hace `context.pop()`.

## Criterios de aceptación
- [ ] No permite guardar una receta sin ingredientes ni repetir el mismo insumo dos veces.
- [ ] Las cantidades de cada ingrediente usan `CampoCantidad` con la `Unidad` del insumo elegido.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/catalogo/recetas_lista_pantalla.dart","app/lib/features/catalogo/receta_formulario_pantalla.dart"
```
