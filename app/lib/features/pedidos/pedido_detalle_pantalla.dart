import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

import 'dialogo_pago_pedido.dart';

class PedidoDetallePantalla extends ConsumerWidget {
  const PedidoDetallePantalla({super.key, required this.id});

  final String id;

  IconData _iconoParaEstado(EstadoPedido estado) {
    switch (estado) {
      case EstadoPedido.presupuesto:
        return Icons.receipt_outlined;
      case EstadoPedido.confirmado:
        return Icons.check_circle_outline;
      case EstadoPedido.enProduccion:
        return Icons.bakery_dining_outlined;
      case EstadoPedido.listo:
        return Icons.done_all;
      case EstadoPedido.entregado:
        return Icons.handshake_outlined;
      case EstadoPedido.cancelado:
        return Icons.cancel_outlined;
    }
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    WidgetRef ref,
    String pedidoId,
    EstadoPedido nuevo,
  ) async {
    String? motivo;
    if (nuevo == EstadoPedido.cancelado) {
      motivo = await pedirTexto(
        context,
        titulo: 'Cancelar pedido',
        etiqueta: 'Motivo de la cancelación',
        textoConfirmar: 'Cancelar pedido',
      );
      if (motivo == null || motivo.trim().isEmpty || !context.mounted) {
        return;
      }
    }

    await ejecutarConManejo(
      context,
      () => ref
          .read(pedidosRepositorioProvider)
          .cambiarEstado(pedidoId, nuevo, motivoCancelacion: motivo),
      mensajeExito: nuevo == EstadoPedido.cancelado
          ? 'Pedido cancelado'
          : 'Estado actualizado a ${nuevo.etiqueta}',
    );
  }

  Future<void> _anularPago(
    BuildContext context,
    WidgetRef ref,
    MovimientoCaja pago,
  ) async {
    final ok = await confirmar(
      context,
      titulo: 'Anular pago',
      mensaje:
          '¿Seguro que querés anular el pago de ${pago.monto.formatear()} (${pago.concepto.etiqueta})?',
      textoConfirmar: 'Anular pago',
      peligroso: true,
    );
    if (!ok || !context.mounted) return;

    await ejecutarConManejo(
      context,
      () => ref.read(pedidosRepositorioProvider).anularPago(pago.id),
      mensajeExito: 'Pago anulado.',
    );
  }

  Widget _construirBarraProgreso(BuildContext context, EstadoPedido estado) {
    final tema = Theme.of(context);
    if (estado == EstadoPedido.cancelado) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tema.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: tema.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Este pedido fue cancelado',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final pasos = [
      (
        etiqueta: estado == EstadoPedido.presupuesto
            ? 'Presupuesto'
            : 'Confirmado',
        icono: estado == EstadoPedido.presupuesto
            ? Icons.receipt_outlined
            : Icons.check_circle_outline,
      ),
      (etiqueta: 'En producción', icono: Icons.bakery_dining_outlined),
      (etiqueta: 'Listo', icono: Icons.done_all),
      (etiqueta: 'Entregado', icono: Icons.handshake_outlined),
    ];

