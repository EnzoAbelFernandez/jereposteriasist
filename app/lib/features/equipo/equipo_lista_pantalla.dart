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
      cuerpo: ListaAsync<Perfil>(
        valor: asyncPerfiles,
        vacio: const EstadoVacio(
          icono: Icons.badge_outlined,
          mensaje: 'Todavía no hay miembros en el equipo',
        ),
        itemBuilder: (context, p) {
          return ListTile(
            leading: Avatar(p.nombre),
            title: Row(
              children: [
                Flexible(child: Text(p.nombre)),
                Separacion.chica,
                InsigniaEstado(
                  texto: p.rol.etiqueta,
                  color: p.esJefe ? ColorEstado.info : ColorEstado.neutro,
                ),
                if (!p.activo) ...[
                  Separacion.chica,
                  const InsigniaEstado(
                    texto: 'Inactivo',
                    color: ColorEstado.advertencia,
                  ),
                ],
              ],
            ),
            subtitle: p.telefono != null && p.telefono!.isNotEmpty
                ? Text(p.telefono!)
                : null,
            onTap: !p.esJefe
                ? () => context.push(Rutas.equipoPermisos(p.id))
                : null,
            trailing: !p.esJefe
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Permisos',
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        onPressed: () =>
                            context.push(Rutas.equipoPermisos(p.id)),
                      ),
                      if (p.activo)
                        IconButton(
                          tooltip: 'Desactivar',
                          icon: const Icon(Icons.person_off_outlined),
                          onPressed: () => _desactivar(p),
                        )
                      else
                        IconButton(
                          tooltip: 'Reactivar',
                          icon: const Icon(Icons.restore),
                          onPressed: () => _reactivar(p),
                        ),
                    ],
                  )
                : null,
          );
        },
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
                onChanged: (v) => _nombre = v,
              ),
              Separacion.media,
              CampoTexto(
                etiqueta: 'Email',
                obligatorio: true,
                teclado: TextInputType.emailAddress,
                onChanged: (v) => _email = v,
              ),
              Separacion.media,
              CampoTexto(
                etiqueta: 'Teléfono (opcional)',
                teclado: TextInputType.phone,
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
