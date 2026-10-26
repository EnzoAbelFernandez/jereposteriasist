import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class InicioPantalla extends ConsumerWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider).asData?.value;
    final nombre = perfil?.nombre.trim();
    final titulo = (nombre != null && nombre.isNotEmpty)
        ? 'Hola, $nombre'
        : 'Hola';

    return PantallaBase(
      titulo: titulo,
      cuerpo: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _MetricasRapidas(),
            Separacion.media,
            _SeccionEntregasHoyMananaProtegida(),
            _SeccionProximosCumpleanosProtegida(),
            _SeccionMisTareas(),
            _SeccionInsumosFaltaProtegida(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MÉTRICAS RÁPIDAS
// =============================================================================

class _MetricasRapidas extends ConsumerWidget {
  const _MetricasRapidas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosActualesProvider);
    final puedePedidos =
        permisos.puede(Modulo.pedidos, NivelPermiso.ver) ||
        permisos.puede(Modulo.produccion, NivelPermiso.ver);
    final puedeStock =
        permisos.puede(Modulo.stock, NivelPermiso.ver) ||
        permisos.puede(Modulo.compras, NivelPermiso.ver);
    final puedeCaja = permisos.puede(Modulo.caja, NivelPermiso.ver);

    final tarjetas = <Widget>[
      const _TarjetaMisTareas(),
      if (puedePedidos)
        RequierePermiso(
          modulo: Modulo.pedidos,
          nivel: NivelPermiso.ver,
          alternativa: RequierePermiso(
            modulo: Modulo.produccion,
            nivel: NivelPermiso.ver,
            child: const _TarjetaEntregasHoy(),
          ),
          child: const _TarjetaEntregasHoy(),
        ),
      if (puedeStock)
        RequierePermiso(
          modulo: Modulo.stock,
          nivel: NivelPermiso.ver,
          alternativa: RequierePermiso(
            modulo: Modulo.compras,
            nivel: NivelPermiso.ver,
            child: const _TarjetaInsumosFalta(),
          ),
          child: const _TarjetaInsumosFalta(),
        ),
      if (puedeCaja)
        RequierePermiso(
          modulo: Modulo.caja,
          nivel: NivelPermiso.ver,
          child: const _TarjetaSaldoMes(),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              for (var i = 0; i < tarjetas.length; i++) ...[
                if (i > 0) Separacion.chica,
                tarjetas[i],
              ],
            ],
          );
        }

        if (constraints.maxWidth < 900 && tarjetas.length > 2) {
          final mitad = (tarjetas.length / 2).ceil();
          final fila1 = tarjetas.sublist(0, mitad);
          final fila2 = tarjetas.sublist(mitad);
          return Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < fila1.length; i++) ...[
                    if (i > 0) Separacion.chica,
                    Expanded(child: fila1[i]),
                  ],
                ],
              ),
              Separacion.chica,
              Row(
                children: [
                  for (var i = 0; i < fila2.length; i++) ...[
                    if (i > 0) Separacion.chica,
                    Expanded(child: fila2[i]),
                  ],
                  if (fila2.length < fila1.length) ...[
                    Separacion.chica,
                    const Spacer(),
                  ],
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < tarjetas.length; i++) ...[
              if (i > 0) Separacion.chica,
              Expanded(child: tarjetas[i]),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaMisTareas extends ConsumerWidget {
  const _TarjetaMisTareas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCantidad = ref.watch(cantidadTareasPendientesProvider);
    final valor = asyncCantidad.maybeWhen(
      data: (cant) => '$cant',
      orElse: () => '...',
    );

    return TarjetaMetrica(
      titulo: 'Mis tareas pendientes',
      valor: valor,
      icono: Icons.checklist_outlined,
      onTap: () => context.push(Rutas.tareas),
    );
  }
}

class _TarjetaEntregasHoy extends ConsumerWidget {
  const _TarjetaEntregasHoy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inicioHoy = hoy();
    final finHoy = DateTime(
      inicioHoy.year,
      inicioHoy.month,
      inicioHoy.day,
      23,
      59,
      59,
      999,
    );

    final asyncPedidos = ref.watch(
      pedidosProvider(FiltroPedidos(desde: inicioHoy, hasta: finHoy)),
    );

    final valor = asyncPedidos.maybeWhen(
      data: (pedidos) =>
          '${pedidos.where((p) => p.pedido.estado != EstadoPedido.cancelado).length}',
      orElse: () => '...',
    );

    return TarjetaMetrica(
      titulo: 'Entregas de hoy',
      valor: valor,
      icono: Icons.local_shipping_outlined,
      onTap: () => context.push(Rutas.pedidos),
    );
  }
}

