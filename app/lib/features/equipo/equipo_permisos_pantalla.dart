import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class EquipoPermisosPantalla extends ConsumerStatefulWidget {
  const EquipoPermisosPantalla({super.key, required this.perfilId});

  final String perfilId;

  @override
  ConsumerState<EquipoPermisosPantalla> createState() =>
      _EquipoPermisosPantallaState();
}

class _EquipoPermisosPantallaState
    extends ConsumerState<EquipoPermisosPantalla> {
  bool _procesando = false;

  Future<void> _cambiarPermiso(Modulo modulo, NivelPermiso nuevoNivel) async {
    if (_procesando) return;
    setState(() => _procesando = true);
    try {
      await ejecutarConManejo(
        context,
        () => ref
            .read(equipoRepositorioProvider)
            .cambiarPermiso(widget.perfilId, modulo, nuevoNivel),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _aplicarAtajo({
    required String titulo,
    required String mensaje,
    required Map<Modulo, NivelPermiso> permisosNuevos,
    bool peligroso = false,
  }) async {
    if (_procesando) return;
    final ok = await confirmar(
      context,
      titulo: titulo,
      mensaje: mensaje,
      textoConfirmar: 'Confirmar',
      peligroso: peligroso,
    );
    if (!ok || !mounted) return;

    setState(() => _procesando = true);
    try {
      await ejecutarConManejo(context, () async {
        final repo = ref.read(equipoRepositorioProvider);
        for (final modulo in Modulo.values) {
          final nivel = permisosNuevos[modulo] ?? NivelPermiso.ninguno;
          await repo.cambiarPermiso(widget.perfilId, modulo, nivel);
        }
      }, mensajeExito: 'Permisos actualizados');
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _aplicarSoloProduccionYStock(Perfil perfil) {
    return _aplicarAtajo(
      titulo: 'Solo producción y stock',
      mensaje:
          '¿Querés asignar los permisos de producción y stock a ${perfil.nombre}?',
      permisosNuevos: const {
        Modulo.produccion: NivelPermiso.cargar,
        Modulo.stock: NivelPermiso.cargar,
        Modulo.pedidos: NivelPermiso.ver,
      },
    );
  }

  Future<void> _aplicarAtencionPedidos(Perfil perfil) {
    return _aplicarAtajo(
      titulo: 'Atención de pedidos',
      mensaje:
          '¿Querés asignar los permisos de atención de pedidos a ${perfil.nombre}?',
      permisosNuevos: const {
        Modulo.pedidos: NivelPermiso.cargar,
        Modulo.clientes: NivelPermiso.cargar,
        Modulo.catalogo: NivelPermiso.ver,
      },
    );
  }

  Future<void> _aplicarQuitarTodos(Perfil perfil) {
    return _aplicarAtajo(
      titulo: 'Quitar todos los permisos',
      mensaje:
          '¿Seguro que querés quitarle todos los permisos a ${perfil.nombre}?',
      peligroso: true,
      permisosNuevos: const {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncPerfil = ref.watch(perfilProvider(widget.perfilId));
    final asyncPermisos = ref.watch(permisosDePerfilProvider(widget.perfilId));

    final perfil = asyncPerfil.value;
    final titulo = perfil != null
        ? 'Permisos de ${perfil.nombre}'
        : 'Permisos del empleado';

    return PantallaBase(
      titulo: titulo,
      cuerpo: VistaAsync<Perfil?>(
        valor: asyncPerfil,
        builder: (context, p) {
          final perfilCargado = p!;
          return VistaAsync<Map<Modulo, NivelPermiso>>(
            valor: asyncPermisos,
            builder: (context, permisos) =>
                _construirCuerpo(perfilCargado, permisos),
          );
        },
      ),
    );
  }

  Widget _construirCuerpo(Perfil perfil, Map<Modulo, NivelPermiso> permisos) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 48),
      children: [
        if (perfil.esJefe) ...[
          Card(
            color: tema.colorScheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: tema.colorScheme.primary),
                  Separacion.media,
                  Expanded(
                    child: Text(
                      'El jefe tiene acceso total a todos los módulos',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          TarjetaSeccion(
            titulo: 'Atajos',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _procesando
                        ? null
                        : () => _aplicarSoloProduccionYStock(perfil),
                    icon: const Icon(Icons.bakery_dining_outlined),
                    label: const Text('Solo producción y stock'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _procesando
                        ? null
                        : () => _aplicarAtencionPedidos(perfil),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Atención de pedidos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _procesando
                        ? null
                        : () => _aplicarQuitarTodos(perfil),
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Quitar todos los permisos'),
                  ),
                ],
              ),
            ],
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            'Permisos por módulo',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final modulo in Modulo.values)
          _TarjetaModulo(
            modulo: modulo,
            deshabilitado: perfil.esJefe || _procesando,
            nivelActual: perfil.esJefe
                ? NivelPermiso.editar
                : (permisos[modulo] ?? NivelPermiso.ninguno),
            onCambiar: (nivel) => _cambiarPermiso(modulo, nivel),
          ),
      ],
    );
  }
}

class _TarjetaModulo extends StatelessWidget {
  const _TarjetaModulo({
    required this.modulo,
    required this.deshabilitado,
    required this.nivelActual,
    required this.onCambiar,
  });

  final Modulo modulo;
  final bool deshabilitado;
  final NivelPermiso nivelActual;
  final ValueChanged<NivelPermiso> onCambiar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(modulo.icono, color: tema.colorScheme.primary),
                Separacion.chica,
                Expanded(
                  child: Text(
                    modulo.etiqueta,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Separacion.chica,
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<NivelPermiso>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  for (final nivel in NivelPermiso.values)
                    ButtonSegment<NivelPermiso>(
                      value: nivel,
                      label: Text(
                        nivel.etiqueta,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: nivel.descripcion,
                    ),
                ],
                selected: {nivelActual},
                onSelectionChanged: deshabilitado
                    ? null
                    : (seleccion) => onCambiar(seleccion.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
