# F1-14 – Caja: resumen, filtros y movimientos

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 0

## Objetivo
Implementar la pantalla de Caja: tarjetas con ingresos, egresos y saldo del período, desglose por medio de pago (efectivo, transferencia, Mercado Pago) y lista de movimientos con filtros.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.7 Caja**)
- `docs/catalogo-widgets.md` (`TarjetaMetrica`, `TextoDinero`, `ChipsFiltro`)

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/caja/caja_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `resumenCajaProvider(FiltroCaja(...))` → `AsyncValue<ResumenCaja>`
- `movimientosCajaProvider(FiltroCaja(...))` → `AsyncValue<List<MovimientoCaja>>`
- `cajaRepositorioProvider.anularMovimiento(String id)`

## Comportamiento esperado

### `CajaPantalla`
- `PantallaBase` con título `'Caja'`.
- Estado del filtro: por defecto `FiltroCaja.mesActual()` (selector de mes `< Mes >` o rango de fechas, más filtro opcional por `TipoMovimientoCaja` y por `MedioPago`).
- Encabezado con `VistaAsync<ResumenCaja>`:
  - 3 `TarjetaMetrica`: **Ingresos** (`resumen.ingresos.formatear()`, `ColorEstado.exito`), **Egresos** (`resumen.egresos.formatear()`, `ColorEstado.peligro`) y **Saldo** (`resumen.saldo.formatear()`).
  - Renglón con el saldo por cada `MedioPago` (`Efectivo`, `Transferencia`, `Mercado Pago`).
- Lista (`ListaAsync<MovimientoCaja>`):
  - `vacio`: `EstadoVacio(icono: Icons.point_of_sale_outlined, mensaje: 'No hay movimientos en este período')`.
  - Cada fila:
    - Título: `m.descripcionTexto` (y si `m.anulado`, `InsigniaEstado(texto: 'Anulado', color: ColorEstado.neutro)`).
    - Subtítulo: `'${formatearFechaHora(m.fecha)} · ${m.medioPago.etiqueta} · ${m.concepto.etiqueta}'`.
    - Derecha: `TextoDinero(m.montoConSigno, colorear: true, conSigno: true)`.
    - Si tiene `pedidoId`, `compraId` o `gastoId`, tocar navega al detalle correspondiente.
    - Si `m.anulable`: botón de anular (`Icons.undo`) envuelto en `RequierePermiso(modulo: Modulo.caja, nivel: NivelPermiso.editar, ...)` → `confirmar(...)` → `anularMovimiento(m.id)`.

## Criterios de aceptación
- [ ] Ingresos se ven en verde con `+` y egresos en rojo con `-`.
- [ ] Solo los movimientos manuales (`m.anulable == true`) muestran el botón de anular desde acá.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/caja/caja_pantalla.dart"
```
