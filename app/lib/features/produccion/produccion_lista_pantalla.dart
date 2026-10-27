import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ProduccionListaPantalla extends ConsumerStatefulWidget {
  const ProduccionListaPantalla({super.key});

  @override
  ConsumerState<ProduccionListaPantalla> createState() =>
      _ProduccionListaPantallaState();
}

class _ProduccionListaPantallaState
    extends ConsumerState<ProduccionListaPantalla> {
  bool _incluirAnuladas = false;

  @override
  Widget build(BuildContext context) {
    final base = FiltroProduccion.ultimos30Dias();
    final filtro = FiltroProduccion(
      desde: base.desde,
      hasta: base.hasta,
      incluirAnuladas: _incluirAnuladas,
    );
    final asyncProducciones = ref.watch(produccionesProvider(filtro));

    return PantallaBase(
      titulo: 'Producción',
      acciones: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FilterChip(
            label: const Text('Ver anuladas'),
            selected: _incluirAnuladas,
            onSelected: (v) => setState(() => _incluirAnuladas = v),
          ),
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.produccion,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.produccionNueva()),
          icon: const Icon(Icons.add),
          label: const Text('Registrar producción'),
        ),
      ),
      cuerpo: ListaAsync<ProduccionResumen>(
        valor: asyncProducciones,
        vacio: const EstadoVacio(
          icono: Icons.bakery_dining_outlined,
          mensaje: 'No hay producciones registradas',
        ),
        itemBuilder: (context, r) {
          final tema = Theme.of(context);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: r.produccion.anulada
                    ? resolverColorEstado(
                        context,
                        ColorEstado.peligro,
                      ).fondo.withValues(alpha: 0.5)
                    : tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () =>
                  context.push(Rutas.produccionDetalle(r.produccion.id)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: r.produccion.anulada
                              ? resolverColorEstado(
                                  context,
                                  ColorEstado.peligro,
                                ).fondo
                              : tema.colorScheme.primaryContainer,
                          foregroundColor: r.produccion.anulada
                              ? resolverColorEstado(
                                  context,
                                  ColorEstado.peligro,
                                ).frente
                              : tema.colorScheme.onPrimaryContainer,
                          child: Icon(
                            r.produccion.anulada
                                ? Icons.block_outlined
                                : Icons.bakery_dining_outlined,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.produccion.cantidad} × ${r.produccion.descripcion}',
                                style: tema.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: r.produccion.anulada
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (r.productoNombre != null &&
                                  r.productoNombre!.trim().isNotEmpty &&
                                  r.productoNombre != r.produccion.descripcion)
                                Text(
                                  'Producto: ${r.productoNombre!}',
                                  style: tema.textTheme.bodySmall?.copyWith(
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InsigniaEstado(
                          texto: r.produccion.anulada ? 'Anulada' : 'Elaborado',
                          color: r.produccion.anulada
                              ? ColorEstado.peligro
                              : ColorEstado.exito,
                          icono: r.produccion.anulada
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatearFechaHora(r.produccion.fecha),
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (r.pedidoNumero != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 14,
                                color: tema.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pedido #${r.pedidoNumero}',
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (r.creadoPorNombre != null &&
                            r.creadoPorNombre!.trim().isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.creadoPorNombre!.trim(),
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.kitchen_outlined,
                              size: 14,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${r.cantidadInsumos} insumo(s)',
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
