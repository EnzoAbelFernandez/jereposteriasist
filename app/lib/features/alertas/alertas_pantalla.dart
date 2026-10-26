import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class AlertasPantalla extends ConsumerStatefulWidget {
  const AlertasPantalla({super.key});

  @override
  ConsumerState<AlertasPantalla> createState() => _AlertasPantallaState();
}

class _AlertasPantallaState extends ConsumerState<AlertasPantalla> {
  bool _soloNoLeidas = false;
  Set<TipoAlerta> _tiposSeleccionados = {};

  @override
  Widget build(BuildContext context) {
    final cantNoLeidas = ref.watch(cantidadAlertasNoLeidasProvider).value ?? 0;
    final asyncAlertas = ref.watch(alertasProvider);

    final asyncAlertasFiltradas = asyncAlertas.whenData((lista) {
      return lista.where((a) {
        if (_soloNoLeidas && a.leida) return false;
        if (_tiposSeleccionados.isNotEmpty &&
            !_tiposSeleccionados.contains(a.tipo)) {
          return false;
        }
        return true;
      }).toList();
    });

    final hayNoLeidas =
        cantNoLeidas > 0 || (asyncAlertas.value?.any((a) => !a.leida) ?? false);

    return PantallaBase(
      titulo: 'Alertas',
      acciones: [
        if (hayNoLeidas)
          TextButton(
            onPressed: () =>
                ref.read(alertasRepositorioProvider).marcarTodasLeidas(),
            child: const Text('Marcar todas como leídas'),
          ),
      ],
      cuerpo: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 0, 6),
                child: FilterChip(
                  label: const Text('Solo no leídas'),
                  selected: _soloNoLeidas,
                  onSelected: (activo) =>
                      setState(() => _soloNoLeidas = activo),
                ),
              ),
              Expanded(
                child: ChipsFiltro<TipoAlerta>(
                  opciones: TipoAlerta.values,
                  seleccionados: _tiposSeleccionados,
                  etiqueta: (t) => t.etiqueta,
                  onChanged: (nuevos) =>
                      setState(() => _tiposSeleccionados = nuevos),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListaAsync<Alerta>(
              valor: asyncAlertasFiltradas,
              vacio: const EstadoVacio(
                icono: Icons.notifications_none,
                mensaje: 'No tenés alertas pendientes',
              ),
              itemBuilder: (context, a) {
                return ListTile(
                  leading: IconoAlerta(a.tipo),
                  title: Text(
                    a.titulo,
                    style: !a.leida
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.mensaje.isNotEmpty) Text(a.mensaje),
                      Text(
                        formatearFechaHora(a.creadoEn),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!a.leida) {
                      ref.read(alertasRepositorioProvider).marcarLeida(a.id);
                    }
                    if (a.rutaDestino != null) {
                      context.push(a.rutaDestino!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
