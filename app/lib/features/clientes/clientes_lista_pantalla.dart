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
    final tema = Theme.of(context);
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
              separadores: false,
              vacio: EstadoVacio(
                icono: Icons.people_outline,
                mensaje: 'Todavía no cargaste clientes',
                textoAccion: 'Cargar cliente',
                onAccion: () => context.push(Rutas.clienteNuevo),
              ),
              itemBuilder: (context, c) {
                final diasCumple = c.diasParaCumple(fechaBase);
                final tieneTelefono =
                    c.telefono != null && c.telefono!.trim().isNotEmpty;
                final tieneCumple = c.cumpleTexto != null;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push(Rutas.cliente(c.id)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Avatar(c.nombre, radio: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        c.nombre,
                                        style: tema.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (c.esHabitual) ...[
                                      const SizedBox(width: 6),
                                      const InsigniaHabitual(),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (tieneTelefono) ...[
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        c.telefono!,
                                        style: tema.textTheme.bodySmall
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                    if (tieneTelefono && tieneCumple) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          color:
                                              tema.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (tieneCumple) ...[
                                      Icon(
                                        Icons.cake_outlined,
                                        size: 14,
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          c.cumpleTexto!,
                                          style: tema.textTheme.bodySmall
                                              ?.copyWith(
                                                color: tema
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (diasCumple != null && diasCumple <= 7)
                            InsigniaEstado(
                              texto: diasCumple == 0
                                  ? '¡Cumple hoy!'
                                  : 'Cumple en $diasCumple d',
                              color: ColorEstado.info,
                              icono: Icons.cake_outlined,
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
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
