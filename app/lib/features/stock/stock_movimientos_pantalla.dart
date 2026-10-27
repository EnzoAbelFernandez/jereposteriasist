import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

import 'dialogos_stock.dart';

class StockMovimientosPantalla extends ConsumerWidget {
  const StockMovimientosPantalla({super.key, required this.insumoId});

  final String insumoId;

  Future<void> _confirmarYAnular(
    BuildContext context,
    WidgetRef ref,
    MovimientoStock m,
    InsumoConStock item,
  ) async {
    final cantidadTexto = item.insumo.unidad.formatear(m.cantidad.abs());
    final seguro = await confirmar(
      context,
      titulo: '¿Anular movimiento?',
      mensaje:
          '¿Seguro que querés anular este movimiento de ${m.tipo.etiqueta.toLowerCase()} por $cantidadTexto?',
      textoConfirmar: 'Anular',
      peligroso: true,
    );
    if (!seguro || !context.mounted) return;

    await ejecutarConManejo(
      context,
      () => ref.read(stockRepositorioProvider).anularMovimiento(m.id),
      mensajeExito: 'Movimiento anulado',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asyncInsumo = ref.watch(insumoConStockProvider(insumoId));
    final asyncMovimientos = ref.watch(movimientosStockProvider(insumoId));

    return VistaAsync<InsumoConStock?>(
      valor: asyncInsumo,
      builder: (context, item) {
        final insumoConStock = item!;

        return PantallaBase(
          titulo: insumoConStock.insumo.nombre,
          acciones: [
            RequierePermiso(
              modulo: Modulo.stock,
              nivel: NivelPermiso.cargar,
              child: IconButton(
                tooltip: 'Ajustar',
                icon: const Icon(Icons.tune),
                onPressed: () =>
                    mostrarDialogoAjusteStock(context, insumoConStock),
              ),
            ),
            RequierePermiso(
              modulo: Modulo.stock,
              nivel: NivelPermiso.cargar,
              child: IconButton(
                tooltip: 'Merma',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => mostrarDialogoMerma(context, insumoConStock),
              ),
            ),
            RequierePermiso(
              modulo: Modulo.stock,
              nivel: NivelPermiso.editar,
              child: IconButton(
                tooltip: 'Editar insumo',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(Rutas.insumoEditar(insumoId)),
              ),
            ),
          ],
          cuerpo: ListaAsync<MovimientoStock>(
            valor: asyncMovimientos,
            encabezado: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TarjetaSeccion(
                titulo: 'Nivel de stock',
                icono: Icons.inventory_2_outlined,
                accion: insumoConStock.faltante
                    ? InsigniaEstado(
                        texto:
                            'Falta ${insumoConStock.insumo.unidad.formatear(insumoConStock.cantidadFaltante)}',
                        color: ColorEstado.peligro,
                        icono: Icons.warning_amber_rounded,
                      )
                    : const InsigniaEstado(
                        texto: 'Stock suficiente',
                        color: ColorEstado.exito,
                        icono: Icons.check_circle_outline,
                      ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        insumoConStock.stockTexto,
                        style: tema.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: insumoConStock.faltante
                              ? resolverColorEstado(
                                  context,
                                  ColorEstado.peligro,
                                ).frente
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'actual',
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Separacion.chica,
                  Text(
                    insumoConStock.insumo.stockMinimo > 0
                        ? 'Stock mínimo configurado: ${insumoConStock.insumo.unidad.formatear(insumoConStock.insumo.stockMinimo)}'
                        : 'Sin stock mínimo configurado',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            vacio: const EstadoVacio(
              icono: Icons.history,
              mensaje: 'Todavía no hay movimientos para este insumo',
            ),
            itemBuilder: (context, m) {
              final cantidadTexto = insumoConStock.insumo.unidad.formatear(
                m.cantidad,
                conSigno: true,
              );

              ColorEstado colorSemantico;
              IconData iconoMovimiento;
              if (m.anulado) {
                colorSemantico = ColorEstado.neutro;
                iconoMovimiento = Icons.block_outlined;
              } else if (m.esEntrada) {
                colorSemantico = ColorEstado.exito;
                iconoMovimiento = Icons.arrow_downward;
              } else if (m.tipo == TipoMovimientoStock.merma) {
                colorSemantico = ColorEstado.peligro;
                iconoMovimiento = Icons.remove_circle_outline;
              } else {
                colorSemantico = ColorEstado.advertencia;
                iconoMovimiento = Icons.arrow_upward;
              }
              final paleta = resolverColorEstado(context, colorSemantico);

              final partesSubtitulo = <String>[
                formatearFechaHora(m.fecha),
                if (m.compraId != null) 'Origen: compra',
                if (m.produccionId != null) 'Origen: producción',
                if (m.nota != null && m.nota!.trim().isNotEmpty) m.nota!.trim(),
                if (m.creadoPorNombre != null &&
                    m.creadoPorNombre!.trim().isNotEmpty)
                  m.creadoPorNombre!.trim(),
              ];
              final subtitulo = partesSubtitulo.join(' · ');

              VoidCallback? onTap;
              if (m.compraId != null) {
                onTap = () => context.push(Rutas.compra(m.compraId!));
              } else if (m.produccionId != null) {
                onTap = () =>
                    context.push(Rutas.produccionDetalle(m.produccionId!));
              }

              Widget? trailing;
              if (m.anulable) {
                trailing = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cantidadTexto,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: m.anulado
                            ? tema.colorScheme.outline
                            : paleta.frente,
                        decoration: m.anulado
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    RequierePermiso(
                      modulo: Modulo.stock,
                      nivel: NivelPermiso.editar,
                      child: IconButton(
                        icon: const Icon(Icons.undo),
                        tooltip: 'Anular movimiento',
                        onPressed: () =>
                            _confirmarYAnular(context, ref, m, insumoConStock),
                      ),
                    ),
                  ],
                );
              } else {
                trailing = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cantidadTexto,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: m.anulado
                            ? tema.colorScheme.outline
                            : paleta.frente,
                        decoration: m.anulado
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ],
                );
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: paleta.fondo,
                  foregroundColor: paleta.frente,
                  child: Icon(iconoMovimiento, size: 18),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.tipo.etiqueta,
                        style: m.anulado
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: tema.colorScheme.outline,
                              )
                            : const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (m.anulado) ...[
                      Separacion.chica,
                      const InsigniaEstado(
                        texto: 'Anulado',
                        color: ColorEstado.neutro,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(subtitulo),
                trailing: trailing,
                onTap: onTap,
              );
            },
          ),
        );
      },
    );
  }
}
