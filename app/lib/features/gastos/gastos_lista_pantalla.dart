import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class GastosListaPantalla extends ConsumerStatefulWidget {
  const GastosListaPantalla({super.key});

  @override
  ConsumerState<GastosListaPantalla> createState() =>
      _GastosListaPantallaState();
}

class _GastosListaPantallaState extends ConsumerState<GastosListaPantalla> {
  DateTime _mes = inicioDeMes(DateTime.now());
  String? _categoriaId;
  bool _incluirAnulados = false;

  void _mesAnterior() {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month - 1, 1);
    });
  }

  void _mesSiguiente() {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + 1, 1);
    });
  }

  Future<void> _anularGasto(Gasto gasto) async {
    final motivo = await pedirTexto(
      context,
      titulo: 'Anular gasto',
      etiqueta: 'Motivo de la anulación',
      textoConfirmar: 'Anular',
    );
    if (motivo == null || motivo.trim().isEmpty || !mounted) return;
    await ejecutarConManejo(
      context,
      () => ref
          .read(gastosRepositorioProvider)
          .anular(gasto.id, motivo: motivo.trim()),
      mensajeExito: 'Gasto anulado',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final filtro = FiltroGastos(
      desde: inicioDeMes(_mes),
      hasta: finDeMes(_mes),
      categoriaId: _categoriaId,
      incluirAnulados: _incluirAnulados,
    );
    final asyncGastos = ref.watch(gastosProvider(filtro));
    final asyncTotal = ref.watch(totalGastosProvider(filtro));

    return PantallaBase(
      titulo: 'Gastos',
      acciones: [
        RequierePermiso(
          modulo: Modulo.gastos,
          nivel: NivelPermiso.editar,
          child: IconButton(
            tooltip: 'Categorías',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push(Rutas.categoriasGasto),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: const Text('Ver anulados'),
            selected: _incluirAnulados,
            tooltip: 'Ver anulados',
            onSelected: (v) => setState(() => _incluirAnulados = v),
          ),
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.gastos,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.gastoNuevo),
          icon: const Icon(Icons.add),
          label: const Text('Registrar gasto'),
        ),
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Mes anterior',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _mesAnterior,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: tema.colorScheme.primary,
                          ),
                          Separacion.chica,
                          Text(
                            formatearMesAnio(_mes),
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Mes siguiente',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _mesSiguiente,
                      ),
                    ],
                  ),
                ),
                Separacion.chica,
                SelectorCategoriaGasto(
                  categoriaId: _categoriaId,
                  obligatorio: false,
                  onChanged: (cat) => setState(() => _categoriaId = cat?.id),
                ),
                Separacion.chica,
                TarjetaMetrica(
                  titulo: 'Total del período',
                  valor: asyncTotal.maybeWhen(
                    data: (total) => total.formatear(),
                    orElse: () => '...',
                  ),
                  color: ColorEstado.peligro,
                  icono: Icons.payments_outlined,
                ),
              ],
            ),
          ),
          Separacion.chica,
          Expanded(
            child: ListaAsync<GastoResumen>(
              valor: asyncGastos,
              separadores: false,
              vacio: const EstadoVacio(
                icono: Icons.receipt_outlined,
                mensaje: 'No hay gastos en este período',
              ),
              itemBuilder: (context, r) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 13,
                                    color: tema.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    r.categoriaNombre,
                                    style: tema.textTheme.labelSmall?.copyWith(
                                      color: tema.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Separacion.chica,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatearFecha(r.gasto.fecha),
                                  style: tema.textTheme.bodySmall?.copyWith(
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (r.gasto.anulado)
                              const InsigniaEstado(
                                texto: 'Anulado',
                                color: ColorEstado.peligro,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.gasto.descripcion,
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: r.gasto.anulado
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (r.gasto.notas != null &&
                            r.gasto.notas!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.gasto.notas!.trim(),
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    r.gasto.medioPago.icono,
                                    size: 15,
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    r.gasto.medioPago.etiqueta,
                                    style: tema.textTheme.bodySmall?.copyWith(
                                      color: tema.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextoDinero(
                              r.gasto.monto,
                              estilo: tema.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: r.gasto.anulado
                                    ? tema.colorScheme.outline
                                    : null,
                              ),
                            ),
                            if (!r.gasto.anulado)
                              RequierePermiso(
                                modulo: Modulo.gastos,
                                nivel: NivelPermiso.editar,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: IconButton(
                                    tooltip: 'Anular gasto',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.block_outlined,
                                      size: 18,
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => _anularGasto(r.gasto),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
