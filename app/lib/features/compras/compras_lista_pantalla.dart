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
          final tema = Theme.of(context);
          final subtitulo =
              '${formatearFecha(r.compra.fecha)} · ${r.cantidadItems} ítem(s) · ${r.compra.medioPago.etiqueta}';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: r.compra.anulada
                  ? tema.colorScheme.surfaceContainerLowest
                  : tema.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: r.compra.anulada
                    ? resolverColorEstado(
                        context,
                        ColorEstado.peligro,
                      ).fondo.withValues(alpha: 0.5)
                    : tema.colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: r.compra.anulada
                    ? resolverColorEstado(context, ColorEstado.peligro).fondo
                    : tema.colorScheme.primaryContainer,
                foregroundColor: r.compra.anulada
                    ? resolverColorEstado(context, ColorEstado.peligro).frente
                    : tema.colorScheme.onPrimaryContainer,
                child: Icon(
                  r.compra.anulada
                      ? Icons.block_outlined
                      : r.compra.medioPago.icono,
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      r.proveedorNombre ?? 'Compra sin proveedor',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: r.compra.anulada
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitulo,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextoDinero(
                    r.total,
                    estilo: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: r.compra.anulada
                          ? TextDecoration.lineThrough
                          : null,
                      color: r.compra.anulada ? tema.colorScheme.outline : null,
                    ),
                  ),
                  if (r.compra.anulada) ...[
                    const SizedBox(height: 4),
                    const InsigniaEstado(
                      texto: 'Anulada',
                      color: ColorEstado.peligro,
                      icono: Icons.cancel_outlined,
                    ),
                  ],
                ],
              ),
              onTap: () => context.push(Rutas.compra(r.compra.id)),
            ),
          );
        },
      ),
    );
  }
}
