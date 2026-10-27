import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class EquipoListaPantalla extends ConsumerStatefulWidget {
  const EquipoListaPantalla({super.key});

  @override
  ConsumerState<EquipoListaPantalla> createState() =>
      _EquipoListaPantallaState();
}

class _EquipoListaPantallaState extends ConsumerState<EquipoListaPantalla> {
  bool _incluirInactivos = false;

  Future<void> _mostrarDialogoInvitar(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const _DialogoInvitarEmpleado(),
    );
  }

  Future<void> _desactivar(Perfil perfil) async {
    final ok = await confirmar(
      context,
      titulo: 'Desactivar empleado',
      mensaje: '¿Seguro que querés desactivar a ${perfil.nombre}?',
      textoConfirmar: 'Desactivar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    await ejecutarConManejo(context, () async {
      try {
        await ref.read(equipoRepositorioProvider).desactivar(perfil.id);
      } on SinConexion catch (e) {
        throw ErrorDeNegocio(e.mensaje);
      }
    }, mensajeExito: 'Empleado desactivado');
  }

  Future<void> _reactivar(Perfil perfil) async {
    final ok = await confirmar(
      context,
      titulo: 'Reactivar empleado',
      mensaje: '¿Seguro que querés reactivar a ${perfil.nombre}?',
      textoConfirmar: 'Reactivar',
    );
    if (!ok || !mounted) return;
    await ejecutarConManejo(context, () async {
      try {
        await ref.read(equipoRepositorioProvider).reactivar(perfil.id);
      } on SinConexion catch (e) {
        throw ErrorDeNegocio(e.mensaje);
      }
    }, mensajeExito: 'Empleado reactivado');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final asyncPerfiles = ref.watch(perfilesProvider(_incluirInactivos));

    return PantallaBase(
      titulo: 'Equipo',
      acciones: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilterChip(
            label: const Text('Ver inactivos'),
            selected: _incluirInactivos,
            tooltip: 'Ver inactivos',
            onSelected: (v) => setState(() => _incluirInactivos = v),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configuración',
          onPressed: () => context.push(Rutas.configuracion),
        ),
      ],
      botonFlotante: SoloJefe(
        child: FloatingActionButton.extended(
          onPressed: () => _mostrarDialogoInvitar(context),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Invitar empleado'),
        ),
      ),
      cuerpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 20,
                    color: tema.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Administrá los miembros del equipo, sus roles y los permisos de acceso a cada módulo.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Separacion.chica,
          Expanded(
            child: ListaAsync<Perfil>(
              valor: asyncPerfiles,
              separadores: false,
              vacio: const EstadoVacio(
                icono: Icons.badge_outlined,
                mensaje: 'Todavía no hay miembros en el equipo',
              ),
              itemBuilder: (context, p) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: !p.esJefe
                        ? () => context.push(Rutas.equipoPermisos(p.id))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Avatar(p.nombre, radio: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nombre,
                                      style: tema.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (p.telefono != null &&
                                        p.telefono!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 13,
                                            color: tema
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            p.telefono!,
                                            style: tema.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: tema
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                children: [
                                  InsigniaEstado(
                                    texto: p.rol.etiqueta,
                                    color: p.esJefe
                                        ? ColorEstado.info
                                        : ColorEstado.neutro,
                                    icono: p.esJefe
                                        ? Icons.admin_panel_settings_outlined
                                        : Icons.badge_outlined,
                                  ),
                                  InsigniaEstado(
                                    texto: p.activo ? 'Activo' : 'Inactivo',
                                    color: p.activo
                                        ? ColorEstado.exito
                                        : ColorEstado.advertencia,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!p.esJefe) ...[
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: tema.colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Permisos'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () =>
                                      context.push(Rutas.equipoPermisos(p.id)),
                                ),
                                const SizedBox(width: 8),
                                if (p.activo)
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.person_off_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Desactivar'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: tema.colorScheme.error,
                                    ),
                                    onPressed: () => _desactivar(p),
                                  )
                                else
                                  TextButton.icon(
                                    icon: const Icon(Icons.restore, size: 18),
                                    label: const Text('Reactivar'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _reactivar(p),
                                  ),
                              ],
                            ),
                          ],
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

class _DialogoInvitarEmpleado extends ConsumerStatefulWidget {
  const _DialogoInvitarEmpleado();

  @override
  ConsumerState<_DialogoInvitarEmpleado> createState() =>
      _DialogoInvitarEmpleadoState();
}

class _DialogoInvitarEmpleadoState
    extends ConsumerState<_DialogoInvitarEmpleado> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _email = '';
  String _telefono = '';

  Future<void> _enviarInvitacion() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(equipoRepositorioProvider)
          .invitarEmpleado(
            nombre: _nombre.trim(),
            email: _email.trim(),
            telefono: _telefono.trim().isEmpty ? null : _telefono.trim(),
          );
    } on SinConexion catch (e) {
      throw ErrorDeNegocio(e.mensaje);
    }
    if (mounted) {
      Navigator.of(context).pop();
      mostrarExito(context, 'Invitación enviada');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar empleado'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CampoTexto(
                etiqueta: 'Nombre',
                obligatorio: true,
                icono: Icons.person_outline,
                onChanged: (v) => _nombre = v,
              ),
              Separacion.media,
              CampoTexto(
                etiqueta: 'Email',
                obligatorio: true,
                teclado: TextInputType.emailAddress,
                icono: Icons.mail_outline,
                onChanged: (v) => _email = v,
              ),
              Separacion.media,
              CampoTexto(
                etiqueta: 'Teléfono (opcional)',
                teclado: TextInputType.phone,
                icono: Icons.phone_outlined,
                onChanged: (v) => _telefono = v,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonGuardar(texto: 'Enviar invitación', onGuardar: _enviarInvitacion),
      ],
    );
  }
}
