import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ComprasListaPantalla extends ConsumerStatefulWidget {
  const ComprasListaPantalla({super.key});

  @override
  ConsumerState<ComprasListaPantalla> createState() =>
      _ComprasListaPantallaState();
}

class _ComprasListaPantallaState extends ConsumerState<ComprasListaPantalla> {
  bool _verAnuladas = false;

  @override
  Widget build(BuildContext context) {
    final filtro = FiltroCompras(incluirAnuladas: _verAnuladas);
    final asyncCompras = ref.watch(comprasProvider(filtro));

    return PantallaBase(
      titulo: 'Compras',
      acciones: [
        IconButton(
          tooltip: 'Sugeridas',
          icon: const Icon(Icons.playlist_add_check_outlined),
          onPressed: () => context.push(Rutas.comprasSugeridas),
        ),
        IconButton(
          tooltip: 'Proveedores',
          icon: const Icon(Icons.local_shipping_outlined),
          onPressed: () => context.push(Rutas.proveedores),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: const Text('Ver anuladas'),
            selected: _verAnuladas,
            tooltip: 'Ver anuladas',
            onSelected: (v) => setState(() => _verAnuladas = v),
          ),
        ),
      ],
      botonFlotante: RequierePermiso(
        modulo: Modulo.compras,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.compraNueva),
          icon: const Icon(Icons.add),
          label: const Text('Registrar compra'),
        ),
      ),
      cuerpo: ListaAsync<CompraResumen>(
        valor: asyncCompras,
        vacio: const EstadoVacio(
          icono: Icons.shopping_cart_outlined,
          mensaje: 'No hay compras registradas',
        ),
        itemBuilder: (context, r) {
          final subtitulo =
              '${formatearFecha(r.compra.fecha)} · ${r.cantidadItems} ítem(s) · ${r.compra.medioPago.etiqueta}';

          return ListTile(
            title: Text(r.proveedorNombre ?? 'Compra sin proveedor'),
            subtitle: Text(subtitulo),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextoDinero(r.total),
                if (r.compra.anulada) ...[
                  const SizedBox(height: 4),
                  const InsigniaEstado(
                    texto: 'Anulada',
                    color: ColorEstado.peligro,
                  ),
                ],
              ],
            ),
            onTap: () => context.push(Rutas.compra(r.compra.id)),
          );
        },
      ),
    );
  }
}
