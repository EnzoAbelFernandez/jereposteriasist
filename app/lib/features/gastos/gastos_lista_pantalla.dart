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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Mes anterior',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _mesAnterior,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        formatearMesAnio(_mes),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mes siguiente',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _mesSiguiente,
                    ),
                  ],
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
                  icono: Icons.payments_outlined,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListaAsync<GastoResumen>(
              valor: asyncGastos,
              vacio: const EstadoVacio(
                icono: Icons.receipt_outlined,
                mensaje: 'No hay gastos en este período',
              ),
              itemBuilder: (context, r) {
                final subtitulo =
                    '${formatearFecha(r.gasto.fecha)} · ${r.categoriaNombre} · ${r.gasto.medioPago.etiqueta}';
                return ListTile(
                  title: Text(r.gasto.descripcion),
                  subtitle: Text(subtitulo),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextoDinero(r.gasto.monto),
                      if (r.gasto.anulado) ...[
                        Separacion.chica,
                        const InsigniaEstado(
                          texto: 'Anulado',
                          color: ColorEstado.peligro,
                        ),
                      ] else
                        RequierePermiso(
                          modulo: Modulo.gastos,
                          nivel: NivelPermiso.editar,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Separacion.chica,
                              IconButton(
                                tooltip: 'Anular',
                                icon: const Icon(Icons.block_outlined),
                                onPressed: () => _anularGasto(r.gasto),
                              ),
                            ],
                          ),
                        ),
                    ],
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
