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

  Future<void> _cambiarRol(Perfil perfil) async {
    if (_procesando) return;
    final nuevoRol = perfil.esJefe ? Rol.empleado : Rol.jefe;
    final titulo = perfil.esJefe ? 'Pasar a empleado' : 'Convertir en jefe';
    final mensaje = perfil.esJefe
        ? '¿Seguro que querés pasar a ${perfil.nombre} al rol de empleado?'
        : '¿Seguro que querés darle rol de jefe con acceso total a ${perfil.nombre}?';

    final ok = await confirmar(
      context,
      titulo: titulo,
      mensaje: mensaje,
      textoConfirmar: 'Confirmar',
      peligroso: perfil.esJefe,
    );
    if (!ok || !mounted) return;

    setState(() => _procesando = true);
    try {
      await ejecutarConManejo(
        context,
        () =>
            ref.read(equipoRepositorioProvider).cambiarRol(perfil.id, nuevoRol),
        mensajeExito: 'Rol actualizado',
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

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
    final miPerfil = ref.watch(perfilActualProvider).asData?.value;

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 48),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Avatar(perfil.nombre, radio: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil.nombre,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (perfil.telefono != null &&
                          perfil.telefono!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          perfil.telefono!,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          InsigniaEstado(
                            texto: perfil.rol.etiqueta,
                            color: perfil.esJefe
                                ? ColorEstado.info
                                : ColorEstado.neutro,
                            icono: perfil.esJefe
                                ? Icons.admin_panel_settings_outlined
                                : Icons.badge_outlined,
                          ),
                          InsigniaEstado(
                            texto: perfil.activo ? 'Activo' : 'Inactivo',
                            color: perfil.activo
                                ? ColorEstado.exito
                                : ColorEstado.advertencia,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (miPerfil?.id != perfil.id)
                  OutlinedButton.icon(
                    onPressed: _procesando ? null : () => _cambiarRol(perfil),
                    icon: const Icon(
                      Icons.published_with_changes_outlined,
                      size: 16,
                    ),
                    label: Text(
                      perfil.esJefe ? 'Pasar a empleado' : 'Hacer jefe',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Separacion.chica,
        if (perfil.esJefe) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tema.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tema.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: tema.colorScheme.primary,
                ),
                Separacion.media,
                Expanded(
                  child: Text(
                    'El jefe tiene acceso total a todos los módulos. Para restringir permisos, pasalo primero a empleado.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          TarjetaSeccion(
            titulo: 'Atajos de configuración rápida',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _procesando
                        ? null
                        : () => _aplicarSoloProduccionYStock(perfil),
                    icon: const Icon(Icons.bakery_dining_outlined, size: 18),
                    label: const Text('Solo producción y stock'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _procesando
                        ? null
                        : () => _aplicarAtencionPedidos(perfil),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Atención de pedidos'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _procesando
                        ? null
                        : () => _aplicarQuitarTodos(perfil),
                    icon: const Icon(Icons.block_outlined, size: 18),
                    label: const Text('Quitar todos'),
                  ),
                ],
              ),
            ],
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 12),
          child: Row(
            children: [
              Icon(
                Icons.security_outlined,
                size: 20,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Permisos por módulo',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

  String _etiquetaNivel(NivelPermiso nivel) {
    switch (nivel) {
      case NivelPermiso.ninguno:
        return 'Ninguno';
      case NivelPermiso.ver:
        return 'Ver';
      case NivelPermiso.cargar:
        return 'Cargar';
      case NivelPermiso.editar:
        return 'Editar';
    }
  }

  ColorEstado _colorNivel(NivelPermiso nivel) {
    switch (nivel) {
      case NivelPermiso.ninguno:
        return ColorEstado.neutro;
      case NivelPermiso.ver:
        return ColorEstado.info;
      case NivelPermiso.cargar:
        return ColorEstado.advertencia;
      case NivelPermiso.editar:
        return ColorEstado.exito;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.primaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    modulo.icono,
                    color: tema.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modulo.etiqueta,
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        nivelActual.descripcion,
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                InsigniaEstado(
                  texto: _etiquetaNivel(nivelActual),
                  color: _colorNivel(nivelActual),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<NivelPermiso>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                segments: [
                  for (final nivel in NivelPermiso.values)
                    ButtonSegment<NivelPermiso>(
                      value: nivel,
                      label: Text(
                        _etiquetaNivel(nivel),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      tooltip: '${_etiquetaNivel(nivel)}: ${nivel.descripcion}',
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
