import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class ClienteFormularioPantalla extends ConsumerStatefulWidget {
  const ClienteFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  ConsumerState<ClienteFormularioPantalla> createState() =>
      _ClienteFormularioPantallaState();
}

class _ClienteFormularioPantallaState
    extends ConsumerState<ClienteFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _nombre = '';
  String _telefono = '';
  String _email = '';
  String _direccion = '';
  int? _cumpleDia;
  int? _cumpleMes;
  int? _cumpleAnio;
  String _preferencias = '';
  String _alergias = '';
  HabitualModo _habitualModo = HabitualModo.auto;
  String _notas = '';

  void _precargar(Cliente c) {
    if (_inicializado) return;
    _inicializado = true;
    _nombre = c.nombre;
    _telefono = c.telefono ?? '';
    _email = c.email ?? '';
    _direccion = c.direccion ?? '';
    _cumpleDia = c.cumpleDia;
    _cumpleMes = c.cumpleMes;
    _cumpleAnio = c.cumpleAnio;
    _preferencias = c.preferencias ?? '';
    _alergias = c.alergias ?? '';
    _habitualModo = c.habitualModo;
    _notas = c.notas ?? '';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final datos = ClienteDatos(
      nombre: _nombre.trim(),
      telefono: _telefono.trim().isEmpty ? null : _telefono.trim(),
      email: _email.trim().isEmpty ? null : _email.trim(),
      direccion: _direccion.trim().isEmpty ? null : _direccion.trim(),
      cumpleDia: _cumpleDia,
      cumpleMes: _cumpleMes,
      cumpleAnio: _cumpleAnio,
      preferencias: _preferencias.trim().isEmpty ? null : _preferencias.trim(),
      alergias: _alergias.trim().isEmpty ? null : _alergias.trim(),
      habitualModo: _habitualModo,
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
    );
    final repo = ref.read(clientesRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(datos);
    }
    if (mounted) {
      mostrarExito(
        context,
        widget.esEdicion
            ? 'Cliente actualizado con éxito.'
            : 'Cliente creado con éxito.',
      );
      context.pop();
    }
  }

  Widget _construirFormulario() {
    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        TarjetaSeccion(
          titulo: 'Datos personales y contacto',
          icono: Icons.person_outline,
          children: [
            CampoTexto(
              etiqueta: 'Nombre y apellido',
              valorInicial: _nombre,
              obligatorio: true,
              icono: Icons.person_outline,
              onChanged: (v) => _nombre = v,
            ),
            Separacion.media,
            CampoTexto(
              etiqueta: 'Teléfono / WhatsApp',
              valorInicial: _telefono,
              teclado: TextInputType.phone,
              icono: Icons.phone_outlined,
              onChanged: (v) => _telefono = v,
            ),
            Separacion.media,
            CampoTexto(
              etiqueta: 'Correo electrónico (opcional)',
              valorInicial: _email,
              teclado: TextInputType.emailAddress,
              icono: Icons.email_outlined,
              onChanged: (v) => _email = v,
            ),
            Separacion.media,
            CampoTexto(
              etiqueta: 'Dirección de entrega habitual',
              valorInicial: _direccion,
              icono: Icons.place_outlined,
              onChanged: (v) => _direccion = v,
            ),
          ],
        ),
        TarjetaSeccion(
          titulo: 'Cumpleaños y fidelidad',
          icono: Icons.cake_outlined,
          children: [
            CampoCumpleanos(
              dia: _cumpleDia,
              mes: _cumpleMes,
              anio: _cumpleAnio,
              onChanged: (d, m, a) => setState(() {
                _cumpleDia = d;
                _cumpleMes = m;
                _cumpleAnio = a;
              }),
            ),
            Separacion.media,
            SelectorOpcion<HabitualModo>(
              etiqueta: 'Condición de cliente habitual',
              opciones: HabitualModo.values,
              valor: _habitualModo,
              etiquetaDe: (m) => m.etiqueta,
              onChanged: (v) {
                if (v != null) setState(() => _habitualModo = v);
              },
            ),
          ],
        ),
        TarjetaSeccion(
          titulo: 'Preferencias y observaciones',
          icono: Icons.notes_outlined,
          children: [
            CampoTexto(
              etiqueta: 'Preferencias (sabores preferidos, temáticas)',
              valorInicial: _preferencias,
              icono: Icons.favorite_border,
              onChanged: (v) => _preferencias = v,
            ),
            Separacion.media,
            CampoTexto(
              etiqueta: 'Alergias o restricciones alimentarias',
              valorInicial: _alergias,
              icono: Icons.warning_amber_outlined,
              onChanged: (v) => _alergias = v,
            ),
            Separacion.media,
            CampoTexto(
              etiqueta: 'Notas generales del cliente',
              valorInicial: _notas,
              maxLineas: 3,
              icono: Icons.notes_outlined,
              onChanged: (v) => _notas = v,
            ),
          ],
        ),
      ],
      botonGuardar: BotonGuardar(
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear cliente',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nuevo cliente',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncCliente = ref.watch(clienteProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar cliente',
      cuerpo: VistaAsync<Cliente?>(
        valor: asyncCliente,
        builder: (context, cliente) {
          _precargar(cliente!);
          return _construirFormulario();
        },
      ),
    );
  }
}