class _TarjetaInsumosFalta extends ConsumerWidget {
  const _TarjetaInsumosFalta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCantidad = ref.watch(cantidadFaltantesProvider);
    final cantidad = asyncCantidad.asData?.value ?? 0;
    final valor = asyncCantidad.maybeWhen(
      data: (c) => '$c',
      orElse: () => '...',
    );

    return TarjetaMetrica(
      titulo: 'Insumos en falta',
      valor: valor,
      icono: Icons.inventory_2_outlined,
      color: cantidad > 0 ? ColorEstado.peligro : ColorEstado.neutro,
      onTap: () => context.push(Rutas.stock),
    );
  }
}

class _TarjetaSaldoMes extends ConsumerWidget {
  const _TarjetaSaldoMes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResumen = ref.watch(resumenCajaProvider(FiltroCaja.mesActual()));
    final saldo = asyncResumen.asData?.value.saldo;
    final valor = asyncResumen.maybeWhen(
      data: (r) => r.saldo.formatear(),
      orElse: () => '...',
    );

    return TarjetaMetrica(
      titulo: 'Saldo del mes',
      valor: valor,
      icono: Icons.account_balance_wallet_outlined,
      color: (saldo != null && saldo.esNegativo)
          ? ColorEstado.peligro
          : ColorEstado.neutro,
      onTap: () => context.push(Rutas.caja),
    );
  }
}

// =============================================================================
// SECCIÓN: ENTREGAS DE HOY Y MAÑANA
// =============================================================================

class _SeccionEntregasHoyMananaProtegida extends StatelessWidget {
  const _SeccionEntregasHoyMananaProtegida();

  @override
  Widget build(BuildContext context) {
    return RequierePermiso(
      modulo: Modulo.pedidos,
      nivel: NivelPermiso.ver,
      alternativa: RequierePermiso(
        modulo: Modulo.produccion,
        nivel: NivelPermiso.ver,
        child: const _SeccionEntregasHoyManana(),
      ),
      child: const _SeccionEntregasHoyManana(),
    );
  }
}

class _SeccionEntregasHoyManana extends ConsumerWidget {
  const _SeccionEntregasHoyManana();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final inicioHoy = hoy();
    final finManana = DateTime(
      inicioHoy.year,
      inicioHoy.month,
      inicioHoy.day + 1,
      23,
      59,
      59,
      999,
    );

    final asyncPedidos = ref.watch(
      pedidosProvider(FiltroPedidos(desde: inicioHoy, hasta: finManana)),
    );

