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
          TextButton.icon(
            onPressed: () =>
                ref.read(alertasRepositorioProvider).marcarTodasLeidas(),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Marcar todas como leídas'),
          ),
      ],
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Solo no leídas'),
                  selected: _soloNoLeidas,
                  onSelected: (activo) =>
                      setState(() => _soloNoLeidas = activo),
                ),
                const SizedBox(width: 8),
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
          ),
          Expanded(
            child: ListaAsync<Alerta>(
              valor: asyncAlertasFiltradas,
              separadores: false,
              vacio: const EstadoVacio(
                icono: Icons.notifications_none,
                mensaje: 'No tenés alertas pendientes',
              ),
              itemBuilder: (context, a) => _ItemAlerta(alerta: a),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemAlerta extends ConsumerWidget {
  const _ItemAlerta({required this.alerta});

  final Alerta alerta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final a = alerta;

    Widget? botonWhatsApp;
    if (a.tipo == TipoAlerta.cumpleanos && a.entidadId != null) {
      final cliente = ref.watch(clienteProvider(a.entidadId!)).asData?.value;
      final tel = cliente?.telefono?.trim();
      if (cliente != null && tel != null && tel.isNotEmpty) {
        botonWhatsApp = IconButton(
          tooltip: 'Saludar por WhatsApp',
          icon: const Icon(Icons.chat_outlined),
          onPressed: () {
            if (!a.leida) {
              ref.read(alertasRepositorioProvider).marcarLeida(a.id);
            }
            abrirWhatsApp(
              cliente.telefono!,
              mensaje:
                  '¡Hola ${cliente.nombre}! Se acerca tu cumpleaños y queremos regalarte un descuento especial en tu próximo pedido 🎂',
            );
          },
        );
      }
    }

    final fechaRelativa = formatearFechaRelativa(a.creadoEn);
    final hora = formatearHora(a.creadoEn);
    final textoFechaHora = '$fechaRelativa a las $hora';

    final colorFondo = !a.leida
        ? cs.primaryContainer.withValues(alpha: 0.24)
        : cs.surfaceContainerLowest;

    final colorBorde = !a.leida
        ? cs.primary.withValues(alpha: 0.32)
        : cs.outlineVariant.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde, width: !a.leida ? 1.2 : 1.0),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!a.leida) {
              ref.read(alertasRepositorioProvider).marcarLeida(a.id);
            }
            if (a.rutaDestino != null) {
              context.push(a.rutaDestino!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: IconoAlerta(a.tipo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              a.titulo,
                              style: tema.textTheme.titleSmall?.copyWith(
                                fontWeight: !a.leida
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          if (!a.leida) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (a.mensaje.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          a.mensaje,
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: !a.leida
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color: cs.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            textoFechaHora,
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (botonWhatsApp != null || !a.leida) ...[
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?botonWhatsApp,
                      if (!a.leida)
                        IconButton(
                          tooltip: 'Marcar como leída',
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => ref
                              .read(alertasRepositorioProvider)
                              .marcarLeida(a.id),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
