# F2-06 – Reportes: rankings de productos más vendidos y mejores clientes

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F2-05

## Objetivo
Agregar en el módulo de Reportes una sección/widget con los rankings del mes seleccionado: **productos más vendidos** (por ingresos y unidades) y **mejores clientes** (con insignia de habitual y acceso directo a la ficha del cliente).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.16 Compras sugeridas y reportes**, `rankingsPeriodoProvider`)
- `docs/catalogo-widgets.md` (`TarjetaSeccion`, `InsigniaHabitual`, `TextoDinero`, `Avatar`)
- `app/lib/features/reportes/reportes_pantalla.dart`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/reportes/rankings_periodo_seccion.dart`
  - `app/lib/features/reportes/reportes_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers disponibles (`package:jereposteria/data/data.dart`)
- `rankingsPeriodoProvider(PeriodoMensual periodo)` → `AsyncValue<RankingsPeriodo>`
  - `productosMasVendidos` (`List<RankingProducto>`: `nombre`, `productoId`, `unidadesVendidas`, `ingresosTotales`)
  - `mejoresClientes` (`List<RankingCliente>`: `clienteId`, `nombre`, `esHabitual`, `cantidadPedidos`, `montoTotal`)

## Comportamiento esperado
1. Crear `RankingsPeriodoSeccion({required this.periodo})` en `app/lib/features/reportes/rankings_periodo_seccion.dart`:
   - Observa `rankingsPeriodoProvider(periodo)` con `VistaAsync<RankingsPeriodo>`.
   - Muestra dos `TarjetaSeccion`:
     - `'Productos más vendidos del mes'`:
       - Si está vacía: `'Sin ventas confirmadas en este período'`.
       - Si tiene datos: filas con posición (`#1`, `#2`...), `nombre`, `'${p.unidadesVendidas} u. vendidas'` y `TextoDinero(p.ingresosTotales)`.
     - `'Mejores clientes del mes'`:
       - Si está vacía: `'Sin pedidos de clientes en este período'`.
       - Si tiene datos: `ListTile` con `Avatar(c.nombre)`, `c.nombre` + (si `c.esHabitual`, `InsigniaHabitual()`), subtítulo `'${c.cantidadPedidos} pedido(s)'`, `trailing: TextoDinero(c.montoTotal)` y `onTap: () => context.push(Rutas.cliente(c.clienteId))`.
2. Incluir `RankingsPeriodoSeccion(periodo: _periodo)` al final del `ListView` de `ReportesPantalla`.

## Criterios de aceptación
- [ ] Al cambiar el mes en `ReportesPantalla`, también se actualizan ambos rankings.
- [ ] Tocar un cliente en el ranking navega a `Rutas.cliente(c.clienteId)`.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/reportes/rankings_periodo_seccion.dart","app/lib/features/reportes/reportes_pantalla.dart"
```
