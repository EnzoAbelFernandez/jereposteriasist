# F1-13 – Pedidos: calendario de entregas

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-10

## Objetivo
Mostrar las entregas organizadas por mes y por día para planificar la semana y ver rápidamente qué días tienen entregas cargadas.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.5 Pedidos** y sección **Fechas**)
- `docs/catalogo-widgets.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/pedidos/pedidos_calendario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `pedidosProvider(FiltroPedidos(desde: ..., hasta: ..., estados: ...))` → `AsyncValue<List<PedidoResumen>>`

## Comportamiento esperado

### `PedidosCalendarioPantalla`
- `PantallaBase` con título `'Calendario de entregas'`.
- Estado local: `_mesActual` (primer día del mes) y `_diaSeleccionado` (por defecto `hoy()`).
- Consulta `pedidosProvider` para todo el mes (`desde: inicioDeMes(_mesActual)`, `hasta: finDeMes(_mesActual)`), excluyendo `EstadoPedido.cancelado`.
- Arriba:
  - Barra de navegación de mes (`< Octubre 2026 >` + botón `'Hoy'`).
  - Grilla mensual (lunes a domingo) hecha con widgets estándar de Flutter (no agregar paquetes):
    - Cada día muestra el número y, si tiene entregas ese día (`esMismoDia`), un indicador con la cantidad de pedidos.
    - Tocar un día actualiza `_diaSeleccionado`.
- Abajo (`Expanded`):
  - Encabezado con la fecha seleccionada (`formatearFecha(_diaSeleccionado)`).
  - Lista de los pedidos de ese día ordenados por hora de entrega (`formatearHora(r.pedido.fechaEntrega)`), con cliente, primer ítem, estado (`InsigniaEstadoPedido`) y `onTap` → `Rutas.pedido(r.pedido.id)`.
  - Si ese día no hay entregas: `EstadoVacio(icono: Icons.event_available, mensaje: 'No hay entregas para este día')`.

## Criterios de aceptación
- [ ] Cambiar de mes actualiza los indicadores del calendario.
- [ ] Tocar un día muestra las entregas de ese día y tocar una entrega abre su detalle.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/pedidos/pedidos_calendario_pantalla.dart"
```
