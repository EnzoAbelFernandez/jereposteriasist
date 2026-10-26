# F2-05 – Reportes: balance mensual de ingresos, compras y gastos

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** Fase 1

## Objetivo
Implementar `ReportesPantalla` con navegación por mes (`PeriodoMensual`), resumen de ingresos por pedidos, otros ingresos, compras de insumos, gastos por categoría y resultado neto del mes.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.16 Compras sugeridas y reportes**, `resumenFinancieroMensualProvider`)
- `docs/catalogo-widgets.md` (`TarjetaMetrica`, `TarjetaSeccion`, `TextoDinero`, `FilaDato`)

## Alcance de archivos
- **Modificar únicamente:**
  - `app/lib/features/reportes/reportes_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers disponibles (`package:jereposteria/data/data.dart`)
- `resumenFinancieroMensualProvider(PeriodoMensual periodo)` → `AsyncValue<ResumenFinancieroMensual>`
  - `periodo.etiqueta` (ej. `"Octubre 2026"`), `periodo.anterior`, `periodo.siguiente`
  - `totalIngresos`, `totalEgresos`, `resultadoNeto` (`Dinero`)
  - `ingresosPedidos`, `otrosIngresos`, `egresosCompras`, `egresosGastos`, `otrosEgresos` (`Dinero`)
  - `pedidosEntregados`, `pedidosCancelados` (`int`)
  - `gastosPorCategoria` (`List<GastoPorCategoria>`: `categoriaNombre`, `monto`, `porcentajeEntero`)

## Comportamiento esperado
1. Estado local: `PeriodoMensual _periodo = PeriodoMensual.actual()`.
2. Selector de mes arriba con botón mes anterior (`Icons.chevron_left`), texto `_periodo.etiqueta` al centro y botón mes siguiente (`Icons.chevron_right`).
3. Observar `resumenFinancieroMensualProvider(_periodo)` con `VistaAsync<ResumenFinancieroMensual>`.
4. Mostrar:
   - 3 `TarjetaMetrica` principales:
     - `'Ingresos del mes'` → `r.totalIngresos.formatear()` (`ColorEstado.exito`, `Icons.trending_up`)
     - `'Egresos del mes'` → `r.totalEgresos.formatear()` (`ColorEstado.peligro`, `Icons.trending_down`)
     - `'Resultado neto'` → `r.resultadoNeto.formatear(conSigno: true)` (`r.resultadoNeto.esNegativo ? ColorEstado.peligro : ColorEstado.info`, `Icons.account_balance_wallet_outlined`)
   - `TarjetaSeccion(titulo: 'Desglose de movimientos')`:
     - Cobros de pedidos y señas (`r.ingresosPedidos.formatear()`)
     - Otros ingresos (`r.otrosIngresos.formatear()`)
     - Compras de insumos (`r.egresosCompras.formatear()`)
     - Gastos operativos (`r.egresosGastos.formatear()`)
     - Otros egresos (`r.otrosEgresos.formatear()`)
     - Pedidos entregados (`'${r.pedidosEntregados}'`) y cancelados (`'${r.pedidosCancelados}'`)
   - `TarjetaSeccion(titulo: 'Gastos por categoría')`:
     - Si `r.gastosPorCategoria.isEmpty`: texto `'No hay gastos registrados en este mes'`.
     - Para cada `GastoPorCategoria`: fila con `categoriaNombre`, `'${cat.porcentajeEntero}%'`, barra `LinearProgressIndicator(value: cat.porcentajeEntero / 100)` y `TextoDinero(cat.monto)`.

## Criterios de aceptación
- [ ] Permite cambiar de mes hacia atrás y hacia adelante actualizando todas las métricas.
- [ ] Todos los importes usan `Dinero` (prohibido usar `double` para montos o saldos).

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/reportes/reportes_pantalla.dart"
```
