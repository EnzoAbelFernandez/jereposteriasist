# F1-07 – Stock: historial de movimientos de un insumo

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-06

## Objetivo
Mostrar la ficha de un insumo con su stock actual, accesos rápidos a ajustar/merma/editar y el historial completo de entradas y salidas (compras, producciones, ajustes, mermas y anulaciones), permitiendo anular ajustes o mermas manuales.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.4 Insumos y stock**)
- `docs/catalogo-widgets.md`
- `app/lib/features/stock/dialogos_stock.dart` (creado en F1-06)

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/stock/stock_movimientos_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `insumoConStockProvider(String insumoId)` → `AsyncValue<InsumoConStock?>`
- `movimientosStockProvider(String insumoId)` → `AsyncValue<List<MovimientoStock>>`
- `stockRepositorioProvider.anularMovimiento(String movimientoId)`

## Comportamiento esperado

### `StockMovimientosPantalla` (`required this.insumoId`)
- Observa `insumoConStockProvider(insumoId)` con `VistaAsync`.
- `PantallaBase` con título `item.insumo.nombre`.
- En `acciones`:
  - `RequierePermiso` (`stock:cargar`): botones para `'Ajustar'` (`mostrarDialogoAjusteStock`) y `'Merma'` (`mostrarDialogoMerma`).
  - `RequierePermiso` (`stock:editar`): botón `'Editar insumo'` → `Rutas.insumoEditar(insumoId)`.
- Encabezado con `TarjetaSeccion`:
  - Stock actual grande (`item.stockTexto`), stock mínimo y, si `item.faltante`, `InsigniaEstado` en rojo.
- Lista de movimientos (`ListaAsync<MovimientoStock>` sobre `movimientosStockProvider(insumoId)`):
  - `vacio`: `EstadoVacio(icono: Icons.history, mensaje: 'Todavía no hay movimientos para este insumo')`.
  - Cada fila:
    - Ícono según `m.esEntrada` (`Icons.arrow_downward` / `Icons.arrow_upward`).
    - Título: `m.tipo.etiqueta` + cantidad con signo (`'+2,5 kg'` o `'-500 g'`). Si `m.anulado`, mostrar tachado o con `InsigniaEstado(texto: 'Anulado', color: ColorEstado.neutro)`.
    - Subtítulo: `formatearFechaHora(m.fecha)` + `m.nota` (si tiene) + `m.creadoPorNombre` (si tiene).
    - Si `m.compraId != null`, tocar la fila navega a `Rutas.compra(m.compraId!)`.
    - Si `m.produccionId != null`, tocar la fila navega a `Rutas.produccionDetalle(m.produccionId!)`.
    - Si `m.anulable`: mostrar botón de anular (`Icons.undo`) envuelto en `RequierePermiso(modulo: Modulo.stock, nivel: NivelPermiso.editar, ...)` → `confirmar(...)` → `anularMovimiento(m.id)`.

## Criterios de aceptación
- [ ] Solo los movimientos con `m.anulable == true` muestran el botón de anular (los de compras y producciones se anulan desde la compra o la producción).
- [ ] Al anular un movimiento manual aparece el contramovimiento y el stock se actualiza.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/stock/stock_movimientos_pantalla.dart"
```
