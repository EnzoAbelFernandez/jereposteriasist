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

  Widget _construirCabecera(BuildContext context, Cliente c) {
    final tema = Theme.of(context);
    final tieneTelefono = c.telefono != null && c.telefono!.trim().isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Avatar(c.nombre, radio: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.nombre,
                              style: tema.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (c.esHabitual) ...[
                            const SizedBox(width: 8),
                            const InsigniaHabitual(),
                          ],
                        ],
                      ),
                      if (tieneTelefono) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c.telefono!,
                              style: tema.textTheme.bodyMedium?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (c.direccion != null &&
                          c.direccion!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.direccion!,
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (tieneTelefono) ...[
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
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
                    label: const Text('WhatsApp'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => llamar(c.telefono!),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Llamar'),
                  ),
                  if (c.cumpleDia != null && c.cumpleMes != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        final mensaje = c.esHabitual
                            ? '¡Hola ${c.nombre}! Se acerca tu cumpleaños y, por ser cliente habitual, queremos regalarte una atención especial en tu próximo pedido 🎂'
                            : '¡Hola ${c.nombre}! Queremos desearte un muy feliz cumpleaños de parte de todo el equipo 🎂';
                        abrirWhatsApp(c.telefono!, mensaje: mensaje);
                      },
                      icon: const Icon(Icons.cake_outlined),
                      label: const Text('Saludo de cumple'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asyncCliente = ref.watch(clienteProvider(id));
    final asyncPedidos = ref.watch(pedidosPorClienteProvider(id));

    return VistaAsync<Cliente?>(
      valor: asyncCliente,
      builder: (context, cliente) {
        final c = cliente!;
        final pedidos = asyncPedidos.value ?? const <PedidoResumen>[];

        final Dinero saldoDeudor = pedidos
            .where((p) => p.pedido.estado != EstadoPedido.cancelado)
            .fold(Dinero.cero, (acc, p) => acc + p.saldo);

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
              _construirCabecera(context, c),

              // Métricas rápidas
              Row(
                children: [
                  Expanded(
                    child: TarjetaMetrica(
                      titulo: 'Pedidos registrados',
                      valor: '${pedidos.length}',
                      icono: Icons.receipt_long_outlined,
                      color: ColorEstado.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: saldoDeudor.esPositivo
                        ? TarjetaMetrica(
                            titulo: 'Saldo pendiente',
                            valor: saldoDeudor.formatear(),
                            icono: Icons.warning_amber_rounded,
                            color: ColorEstado.peligro,
                          )
                        : const TarjetaMetrica(
                            titulo: 'Estado de pagos',
                            valor: 'Al día',
                            icono: Icons.check_circle_outline,
                            color: ColorEstado.exito,
                          ),
                  ),
                ],
              ),
              Separacion.media,

              // Datos de contacto y preferencias
              TarjetaSeccion(
                titulo: 'Datos de contacto y preferencias',
                icono: Icons.contact_page_outlined,
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
                  if (c.alergias != null && c.alergias!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: tema.colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alergias: ${c.alergias!}',
                                style: TextStyle(
                                  color: tema.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  FilaDato(
                    etiqueta: 'Notas',
                    valor: c.notas,
                    icono: Icons.notes_outlined,
                  ),
                ],
              ),

              // Fidelidad
              TarjetaSeccion(
                titulo: 'Fidelidad y condición habitual',
                icono: Icons.star_outline,
                children: [
                  FilaDato(
                    etiqueta: 'Condición actual',
                    valor: c.esHabitual
                        ? 'Cliente habitual (${c.habitualModo.etiqueta})'
                        : 'No habitual (${c.habitualModo.etiqueta})',
                    icono: Icons.loyalty_outlined,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Un cliente pasa a habitual de manera automática al acumular 3 pedidos entregados en los últimos 12 meses.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  RequierePermiso(
                    modulo: Modulo.clientes,
                    nivel: NivelPermiso.editar,
                    child: SelectorOpcion<HabitualModo>(
                      etiqueta: 'Modificar modo de condición',
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
                ],
              ),

              // Historial de pedidos
              TarjetaSeccion(
                titulo: 'Historial de pedidos (${pedidos.length})',
                icono: Icons.receipt_long_outlined,
                children: [
                  if (pedidos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Este cliente todavía no tiene pedidos cargados.',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < pedidos.length; i++) ...[
                      if (i > 0)
                        Divider(
                          color: tema.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tema.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pedidos[i].pedido.numeroTexto,
                            style: tema.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              formatearFecha(pedidos[i].pedido.fechaEntrega),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Separacion.chica,
                            InsigniaEstadoPedido(pedidos[i].pedido.estado),
                          ],
                        ),
                        subtitle:
                            pedidos[i].primerItem != null &&
                                pedidos[i].primerItem!.isNotEmpty
                            ? Text(
                                pedidos[i].cantidadItems > 1
                                    ? '${pedidos[i].primerItem!} + ${pedidos[i].cantidadItems - 1} más'
                                    : pedidos[i].primerItem!,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextoDinero(
                              pedidos[i].total,
                              estilo: tema.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!pedidos[i].pagadoCompleto &&
                                pedidos[i].pedido.estado !=
                                    EstadoPedido.cancelado)
                              Text(
                                'Resta ${pedidos[i].saldo.formatear()}',
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: tema.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (pedidos[i].pagadoCompleto)
                              Text(
                                'Pagado',
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: tema.colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        onTap: () =>
                            context.push(Rutas.pedido(pedidos[i].pedido.id)),
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
