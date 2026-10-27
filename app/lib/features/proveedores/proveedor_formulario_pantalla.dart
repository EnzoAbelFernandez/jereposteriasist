import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class ProveedorFormularioPantalla extends ConsumerStatefulWidget {
  const ProveedorFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  ConsumerState<ProveedorFormularioPantalla> createState() =>
      _ProveedorFormularioPantallaState();
}

class _ProveedorFormularioPantallaState
    extends ConsumerState<ProveedorFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _nombre = '';
  String _telefono = '';
  String _email = '';
  String _notas = '';

  void _precargar(Proveedor p) {
    if (_inicializado) return;
    _inicializado = true;
    _nombre = p.nombre;
    _telefono = p.telefono ?? '';
    _email = p.email ?? '';
    _notas = p.notas ?? '';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final datos = ProveedorDatos(
      nombre: _nombre.trim(),
      telefono: _telefono.trim().isEmpty ? null : _telefono.trim(),
      email: _email.trim().isEmpty ? null : _email.trim(),
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
    );
    final repo = ref.read(proveedoresRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(datos);
    }
    if (mounted) {
      mostrarExito(context, 'Proveedor guardado');
      context.pop();
    }
  }

  Future<void> _archivar() async {
    final ok = await confirmar(
      context,
      titulo: 'Archivar proveedor',
      mensaje: '¿Querés archivar este proveedor? No se borra el historial de compras.',
      textoConfirmar: 'Archivar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(proveedoresRepositorioProvider).archivar(widget.id!);
      if (mounted) {
        mostrarExito(context, 'Proveedor archivado');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        mostrarError(context, e);
      }
    }
  }

  Widget _construirFormulario() {
    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        if (widget.esEdicion && _nombre.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Avatar(_nombre, radio: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombre,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_telefono.isNotEmpty)
                        Text(
                          _telefono,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                if (_telefono.trim().isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.chat_outlined),
                    tooltip: 'WhatsApp',
                    onPressed: () => abrirWhatsApp(_telefono),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined),
                    tooltip: 'Llamar',
                    onPressed: () => llamar(_telefono),
                  ),
                ],
              ],
            ),
          ),
        CampoTexto(
          etiqueta: 'Nombre',
          valorInicial: _nombre,
          obligatorio: true,
          icono: Icons.business_outlined,
          onChanged: (v) => _nombre = v,
        ),
        CampoTexto(
          etiqueta: 'Teléfono',
          valorInicial: _telefono,
          teclado: TextInputType.phone,
          icono: Icons.phone_outlined,
          onChanged: (v) => _telefono = v,
        ),
        CampoTexto(
          etiqueta: 'Email',
          valorInicial: _email,
          teclado: TextInputType.emailAddress,
          icono: Icons.email_outlined,
          onChanged: (v) => _email = v,
        ),
        CampoTexto(
          etiqueta: 'Notas',
          valorInicial: _notas,
          maxLineas: 3,
          icono: Icons.notes_outlined,
          onChanged: (v) => _notas = v,
        ),
      ],
      botonGuardar: BotonGuardar(
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear proveedor',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nuevo proveedor',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncProveedor = ref.watch(proveedorProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar proveedor',
      acciones: [
        RequierePermiso(
          modulo: Modulo.compras,
          nivel: NivelPermiso.editar,
          child: IconButton(
            tooltip: 'Archivar',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _archivar,
          ),
        ),
      ],
      cuerpo: VistaAsync<Proveedor?>(
        valor: asyncProveedor,
        builder: (context, proveedor) {
          _precargar(proveedor!);
          return _construirFormulario();
        },
      ),
    );
  }
}
