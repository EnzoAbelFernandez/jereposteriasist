import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ProduccionDetallePantalla extends ConsumerWidget {
  const ProduccionDetallePantalla({super.key, required this.id});
  final String id;

  Future<void> _anular(BuildContext context, WidgetRef ref) async {
    final motivo = await pedirTexto(
      context,
      titulo: 'Anular producción',
      etiqueta: 'Motivo de la anulación',
      textoConfirmar: 'Anular',
    );
    if (motivo == null || motivo.trim().isEmpty || !context.mounted) return;
    await ejecutarConManejo(context, () async {
      await ref
          .read(produccionRepositorioProvider)
          .anular(id, motivo: motivo.trim());
    }, mensajeExito: 'Producción anulada');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetalle = ref.watch(produccionDetalleProvider(id));

    return VistaAsync<ProduccionDetalle?>(
      valor: asyncDetalle,
      builder: (context, detalle) {
        final d = detalle!;

        return PantallaBase(
          titulo: 'Detalle de producción',
          acciones: [
            if (!d.produccion.anulada)
              RequierePermiso(
                modulo: Modulo.produccion,
                nivel: NivelPermiso.editar,
                child: IconButton(
                  tooltip: 'Anular',
                  icon: const Icon(Icons.block_outlined),
                  onPressed: () => _anular(context, ref),
                ),
              ),
          ],
          cuerpo: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (d.produccion.anulada) ...[
                TarjetaSeccion(
                  children: [
                    Row(
                      children: [
                        const InsigniaEstado(
                          texto: 'Anulada',
                          color: ColorEstado.peligro,
                          icono: Icons.block_outlined,
                        ),
                        Separacion.media,
                        Expanded(
                          child: Text(
                            d.produccion.motivoAnulacion != null &&
                                    d.produccion.motivoAnulacion!.isNotEmpty
                                ? 'Motivo: ${d.produccion.motivoAnulacion!}'
                                : 'Producción anulada',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (d.produccion.anuladoEn != null) ...[
                      Separacion.chica,
                      FilaDato(
                        etiqueta: 'Fecha de anulación',
                        valor: formatearFechaHora(d.produccion.anuladoEn!),
                        icono: Icons.event_busy_outlined,
                      ),
                    ],
                  ],
                ),
              ],
              TarjetaSeccion(
                titulo: 'Datos',
                accion: d.produccion.anulada
                    ? const InsigniaEstado(
                        texto: 'Anulada',
                        color: ColorEstado.peligro,
                      )
                    : null,
                children: [
                  FilaDato(
                    etiqueta: 'Fecha',
                    valor: formatearFechaHora(d.produccion.fecha),
                    icono: Icons.calendar_today_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Descripción',
                    valor: d.produccion.descripcion,
                    icono: Icons.description_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Cantidad',
                    valor: '${d.produccion.cantidad}',
                    icono: Icons.tag_outlined,
                  ),
                  if (d.producto != null)
                    FilaDato(
                      etiqueta: 'Producto',
                      valor: d.producto!.nombre,
                      icono: Icons.cake_outlined,
                    ),
                  if (d.pedido != null)
                    FilaDato(
                      etiqueta: 'Pedido vinculado',
                      valor:
                          '${d.pedido!.pedido.numeroTexto} – ${d.pedido!.clienteNombre}',
                      icono: Icons.receipt_long_outlined,
                      onTap: () =>
                          context.push(Rutas.pedido(d.pedido!.pedido.id)),
                    )
                  else if (d.produccion.pedidoId != null)
                    FilaDato(
                      etiqueta: 'Pedido vinculado',
                      valor: 'Pedido #${d.produccion.pedidoId}',
                      icono: Icons.receipt_long_outlined,
                      onTap: () =>
                          context.push(Rutas.pedido(d.produccion.pedidoId!)),
                    ),
                  FilaDato(
                    etiqueta: 'Registrado por',
                    valor: d.creadoPorNombre,
                    icono: Icons.person_outline,
                  ),
                  FilaDato(
                    etiqueta: 'Notas',
                    valor: d.produccion.notas,
                    icono: Icons.notes_outlined,
                  ),
                ],
              ),
              TarjetaSeccion(
                titulo: 'Insumos consumidos',
                children: [
                  if (d.consumos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No se registraron consumos de insumos',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < d.consumos.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.kitchen_outlined),
                        title: Text(d.consumos[i].insumoNombre),
                        trailing: Text(
                          d.consumos[i].cantidadTexto,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
