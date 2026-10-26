# F1-12 – Pedidos: detalle, cambio de estado y cobro de seña/saldo

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-11

## Objetivo
Implementar la pantalla de detalle de un pedido: datos del cliente (con WhatsApp/llamar), ítems, avance de estados (`presupuesto → confirmado → en producción → listo → entregado / cancelado`) y registro/anulación de pagos (señas y saldo).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.5 Pedidos**)
- `docs/catalogo-widgets.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/pedidos/pedido_detalle_pantalla.dart`
  - `app/lib/features/pedidos/dialogo_pago_pedido.dart` (crear)
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `pedidoDetalleProvider(String id)` → `AsyncValue<PedidoDetalle?>`
- `pedidosRepositorioProvider`:
  - `Future<void> cambiarEstado(String id, EstadoPedido nuevo, {String? motivoCancelacion})`
  - `Future<void> registrarPago(String pedidoId, PagoDatos pago, {bool esSena = false})`
  - `Future<void> anularPago(String movimientoCajaId)`

## Comportamiento esperado

### 1. `dialogo_pago_pedido.dart`
- Función `Future<void> mostrarDialogoPagoPedido(BuildContext context, PedidoDetalle detalle)`:
  - `CampoDinero` `'Monto a cobrar'` (inicializado en `detalle.saldo`, botón rápido `'Total del saldo (${detalle.saldo.formatear()})'`, `obligatorio: true`)
  - `SelectorMedioPago` (por defecto `MedioPago.efectivo`)
  - `SwitchListTile` `'Es seña'` (por defecto `true` si `detalle.pagado.esCero`, `false` si ya tenía pagos)
  - `BotonGuardar(texto: 'Registrar cobro', ...)` → llama `registrarPago(detalle.pedido.id, PagoDatos(monto: ..., medioPago: ...), esSena: ...)` → `mostrarExito(context, 'Cobro registrado')` → cierra el diálogo.

### 2. `PedidoDetallePantalla` (`required this.id`)
- Observa `pedidoDetalleProvider(id)` con `VistaAsync`.
- `PantallaBase` con título `'Pedido ${d.pedido.numeroTexto}'`.
- En `acciones`: si `!d.pedido.estado.esFinal`, botón `'Editar'` (`Rutas.pedidoEditar(id)`) envuelto en `RequierePermiso(modulo: Modulo.pedidos, nivel: NivelPermiso.editar, ...)`.
- **Sección Estado y acciones rápidas:**
  - Muestra `InsigniaEstadoPedido(d.pedido.estado)` y la fecha/hora de entrega.
  - Botones para pasar a cada estado de `d.pedido.estado.siguientes`:
    - Si el usuario solo tiene `produccion:cargar` (y no `pedidos:editar`), mostrar únicamente los botones hacia `enProduccion` y `listo`.
    - Si el estado destino es `EstadoPedido.cancelado`, pedir motivo con `pedirTexto(context, titulo: 'Cancelar pedido', etiqueta: 'Motivo de la cancelación', textoConfirmar: 'Cancelar pedido')`.
    - Llamar `cambiarEstado(...)` con `ejecutarConManejo`.
- **Sección Cliente (`TarjetaSeccion`):**
  - Nombre (con `InsigniaHabitual()` si `d.cliente.esHabitual`), teléfono, botones de WhatsApp y llamar, botón para ver ficha (`Rutas.cliente(d.cliente.id)`).
  - Tipo de entrega y dirección si es envío.
- **Sección Ítems (`TarjetaSeccion`):**
  - Cada `PedidoItem`: cantidad × descripción, notas, `precioUnitario` y `subtotal`.
  - Pie con Subtotal, Descuento (si `> 0`, con motivo) y **Total**.
- **Sección Pagos y saldo (`TarjetaSeccion`):**
  - Resumen: **Total**, **Pagado** y **Saldo pendiente** (`TextoDinero(d.saldo)`).
  - Botón `'Registrar cobro'` (si `d.saldo.esPositivo && d.pedido.estado != EstadoPedido.cancelado`), envuelto en `RequierePermiso` (`pedidos:cargar`), que abre `mostrarDialogoPagoPedido`.
  - Lista de pagos (`d.pagos`): fecha, concepto (`sena` / `pagoPedido` / `anulacion`), medio de pago, monto y, si `!pago.anulado && pago.concepto != ConceptoCaja.anulacion`, botón de anular pago (`pedidos:editar`) con `confirmar(...)` → `anularPago(pago.id)`.

## Criterios de aceptación
- [ ] Al registrar un cobro, el saldo pendiente baja de inmediato.
- [ ] Cancelar un pedido pide motivo obligatorio.
- [ ] Un empleado que solo tiene permiso de producción puede pasar el pedido a "En producción" o "Listo", pero no editarlo ni cancelarlo.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/pedidos/pedido_detalle_pantalla.dart","app/lib/features/pedidos/dialogo_pago_pedido.dart"
```
