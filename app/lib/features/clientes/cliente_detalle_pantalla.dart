import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ClienteDetallePantalla extends ConsumerWidget {
  const ClienteDetallePantalla({super.key, required this.id});
  final String id;

  Future<void> _archivar(BuildContext context, WidgetRef ref, Cliente c) async {
    final ok = await confirmar(
      context,
      titulo: 'Archivar cliente',
      mensaje: '¿Seguro que querés archivar a ${c.nombre}?',
      textoConfirmar: 'Archivar',
      peligroso: true,
    );
    if (!ok || !context.mounted) return;
    await ejecutarConManejo(context, () async {
      await ref.read(clientesRepositorioProvider).archivar(c.id);
      if (context.mounted) context.pop();
    }, mensajeExito: 'Cliente archivado.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCliente = ref.watch(clienteProvider(id));
    final asyncPedidos = ref.watch(pedidosPorClienteProvider(id));

    return VistaAsync<Cliente?>(
      valor: asyncCliente,
      builder: (context, cliente) {
        final c = cliente!;
        final pedidos = asyncPedidos.value ?? const <PedidoResumen>[];
        return PantallaBase(
          titulo: c.nombre,
          acciones: [
            RequierePermiso(
              modulo: Modulo.clientes,
              nivel: NivelPermiso.editar,
              child: IconButton(
                tooltip: 'Editar cliente',
                onPressed: () => context.push(Rutas.clienteEditar(c.id)),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            RequierePermiso(
              modulo: Modulo.clientes,
              nivel: NivelPermiso.editar,
              child: IconButton(
                tooltip: 'Archivar cliente',
                onPressed: () => _archivar(context, ref, c),
                icon: const Icon(Icons.archive_outlined),
              ),
            ),
          ],
          botonFlotante: RequierePermiso(
            modulo: Modulo.pedidos,
            nivel: NivelPermiso.cargar,
            child: FloatingActionButton.extended(
              onPressed: () => context.push(Rutas.pedidoNuevo(clienteId: c.id)),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nuevo pedido'),
            ),
          ),
          cuerpo: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TarjetaSeccion(
                titulo: 'Datos de contacto',
                accion: c.esHabitual ? const InsigniaHabitual() : null,
                children: [
                  FilaDato(
                    etiqueta: 'Teléfono',
                    valor: c.telefono,
                    icono: Icons.phone_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Email',
                    valor: c.email,
                    icono: Icons.email_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Dirección',
                    valor: c.direccion,
                    icono: Icons.place_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Cumpleaños',
                    valor: c.cumpleTexto,
                    icono: Icons.cake_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Preferencias',
                    valor: c.preferencias,
                    icono: Icons.favorite_border,
                  ),
                  FilaDato(
                    etiqueta: 'Alergias',
                    valor: c.alergias,
                    icono: Icons.warning_amber_outlined,
                  ),
                  FilaDato(
                    etiqueta: 'Notas',
                    valor: c.notas,
                    icono: Icons.notes_outlined,
                  ),
                  if (c.telefono != null && c.telefono!.isNotEmpty) ...[
                    Separacion.media,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => abrirWhatsApp(
                            c.telefono!,
                            mensaje: '¡Hola ${c.nombre}!',
                          ),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Escribir por WhatsApp'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => llamar(c.telefono!),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Llamar'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              TarjetaSeccion(
                titulo: 'Fidelidad y seguimiento',
                children: [
                  FilaDato(
                    etiqueta: 'Total de pedidos',
                    valor: '${pedidos.length}',
                  ),
                  FilaDato(
                    etiqueta: 'Condición actual',
                    valor: c.esHabitual
                        ? 'Cliente habitual (${c.habitualModo.etiqueta})'
                        : 'No habitual (${c.habitualModo.etiqueta})',
                  ),
                  RequierePermiso(
                    modulo: Modulo.clientes,
                    nivel: NivelPermiso.editar,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SelectorOpcion<HabitualModo>(
                        etiqueta: 'Modo de cliente habitual',
                        opciones: HabitualModo.values,
                        valor: c.habitualModo,
                        etiquetaDe: (m) => m.etiqueta,
                        onChanged: (nuevo) {
                          if (nuevo == null) return;
                          final datos = ClienteDatos(
                            nombre: c.nombre,
                            telefono: c.telefono,
                            email: c.email,
                            direccion: c.direccion,
                            cumpleDia: c.cumpleDia,
                            cumpleMes: c.cumpleMes,
                            cumpleAnio: c.cumpleAnio,
                            preferencias: c.preferencias,
                            alergias: c.alergias,
                            notas: c.notas,
                            habitualModo: nuevo,
                          );
                          ejecutarConManejo(
                            context,
                            () => ref
                                .read(clientesRepositorioProvider)
                                .actualizar(c.id, datos),
                            mensajeExito: 'Condición actualizada.',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              TarjetaSeccion(
                titulo: 'Historial de pedidos',
                children: [
                  if (pedidos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Este cliente todavía no tiene pedidos.'),
                    )
                  else
                    for (final r in pedidos)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Pedido ${r.pedido.numeroTexto} • ${formatearFecha(r.pedido.fechaEntrega)}',
                        ),
                        subtitle: InsigniaEstadoPedido(r.pedido.estado),
                        trailing: TextoDinero(r.total),
                        onTap: () => context.push(Rutas.pedido(r.pedido.id)),
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
