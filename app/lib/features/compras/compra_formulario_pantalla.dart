import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class CompraFormularioPantalla extends ConsumerStatefulWidget {
  const CompraFormularioPantalla({super.key});

  @override
  ConsumerState<CompraFormularioPantalla> createState() =>
      _CompraFormularioPantallaState();
}

class _RenglonCompra {
  Insumo? insumo;
  int? cantidad;
  Dinero? precioTotal;
}

class _CompraFormularioPantallaState
    extends ConsumerState<CompraFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  String? _proveedorId;
  MedioPago _medioPago = MedioPago.efectivo;
  String _notas = '';
  final List<_RenglonCompra> _renglones = [_RenglonCompra()];

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
  }

  Dinero get _totalCalculado => _renglones.fold(
    Dinero.cero,
    (acc, r) => acc + (r.precioTotal ?? Dinero.cero),
  );

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final itemsDatos = <CompraItemDatos>[];
    for (final r in _renglones) {
      if (r.insumo == null || r.cantidad == null || r.cantidad! <= 0) {
        throw const ErrorDeNegocio('Completá los datos de todos los insumos.');
      }
      itemsDatos.add(
        CompraItemDatos(
          insumoId: r.insumo!.id,
          cantidad: r.cantidad!,
          precioTotal: r.precioTotal ?? Dinero.cero,
        ),
      );
    }

    if (itemsDatos.isEmpty) {
      throw const ErrorDeNegocio('Agregá al menos un insumo a la compra.');
    }

    final datos = CompraDatos(
      proveedorId: _proveedorId,
      fecha: _fecha,
      medioPago: _medioPago,
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
      items: itemsDatos,
    );

    await ref.read(comprasRepositorioProvider).registrar(datos);
    if (mounted) {
      mostrarExito(context, 'Compra registrada');
      context.pop();
    }
  }

  Widget _construirRenglon(int index) {
    final item = _renglones[index];
    final tema = Theme.of(context);
    return Card(
      key: ObjectKey(item),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: tema.colorScheme.primaryContainer,
                  foregroundColor: tema.colorScheme.onPrimaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Insumo ${index + 1}',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_renglones.length > 1)
                  IconButton(
                    tooltip: 'Quitar insumo',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _renglones.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SelectorInsumo(
              insumoId: item.insumo?.id,
              obligatorio: true,
              excluir: {
                for (var j = 0; j < _renglones.length; j++)
                  if (j != index && _renglones[j].insumo != null)
                    _renglones[j].insumo!.id,
              },
              onChanged: (nuevoInsumo) {
                setState(() {
                  if (item.insumo?.id != nuevoInsumo?.id) {
                    item.insumo = nuevoInsumo;
                    item.cantidad = null;
                  }
                });
              },
            ),
            if (item.insumo != null) ...[
              Separacion.chica,
              CampoCantidad(
                key: ValueKey(
                  'cant_${identityHashCode(item)}_${item.insumo!.id}',
                ),
                etiqueta: 'Cantidad',
                unidad: item.insumo!.unidad,
                valorInicial: item.cantidad,
                obligatorio: true,
                permitirCero: false,
                onChanged: (c) => item.cantidad = c,
              ),
              Separacion.chica,
              CampoDinero(
                key: ValueKey('precio_${identityHashCode(item)}'),
                etiqueta: 'Precio total del ítem',
                valorInicial: item.precioTotal,
                obligatorio: true,
                permitirCero: true,
                onChanged: (monto) {
                  setState(() {
                    item.precioTotal = monto;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Registrar compra',
      cuerpo: FormularioResponsivo(
        formKey: _formKey,
        campos: [
          CampoFecha(
            etiqueta: 'Fecha',
            valor: _fecha,
            obligatorio: true,
            onChanged: (v) {
              if (v != null) setState(() => _fecha = v);
            },
          ),
          SelectorProveedor(
            proveedorId: _proveedorId,
            onChanged: (p) => setState(() => _proveedorId = p?.id),
          ),
          SelectorMedioPago(
            valor: _medioPago,
            onChanged: (mp) => setState(() => _medioPago = mp),
          ),
          TarjetaSeccion(
            titulo: 'Insumos comprados',
            children: [
              for (var i = 0; i < _renglones.length; i++) ...[
                if (i > 0) Separacion.chica,
                _construirRenglon(i),
              ],
              Separacion.chica,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _renglones.add(_RenglonCompra());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar otro insumo'),
                ),
              ),
              Separacion.media,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de la compra',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextoDinero(
                      _totalCalculado,
                      estilo: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
          texto: 'Registrar compra',
          onGuardar: _guardar,
        ),
      ),
    );
  }
}
