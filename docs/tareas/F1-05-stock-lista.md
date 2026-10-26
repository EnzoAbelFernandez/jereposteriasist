# F1-05 – Stock: lista con indicador de faltante y filtro

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-02

## Objetivo
Implementar la pantalla principal de Stock: lista de insumos con su cantidad actual, alerta visual cuando está bajo el stock mínimo y filtro rápido "Solo faltantes".

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.4 Insumos y stock**)
- `docs/catalogo-widgets.md` (`InsigniaEstado`, `TextoCantidad`, `RequierePermiso`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/stock/stock_lista_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `insumosConStockProvider(FiltroStock(busqueda: ..., soloFaltantes: ...))` → `AsyncValue<List<InsumoConStock>>`
- `cantidadFaltantesProvider` → `AsyncValue<int>`

## Comportamiento esperado

### `StockListaPantalla`
- `PantallaBase` con título `'Stock de insumos'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.stock, nivel: NivelPermiso.cargar, ...)`, botón `'Nuevo insumo'` → `Rutas.insumoNuevo`.
- Arriba:
  - `CampoBusqueda(hint: 'Buscar insumo...')`
  - `FilterChip` `'Solo faltantes'` (si `cantidadFaltantesProvider` tiene `> 0`, mostrar la cantidad en la etiqueta: `'Solo faltantes ($n)'`).
- `ListaAsync<InsumoConStock>`:
  - `vacio`: si `_soloFaltantes` es true → `EstadoVacio(icono: Icons.check_circle_outline, mensaje: 'No hay insumos en falta')`; si no → `EstadoVacio(icono: Icons.inventory_2_outlined, mensaje: 'Todavía no cargaste insumos')`.
- Cada fila (`ListTile`):
  - `title: Text(item.insumo.nombre)`
  - `subtitle`:
    - Si `item.insumo.stockMinimo > 0`: `'Mínimo: ${item.insumo.unidad.formatear(item.insumo.stockMinimo)}'`
    - Si tiene categoría, mostrarla también.
  - `trailing`: columna o fila con:
    - `TextoCantidad(item.stock, item.insumo.unidad)` (destacado)
    - Si `item.faltante`: `InsigniaEstado(texto: 'Falta ${item.insumo.unidad.formatear(item.cantidadFaltante)}', color: ColorEstado.peligro)`
  - `onTap`: navega a `Rutas.stockMovimientos(item.insumo.id)`.
  - Menú contextual (`PopupMenuButton` o botón editar) para ir a `Rutas.insumoEditar(item.insumo.id)` si tiene `stock:editar`.

## Criterios de aceptación
- [ ] Los insumos bajo su mínimo muestran la insignia roja con cuánto falta para llegar al mínimo.
- [ ] El filtro "Solo faltantes" muestra únicamente los insumos con `item.faltante == true`.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/stock/stock_lista_pantalla.dart"
```
