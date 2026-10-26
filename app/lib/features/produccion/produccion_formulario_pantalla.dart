import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class ProduccionFormularioPantalla extends ConsumerStatefulWidget {
  const ProduccionFormularioPantalla({super.key, this.pedidoIdInicial});
  final String? pedidoIdInicial;

  @override
  ConsumerState<ProduccionFormularioPantalla> createState() =>
      _ProduccionFormularioPantallaState();
}

class _RenglonConsumo {
  Insumo? insumo;
  int? cantidad;
}

class _ProduccionFormularioPantallaState
    extends ConsumerState<ProduccionFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  String? _productoId;
  String _descripcion = '';
  int _descripcionVersion = 0;
  int _cantidad = 1;
  String? _pedidoId;
  String _notas = '';
  final List<_RenglonConsumo> _consumos = [];

  @override
  void initState() {
    super.initState();
    _fecha = DateTime.now();
    _pedidoId = widget.pedidoIdInicial;
  }

  @override
  void didUpdateWidget(covariant ProduccionFormularioPantalla oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pedidoIdInicial != widget.pedidoIdInicial &&
        _pedidoId == null) {
      _pedidoId = widget.pedidoIdInicial;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final consumosDatos = <ConsumoDatos>[];
    for (final item in _consumos) {
      if (item.insumo == null || item.cantidad == null || item.cantidad! <= 0) {
        throw const ErrorDeNegocio(
          'Completá los datos de los insumos utilizados.',
        );
      }
      consumosDatos.add(
        ConsumoDatos(insumoId: item.insumo!.id, cantidad: item.cantidad!),
      );
    }

    final datos = ProduccionDatos(
      fecha: _fecha,
      productoId: _productoId,
      descripcion: _descripcion.trim(),
      cantidad: _cantidad,
      pedidoId: _pedidoId,
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
      consumos: consumosDatos,
    );

    await ref.read(produccionRepositorioProvider).registrar(datos);
    if (mounted) {
      mostrarExito(context, 'Producción registrada');
      context.pop();
    }
  }

  Widget _construirRenglonConsumo(int index) {
    final item = _consumos[index];
    return Card(
      key: ObjectKey(item),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectorInsumo(
                    insumoId: item.insumo?.id,
                    obligatorio: true,
                    excluir: {
                      for (var j = 0; j < _consumos.length; j++)
                        if (j != index && _consumos[j].insumo != null)
                          _consumos[j].insumo!.id,
                    },
                    onChanged: (nuevoInsumo) {
                      setState(() {
                        item.insumo = nuevoInsumo;
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _consumos.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            if (item.insumo != null) ...[
              Separacion.chica,
              CampoCantidad(
                key: ValueKey(
                  'cant_${identityHashCode(item)}_${item.insumo!.id}',
                ),
                etiqueta: 'Cantidad consumida',
                unidad: item.insumo!.unidad,
                valorInicial: item.cantidad,
                obligatorio: true,
                permitirCero: false,
                onChanged: (c) => item.cantidad = c,
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
      titulo: 'Registrar producción',
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
          SelectorProducto(
            productoId: _productoId,
            onChanged: (producto) {
              setState(() {
                _productoId = producto?.id;
                if (_descripcion.trim().isEmpty && producto != null) {
                  _descripcion = producto.nombre;
                  _descripcionVersion++;
                }
              });
            },
          ),
          CampoTexto(
            key: ValueKey('desc_$_descripcionVersion'),
            etiqueta: 'Qué se produjo',
            valorInicial: _descripcion,
            obligatorio: true,
            icono: Icons.bakery_dining_outlined,
            onChanged: (v) => _descripcion = v,
          ),
          CampoEntero(
            etiqueta: 'Cantidad producida',
            valorInicial: _cantidad,
            minimo: 1,
            obligatorio: true,
            onChanged: (v) => _cantidad = v ?? 1,
          ),
          SelectorPedido(
            pedidoId: _pedidoId,
            onChanged: (p) => setState(() => _pedidoId = p?.pedido.id),
          ),
          TarjetaSeccion(
            titulo: 'Insumos utilizados (opcional)',
            children: [
              for (var i = 0; i < _consumos.length; i++) ...[
                if (i > 0) Separacion.chica,
                _construirRenglonConsumo(i),
              ],
              Separacion.chica,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _consumos.add(_RenglonConsumo());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar insumo utilizado'),
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
          texto: 'Registrar producción',
          onGuardar: _guardar,
        ),
      ),
    );
  }
}
