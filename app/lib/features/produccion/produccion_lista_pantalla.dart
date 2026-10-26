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
          final subtitulo =
              '${formatearFechaHora(r.produccion.fecha)}${r.pedidoNumero != null ? ' · Pedido #${r.pedidoNumero}' : ''} · ${r.cantidadInsumos} insumo(s)';

          return ListTile(
            leading: const Icon(Icons.bakery_dining_outlined),
            title: Text(
              '${r.produccion.cantidad} × ${r.produccion.descripcion}',
            ),
            subtitle: Text(subtitulo),
            trailing: r.produccion.anulada
                ? const InsigniaEstado(
                    texto: 'Anulada',
                    color: ColorEstado.peligro,
                  )
                : const Icon(Icons.chevron_right),
            onTap: () => context.push(Rutas.produccionDetalle(r.produccion.id)),
          );
        },
      ),
    );
  }
}
