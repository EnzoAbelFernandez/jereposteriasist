import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class GastoFormularioPantalla extends ConsumerStatefulWidget {
  const GastoFormularioPantalla({super.key});

  @override
  ConsumerState<GastoFormularioPantalla> createState() =>
      _GastoFormularioPantallaState();
}

class _GastoFormularioPantallaState
    extends ConsumerState<GastoFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();

  DateTime _fecha = hoy();
  String? _categoriaId;
  String _descripcion = '';
  Dinero? _monto;
  MedioPago _medioPago = MedioPago.efectivo;
  String _notas = '';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      mostrarError(
        context,
        const ErrorDeNegocio('Elegí una categoría de gasto.'),
      );
      return;
    }
    if (_monto == null || !_monto!.esPositivo) {
      mostrarError(
        context,
        const ErrorDeNegocio('El monto del gasto debe ser mayor a cero.'),
      );
      return;
    }

    final datos = GastoDatos(
      fecha: _fecha,
      categoriaId: _categoriaId!,
      descripcion: _descripcion.trim(),
      monto: _monto!,
      medioPago: _medioPago,
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
    );

    await ref.read(gastosRepositorioProvider).registrar(datos);
    if (mounted) {
      mostrarExito(context, 'Gasto registrado');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return PantallaBase(
      titulo: 'Registrar gasto',
      cuerpo: FormularioResponsivo(
        formKey: _formKey,
        campos: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tema.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: tema.colorScheme.primary,
                ),
                Separacion.media,
                Expanded(
                  child: Text(
                    'Cargá los detalles del gasto operativo o compra general para impactar en caja y reportes.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CampoFecha(
            etiqueta: 'Fecha',
            valor: _fecha,
            obligatorio: true,
            onChanged: (d) {
              if (d != null) {
                setState(() => _fecha = d);
              }
            },
          ),
          SelectorCategoriaGasto(
            categoriaId: _categoriaId,
            obligatorio: true,
            onChanged: (c) => setState(() => _categoriaId = c?.id),
          ),
          CampoTexto(
            etiqueta: 'Descripción',
            valorInicial: _descripcion,
            obligatorio: true,
            icono: Icons.description_outlined,
            onChanged: (v) => _descripcion = v,
          ),
          CampoDinero(
            etiqueta: 'Monto',
            valorInicial: _monto,
            obligatorio: true,
            permitirCero: false,
            onChanged: (d) => _monto = d,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Medio de pago',
                  style: tema.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SelectorMedioPago(
                valor: _medioPago,
                onChanged: (m) => setState(() => _medioPago = m),
              ),
            ],
          ),
          CampoTexto(
            etiqueta: 'Notas (opcional)',
            valorInicial: _notas,
            maxLineas: 2,
            icono: Icons.notes_outlined,
            onChanged: (v) => _notas = v,
          ),
        ],
        botonGuardar: BotonGuardar(
          texto: 'Registrar gasto',
          onGuardar: _guardar,
        ),
      ),
    );
  }
}
