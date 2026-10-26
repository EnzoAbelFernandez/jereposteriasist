import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class CompraDetallePantalla extends ConsumerWidget {
  const CompraDetallePantalla({super.key, required this.id});

  final String id;

  Future<void> _anular(
    BuildContext context,
    WidgetRef ref,
    String compraId,
  ) async {
    final motivo = await pedirTexto(
      context,
      titulo: 'Anular compra',
      etiqueta: 'Motivo de la anulación',
      textoConfirmar: 'Anular',
    );
    if (motivo == null || !context.mounted) return;
    await ejecutarConManejo(
      context,
      () =>
          ref.read(comprasRepositorioProvider).anular(compraId, motivo: motivo),
      mensajeExito: 'Compra anulada',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetalle = ref.watch(compraDetalleProvider(id));

    return VistaAsync<CompraDetalle?>(
      valor: asyncDetalle,
      builder: (context, detalle) {
        final d = detalle!;
        return PantallaBase(
          titulo: 'Detalle de compra',
          acciones: [
            if (!d.compra.anulada)
              RequierePermiso(
                modulo: Modulo.compras,
                nivel: NivelPermiso.editar,
                child: Tooltip(
                  message: 'Anular compra',
                  child: TextButton.icon(
                    onPressed: () => _anular(context, ref, d.compra.id),
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Anular compra'),
                  ),
                ),
              ),
          ],
          cuerpo: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (d.compra.anulada)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const InsigniaEstado(
                              texto: 'Anulada',
                              color: ColorEstado.peligro,
                              icono: Icons.cancel_outlined,
                            ),
                            if (d.compra.anuladoEn != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                formatearFechaHora(d.compra.anuladoEn!),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        if (d.compra.motivoAnulacion != null &&
                            d.compra.motivoAnulacion!.isNotEmpty) ...[
                          Separacion.chica,
                          Text(
                            'Motivo: ${d.compra.motivoAnulacion!}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              TarjetaSeccion(
                titulo: 'Datos',
                children: [
                  FilaDato(
                    etiqueta: 'Fecha',
                    valor: formatearFecha(d.compra.fecha),
                    icono: Icons.calendar_today_outlined,
                  ),
                  if (d.proveedor != null)
                    FilaDato(
                      etiqueta: 'Proveedor',
                      valor: d.proveedor!.nombre,
                      icono: Icons.local_shipping_outlined,
                    ),
                  FilaDato(
                    etiqueta: 'Medio de pago',
                    valor: d.compra.medioPago.etiqueta,
                    icono: d.compra.medioPago.icono,
                  ),
                  FilaDato(
                    etiqueta: 'Cargada por',
                    valor: d.creadoPorNombre,
                    icono: Icons.person_outline,
                  ),
                  FilaDato(
                    etiqueta: 'Notas',
                    valor: d.compra.notas,
                    icono: Icons.notes_outlined,
                  ),
                ],
              ),
              TarjetaSeccion(
                titulo: 'Insumos comprados',
                children: [
                  if (d.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No hay insumos registrados en esta compra.'),
                    )
                  else
                    for (var i = 0; i < d.items.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.items[i].insumoNombre),
                        subtitle: Text(d.items[i].cantidadTexto),
                        trailing: TextoDinero(d.items[i].item.precioTotal),
                      ),
                    ],
                  const Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextoDinero(
                          d.total,
                          estilo: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
