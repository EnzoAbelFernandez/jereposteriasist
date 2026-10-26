import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

enum _FiltroRapidoCliente { habituales, cumplePronto }

class ClientesListaPantalla extends ConsumerStatefulWidget {
  const ClientesListaPantalla({super.key});

  @override
  ConsumerState<ClientesListaPantalla> createState() =>
      _ClientesListaPantallaState();
}

class _ClientesListaPantallaState extends ConsumerState<ClientesListaPantalla> {
  String _busqueda = '';
  Set<_FiltroRapidoCliente> _filtros = {};

  @override
  Widget build(BuildContext context) {
    final asyncBase = ref.watch(clientesProvider(_busqueda));
    final fechaBase = hoy();
    final asyncClientes = asyncBase.whenData((lista) {
      return lista.where((c) {
        if (_filtros.contains(_FiltroRapidoCliente.habituales) &&
            !c.esHabitual) {
          return false;
        }
        if (_filtros.contains(_FiltroRapidoCliente.cumplePronto)) {
          final faltan = c.diasParaCumple(fechaBase);
          if (faltan == null || faltan > 7) return false;
        }
        return true;
      }).toList();
    });

    return PantallaBase(
      titulo: 'Clientes',
      botonFlotante: RequierePermiso(
        modulo: Modulo.clientes,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.clienteNuevo),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Nuevo cliente'),
        ),
      ),
      cuerpo: Column(
        children: [
          CampoBusqueda(
            hint: 'Buscar por nombre o teléfono...',
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          ChipsFiltro<_FiltroRapidoCliente>(
            opciones: _FiltroRapidoCliente.values,
            seleccionados: _filtros,
            etiqueta: (f) => f == _FiltroRapidoCliente.habituales
                ? 'Habituales'
                : 'Cumple en 7 días',
            onChanged: (nuevos) => setState(() => _filtros = nuevos),
          ),
          Expanded(
            child: ListaAsync<Cliente>(
              valor: asyncClientes,
              vacio: EstadoVacio(
                icono: Icons.people_outline,
                mensaje: 'Todavía no cargaste clientes',
                textoAccion: 'Cargar cliente',
                onAccion: () => context.push(Rutas.clienteNuevo),
              ),
              itemBuilder: (context, c) {
                final diasCumple = c.diasParaCumple(fechaBase);
                final subtitulo = [
                  if (c.telefono != null && c.telefono!.isNotEmpty) c.telefono!,
                  if (c.cumpleTexto != null) 'Cumple: ${c.cumpleTexto!}',
                ].join(' • ');
                return ListTile(
                  leading: Avatar(c.nombre),
                  title: Row(
                    children: [
                      Flexible(child: Text(c.nombre)),
                      if (c.esHabitual) ...[
                        Separacion.chica,
                        const InsigniaHabitual(),
                      ],
                    ],
                  ),
                  subtitle: subtitulo.isNotEmpty ? Text(subtitulo) : null,
                  trailing: diasCumple != null && diasCumple <= 7
                      ? InsigniaEstado(
                          texto: diasCumple == 0
                              ? '¡Cumple hoy!'
                              : 'Cumple en $diasCumple d',
                          color: ColorEstado.info,
                          icono: Icons.cake_outlined,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () => context.push(Rutas.cliente(c.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