    int pasoActual;
    switch (estado) {
      case EstadoPedido.presupuesto:
      case EstadoPedido.confirmado:
        pasoActual = 0;
        break;
      case EstadoPedido.enProduccion:
        pasoActual = 1;
        break;
      case EstadoPedido.listo:
        pasoActual = 2;
        break;
      case EstadoPedido.entregado:
        pasoActual = 3;
        break;
      case EstadoPedido.cancelado:
        pasoActual = 0;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < pasos.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i <= pasoActual
                        ? tema.colorScheme.primary
                        : tema.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: i < pasoActual
                      ? tema.colorScheme.primaryContainer
                      : (i == pasoActual
                            ? tema.colorScheme.primary
                            : tema.colorScheme.surfaceContainerHighest),
                  foregroundColor: i < pasoActual
                      ? tema.colorScheme.onPrimaryContainer
                      : (i == pasoActual
                            ? tema.colorScheme.onPrimary
                            : tema.colorScheme.outline),
                  child: Icon(
                    i < pasoActual ? Icons.check : pasos[i].icono,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pasos[i].etiqueta,
                  style: tema.textTheme.labelSmall?.copyWith(
                    fontWeight: i == pasoActual
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: i <= pasoActual
                        ? tema.colorScheme.onSurface
                        : tema.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirResumenFinanciero(BuildContext context, PedidoDetalle d) {
    final tema = Theme.of(context);
    final adeuda =
        d.saldo.esPositivo && d.pedido.estado != EstadoPedido.cancelado;

    return TarjetaSeccion(
      titulo: 'Resumen financiero',
      icono: Icons.payments_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tema.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextoDinero(
                      d.total,
                      estilo: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tema.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pagado',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextoDinero(
                      d.pagado,
                      estilo: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: adeuda
                      ? tema.colorScheme.errorContainer
                      : (d.pedido.estado == EstadoPedido.cancelado
                            ? tema.colorScheme.surfaceContainerHighest
                            : tema.colorScheme.tertiaryContainer),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          adeuda
                              ? Icons.warning_amber_rounded
                              : (d.pedido.estado == EstadoPedido.cancelado
                                    ? Icons.cancel_outlined
                                    : Icons.check_circle_outline),
                          size: 13,
                          color: adeuda
                              ? tema.colorScheme.onErrorContainer
                              : (d.pedido.estado == EstadoPedido.cancelado
                                    ? tema.colorScheme.outline
                                    : tema.colorScheme.onTertiaryContainer),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            adeuda ? 'Adeuda' : 'Saldo',
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: adeuda
                                  ? tema.colorScheme.onErrorContainer
                                  : (d.pedido.estado == EstadoPedido.cancelado
                                        ? tema.colorScheme.outline
                                        : tema.colorScheme.onTertiaryContainer),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (adeuda)
                      TextoDinero(
                        d.saldo,
                        estilo: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tema.colorScheme.onErrorContainer,
                        ),
                      )
                    else if (d.pedido.estado == EstadoPedido.cancelado)
                      Text(
                        '-',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tema.colorScheme.outline,
                        ),
                      )
                    else
                      Text(
                        'Al día',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tema.colorScheme.onTertiaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (adeuda) ...[
          Separacion.media,
          RequierePermiso(
            modulo: Modulo.pedidos,
            nivel: NivelPermiso.cargar,
            child: FilledButton.icon(
              onPressed: () => mostrarDialogoPagoPedido(context, d),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar cobro / seña'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asyncDetalle = ref.watch(pedidoDetalleProvider(id));
    final permisos = ref.watch(permisosActualesProvider);

    final puedeEditarPedidos = permisos.puede(
      Modulo.pedidos,
      NivelPermiso.editar,
    );
    final puedeCargarProduccion = permisos.puede(
      Modulo.produccion,
      NivelPermiso.cargar,
    );

    return VistaAsync<PedidoDetalle?>(
      valor: asyncDetalle,
      builder: (context, detalle) {
        final d = detalle!;

        final List<EstadoPedido> estadosSiguientes;
        if (puedeEditarPedidos) {
          estadosSiguientes = d.pedido.estado.siguientes;
        } else if (puedeCargarProduccion) {
          estadosSiguientes = d.pedido.estado.siguientes
              .where(
                (e) =>
                    e == EstadoPedido.enProduccion || e == EstadoPedido.listo,
              )
              .toList();
        } else {
          estadosSiguientes = const [];
        }

        return PantallaBase(
          titulo: 'Pedido ${d.pedido.numeroTexto}',
          acciones: [
            if (!d.pedido.estado.esFinal)
              RequierePermiso(
                modulo: Modulo.pedidos,
                nivel: NivelPermiso.editar,
                child: IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(Rutas.pedidoEditar(id)),
                ),
              ),
          ],
          cuerpo: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sección Estado y evolución
              TarjetaSeccion(
                titulo: 'Evolución del pedido',
                icono: Icons.timeline_outlined,
                children: [
                  _construirBarraProgreso(context, d.pedido.estado),
                  Separacion.media,
                  Row(
                    children: [
                      InsigniaEstadoPedido(d.pedido.estado),
                      const Spacer(),
                      Icon(
                        Icons.event_outlined,
                        size: 18,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Entrega: ${formatearFechaHora(d.pedido.fechaEntrega)}',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (d.pedido.entregadoEn != null)
                    FilaDato(
                      etiqueta: 'Entregado el',
                      valor: formatearFechaHora(d.pedido.entregadoEn!),
                      icono: Icons.check_circle_outlined,
                    ),
                  if (d.pedido.canceladoEn != null)
                    FilaDato(
                      etiqueta: 'Cancelado el',
                      valor: formatearFechaHora(d.pedido.canceladoEn!),
                      icono: Icons.cancel_outlined,
                    ),
                  if (d.pedido.motivoCancelacion != null &&
                      d.pedido.motivoCancelacion!.trim().isNotEmpty)
                    FilaDato(
                      etiqueta: 'Motivo cancelación',
                      valor: d.pedido.motivoCancelacion,
                      icono: Icons.info_outline,
                    ),
                  if (d.pedido.notas != null &&
                      d.pedido.notas!.trim().isNotEmpty)
                    FilaDato(
                      etiqueta: 'Notas del pedido',
                      valor: d.pedido.notas,
                      icono: Icons.notes_outlined,
                    ),
                  if (estadosSiguientes.isNotEmpty) ...[
                    Separacion.media,
                    const Divider(),
                    Separacion.chica,
                    Text(
                      'Cambiar estado',
                      style: tema.textTheme.labelLarge?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Separacion.chica,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final estado in estadosSiguientes)
                          if (estado == EstadoPedido.cancelado)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tema.colorScheme.error,
                              ),
                              onPressed: () => _cambiarEstado(
                                context,
                                ref,
                                d.pedido.id,
                                estado,
                              ),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar pedido'),
                            )
                          else
                            FilledButton.tonalIcon(
                              onPressed: () => _cambiarEstado(
                                context,
                                ref,
                                d.pedido.id,
                                estado,
                              ),
                              icon: Icon(_iconoParaEstado(estado)),
                              label: Text(estado.etiqueta),
                            ),
                      ],
                    ),
                  ],
                ],
              ),

              // Resumen Financiero destacado
              _construirResumenFinanciero(context, d),

              // Sección Cliente
              TarjetaSeccion(
                titulo: 'Cliente',
                icono: Icons.person_outline,
                accion: d.cliente.esHabitual ? const InsigniaHabitual() : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Avatar(d.cliente.nombre, radio: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.cliente.nombre,
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (d.cliente.telefono != null &&
                                  d.cliente.telefono!.trim().isNotEmpty)
                                Text(
                                  d.cliente.telefono!,
                                  style: tema.textTheme.bodyMedium?.copyWith(
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Separacion.chica,
                  FilaDato(
                    etiqueta: 'Tipo de entrega',
                    valor: d.pedido.tipoEntrega.etiqueta,
                    icono: d.pedido.tipoEntrega == TipoEntrega.envio
                        ? Icons.local_shipping_outlined
                        : Icons.storefront_outlined,
                  ),
                  if (d.pedido.tipoEntrega == TipoEntrega.envio)
                    FilaDato(
                      etiqueta: 'Dirección de entrega',
                      valor: d.pedido.direccionEntrega,
                      icono: Icons.place_outlined,
                    ),
                  Separacion.chica,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (d.cliente.telefono != null &&
                          d.cliente.telefono!.trim().isNotEmpty) ...[
                        FilledButton.tonalIcon(
                          onPressed: () => abrirWhatsApp(
                            d.cliente.telefono!,
                            mensaje:
                                '¡Hola ${d.cliente.nombre}! Te escribo de Jerepostería por tu pedido ${d.pedido.numeroTexto}.',
                          ),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('WhatsApp'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => llamar(d.cliente.telefono!),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Llamar'),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.push(Rutas.cliente(d.cliente.id)),
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('Ver ficha'),
                      ),
                    ],
                  ),
                ],
              ),

              // Sección Ítems del pedido
              TarjetaSeccion(
                titulo: 'Ítems del pedido',
                icono: Icons.cake_outlined,
                children: [
                  for (var i = 0; i < d.items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        color: tema.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${d.items[i].cantidad}×',
                              style: tema.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tema.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.items[i].descripcion,
                                  style: tema.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (d.items[i].notas != null &&
                                    d.items[i].notas!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    d.items[i].notas!,
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  'Unitario: ${d.items[i].precioUnitario.formatear()}',
                                  style: tema.textTheme.bodySmall?.copyWith(
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextoDinero(
                            d.items[i].subtotal,
                            estilo: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Separacion.chica,
                  Divider(
                    thickness: 1.5,
                    color: tema.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  Separacion.chica,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextoDinero(d.subtotal),
                    ],
                  ),
                  if (d.pedido.descuento.esPositivo) ...[
                    Separacion.chica,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d.pedido.motivoDescuento != null &&
                                    d.pedido.motivoDescuento!.trim().isNotEmpty
                                ? 'Descuento (${d.pedido.motivoDescuento})'
                                : 'Descuento',
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.error,
                            ),
                          ),
                        ),
                        TextoDinero(-d.pedido.descuento, colorear: true),
                      ],
                    ),
                  ],
                  Separacion.chica,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: tema.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextoDinero(
                        d.total,
                        estilo: tema.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Historial de pagos
              TarjetaSeccion(
                titulo: 'Historial de pagos',
                icono: Icons.history_outlined,
                children: [
                  if (d.pagos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Todavía no se registraron pagos.',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (final pago in d.pagos) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              pago.anulado ||
                                  pago.concepto == ConceptoCaja.anulacion
                              ? tema.colorScheme.errorContainer
                              : tema.colorScheme.secondaryContainer,
                          child: Icon(
                            pago.anulado ||
                                    pago.concepto == ConceptoCaja.anulacion
                                ? Icons.money_off_outlined
                                : pago.medioPago.icono,
                            color:
                                pago.anulado ||
                                    pago.concepto == ConceptoCaja.anulacion
                                ? tema.colorScheme.onErrorContainer
                                : tema.colorScheme.onSecondaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(pago.concepto.etiqueta),
                            if (pago.anulado) ...[
                              Separacion.chica,
                              const InsigniaEstado(
                                texto: 'Anulado',
                                color: ColorEstado.peligro,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${formatearFechaHora(pago.fecha)} • ${pago.medioPago.etiqueta}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextoDinero(
                              pago.concepto == ConceptoCaja.anulacion
                                  ? -pago.monto
                                  : pago.monto,
                              colorear: true,
                              estilo: pago.anulado
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: tema.colorScheme.outline,
                                    )
                                  : null,
                            ),
                            if (!pago.anulado &&
                                pago.concepto != ConceptoCaja.anulacion)
                              RequierePermiso(
                                modulo: Modulo.pedidos,
                                nivel: NivelPermiso.editar,
                                child: IconButton(
                                  tooltip: 'Anular pago',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      _anularPago(context, ref, pago),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