    return TarjetaSeccion(
      titulo: 'Entregas de hoy y mañana',
      accion: TextButton.icon(
        onPressed: () => context.push(Rutas.pedidosCalendario),
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: const Text('Ver calendario'),
      ),
      children: [
        asyncPedidos.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No se pudieron cargar las entregas',
              style: TextStyle(color: tema.colorScheme.error),
            ),
          ),
          data: (pedidos) {
            final filtrados = pedidos
                .where((p) => p.pedido.estado != EstadoPedido.cancelado)
                .take(5)
                .toList();

            if (filtrados.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No hay entregas programadas para hoy ni mañana'),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < filtrados.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ItemEntrega(
                    pedidoResumen: filtrados[i],
                    inicioHoy: inicioHoy,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ItemEntrega extends StatelessWidget {
  const _ItemEntrega({required this.pedidoResumen, required this.inicioHoy});

  final PedidoResumen pedidoResumen;
  final DateTime inicioHoy;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final p = pedidoResumen;
    final esHoy = esMismoDia(p.pedido.fechaEntrega, inicioHoy);
    final dia = esHoy ? 'Hoy' : 'Mañana';
    final hora = formatearHora(p.pedido.fechaEntrega);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Avatar(p.clienteNombre),
      title: Text(
        p.clienteNombre,
        style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$dia a las $hora · ${p.pedido.tipoEntrega.etiqueta}'),
      trailing: InsigniaEstadoPedido(p.pedido.estado),
      onTap: () => context.push(Rutas.pedido(p.pedido.id)),
    );
  }
}

// =============================================================================
// SECCIÓN: PRÓXIMOS CUMPLEAÑOS
// =============================================================================

class _SeccionProximosCumpleanosProtegida extends StatelessWidget {
  const _SeccionProximosCumpleanosProtegida();

  @override
  Widget build(BuildContext context) {
    return RequierePermiso(
      modulo: Modulo.clientes,
      nivel: NivelPermiso.ver,
      child: const _SeccionProximosCumpleanos(),
    );
  }
}

class _SeccionProximosCumpleanos extends ConsumerWidget {
  const _SeccionProximosCumpleanos();

  String _textoDias(ClienteConCumple c) {
    if (c.dias <= 0) return 'Hoy';
    if (c.dias == 1) return 'Mañana';
    return 'En ${c.dias} días (${formatearFechaCorta(c.fecha)})';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asyncCumpleanos = ref.watch(proximosCumpleanosProvider);

    return TarjetaSeccion(
      titulo: 'Próximos cumpleaños',
      children: [
        asyncCumpleanos.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No se pudieron cargar los cumpleaños',
              style: TextStyle(color: tema.colorScheme.error),
            ),
          ),
          data: (cumpleanos) {
            if (cumpleanos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No hay cumpleaños en los próximos días'),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < cumpleanos.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ItemCumpleanos(
                    cumple: cumpleanos[i],
                    textoDias: _textoDias(cumpleanos[i]),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ItemCumpleanos extends StatelessWidget {
  const _ItemCumpleanos({required this.cumple, required this.textoDias});

  final ClienteConCumple cumple;
  final String textoDias;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = cumple;
    final tel = c.cliente.telefono?.trim();
    final tieneTelefono = tel != null && tel.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final anchoEstrecho = constraints.maxWidth < 480;

          final infoCliente = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Avatar(c.cliente.nombre),
              Separacion.media,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.cliente.nombre,
                            style: tema.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.cliente.esHabitual) ...[
                          Separacion.chica,
                          const InsigniaHabitual(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      textoDias,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final botonWhatsApp = tieneTelefono
              ? TextButton.icon(
                  onPressed: () => abrirWhatsApp(
                    tel,
                    mensaje:
                        '¡Hola ${c.cliente.nombre}! Se acerca tu cumpleaños y queremos regalarte un descuento especial en tu próximo pedido 🎂',
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Enviar saludo / descuento'),
                )
              : null;

          if (anchoEstrecho) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                infoCliente,
                if (botonWhatsApp != null) ...[
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: botonWhatsApp),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: infoCliente),
              if (botonWhatsApp != null) ...[Separacion.chica, botonWhatsApp],
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// SECCIÓN: MIS TAREAS PENDIENTES
// =============================================================================

class _SeccionMisTareas extends ConsumerWidget {
  const _SeccionMisTareas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final asyncTareas = ref.watch(misTareasProvider(false));

    return TarjetaSeccion(
      titulo: 'Mis tareas pendientes',
      accion: TextButton(
        onPressed: () => context.push(Rutas.tareas),
        child: const Text('Ver todas'),
      ),
      children: [
        asyncTareas.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No se pudieron cargar las tareas',
              style: TextStyle(color: tema.colorScheme.error),
            ),
          ),
          data: (tareas) {
            final items = tareas.take(5).toList();
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No tenés tareas pendientes'),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ItemTarea(tareaResumen: items[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ItemTarea extends ConsumerWidget {
  const _ItemTarea({required this.tareaResumen});

  final TareaResumen tareaResumen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final t = tareaResumen.tarea;
    final esVencida = t.vencida(DateTime.now());

    final partesSubtitulo = <String>[];
    if (t.fechaVencimiento != null) {
      partesSubtitulo.add(
        esVencida
            ? 'Vencida (${formatearFechaCorta(t.fechaVencimiento!)})'
            : 'Vence ${formatearFechaRelativa(t.fechaVencimiento!)}',
      );
    }
    if (t.descripcion != null && t.descripcion!.trim().isNotEmpty) {
      partesSubtitulo.add(t.descripcion!.trim());
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: t.estado == EstadoTarea.hecha,
        onChanged: (bool? valor) async {
          final nuevoEstado = (valor == true)
              ? EstadoTarea.hecha
              : EstadoTarea.pendiente;
          await ejecutarConManejo(
            context,
            () => ref
                .read(tareasRepositorioProvider)
                .cambiarEstado(t.id, nuevoEstado),
          );
        },
      ),
      title: Text(
        t.titulo,
        style: t.estado == EstadoTarea.hecha
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: tema.colorScheme.outline,
              )
            : null,
      ),
      subtitle: partesSubtitulo.isNotEmpty
          ? Text(
              partesSubtitulo.join(' • '),
              style: esVencida
                  ? TextStyle(color: tema.colorScheme.error)
                  : null,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: (t.prioridad == PrioridadTarea.alta)
          ? InsigniaEstado(
              texto: t.prioridad.etiqueta,
              color: t.prioridad.color,
            )
          : null,
      onTap: () => context.push(Rutas.tareaEditar(t.id)),
    );
  }
}

// =============================================================================
// SECCIÓN: INSUMOS EN FALTA
// =============================================================================

class _SeccionInsumosFaltaProtegida extends StatelessWidget {
  const _SeccionInsumosFaltaProtegida();

  @override
  Widget build(BuildContext context) {
    return RequierePermiso(
      modulo: Modulo.stock,
      nivel: NivelPermiso.ver,
      alternativa: RequierePermiso(
        modulo: Modulo.compras,
        nivel: NivelPermiso.ver,
        child: const _SeccionInsumosFalta(),
      ),
      child: const _SeccionInsumosFalta(),
    );
  }
}

class _SeccionInsumosFalta extends ConsumerWidget {
  const _SeccionInsumosFalta();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInsumos = ref.watch(
      insumosConStockProvider(const FiltroStock(soloFaltantes: true)),
    );

    return asyncInsumos.maybeWhen(
      data: (items) {
        final faltantes = items.where((i) => i.faltante).take(5).toList();
        if (faltantes.isEmpty) {
          return const SizedBox.shrink();
        }

        return TarjetaSeccion(
          titulo: 'Insumos en falta',
          accion: RequierePermiso(
            modulo: Modulo.compras,
            nivel: NivelPermiso.cargar,
            child: TextButton.icon(
              onPressed: () => context.push(Rutas.compraNueva),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Registrar compra'),
            ),
          ),
          children: [
            Column(
              children: [
                for (var i = 0; i < faltantes.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ItemInsumoFaltante(item: faltantes[i]),
                ],
              ],
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ItemInsumoFaltante extends StatelessWidget {
  const _ItemInsumoFaltante({required this.item});

  final InsumoConStock item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.insumo.nombre),
      subtitle: Text(
        'Stock actual: ${item.stockTexto} · Mínimo: ${item.insumo.unidad.formatear(item.insumo.stockMinimo)}',
      ),
      trailing: InsigniaEstado(
        texto: 'Falta ${item.insumo.unidad.formatear(item.cantidadFaltante)}',
        color: ColorEstado.peligro,
      ),
      onTap: () => context.push(Rutas.stock),
    );
  }
}
