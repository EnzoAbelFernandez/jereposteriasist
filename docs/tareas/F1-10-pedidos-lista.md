# F1-10 – Pedidos: lista con filtro por estado y búsqueda

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-03

## Objetivo
Implementar el listado de pedidos por encargo con filtros por estado, búsqueda por cliente o número, e indicador claro de fecha de entrega y saldo pendiente.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.5 Pedidos**)
- `docs/catalogo-widgets.md` (`ChipsFiltro`, `InsigniaEstadoPedido`, `TextoDinero`, `formatearFechaHora`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/pedidos/pedidos_lista_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `pedidosProvider(FiltroPedidos(...))` → `AsyncValue<List<PedidoResumen>>`

## Comportamiento esperado

### `PedidosListaPantalla`
- `PantallaBase` con título `'Pedidos'`.
- En `acciones`: `IconButton` con `Icons.calendar_month_outlined` (tooltip `'Ver calendario'`) que navega a `Rutas.pedidosCalendario`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.pedidos, nivel: NivelPermiso.cargar, ...)`, botón `'Nuevo pedido'` → `Rutas.pedidoNuevo()`.
- Arriba:
  - `CampoBusqueda(hint: 'Buscar por cliente o número...')`
  - `ChipsFiltro<EstadoPedido>` con `opciones: EstadoPedido.values`, `multiple: true`. Por defecto seleccionados los estados activos: `{EstadoPedido.presupuesto, EstadoPedido.confirmado, EstadoPedido.enProduccion, EstadoPedido.listo}`.
- `ListaAsync<PedidoResumen>` con `EstadoVacio(icono: Icons.receipt_long_outlined, mensaje: 'No hay pedidos para el filtro seleccionado')`.
- Cada fila (`ListTile` o `Card`):
  - Línea superior: `r.pedido.numeroTexto` + `r.clienteNombre` + `InsigniaEstadoPedido(r.pedido.estado)`
  - Subtítulo:
    - Fecha y hora de entrega: `'Entrega: ${formatearFechaHora(r.pedido.fechaEntrega)} (${r.pedido.tipoEntrega.etiqueta})'`
    - Resumen de ítems: `r.primerItem` (y si `r.cantidadItems > 1`, `' + ${r.cantidadItems - 1} más'`)
  - Derecha / pie:
    - Total: `TextoDinero(r.total)`
    - Si `!r.pagadoCompleto && r.pedido.estado != EstadoPedido.cancelado`: mostrar `'Resta ${r.saldo.formatear()}'`
    - Si `r.pagadoCompleto`: `'Pagado'`
  - `onTap`: `context.push(Rutas.pedido(r.pedido.id))`

## Criterios de aceptación
- [ ] Si un pedido se creó sin conexión y todavía no tiene número, muestra `"Nº pendiente"` (`r.pedido.numeroTexto`).
- [ ] Tocar el ícono de calendario navega a `Rutas.pedidosCalendario`.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/pedidos/pedidos_lista_pantalla.dart"
```
