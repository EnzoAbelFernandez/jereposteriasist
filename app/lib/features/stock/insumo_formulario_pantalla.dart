import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class InsumoFormularioPantalla extends ConsumerStatefulWidget {
  const InsumoFormularioPantalla({super.key, this.id});
  final String? id;

  bool get esEdicion => id != null;

  @override
  ConsumerState<InsumoFormularioPantalla> createState() =>
      _InsumoFormularioPantallaState();
}

class _InsumoFormularioPantallaState
    extends ConsumerState<InsumoFormularioPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _nombre = '';
  Unidad _unidad = Unidad.gramos;
  int _stockMinimo = 0;
  int _stockInicial = 0;
  Dinero? _precioReferencia;
  int? _cantidadReferencia;
  FuenteCostoInsumo _fuenteCosto = FuenteCostoInsumo.ultimaCompra;
  String _categoria = '';
  String _notas = '';

  void _precargar(Insumo i) {
    if (_inicializado) return;
    _inicializado = true;
    _nombre = i.nombre;
    _unidad = i.unidad;
    _stockMinimo = i.stockMinimo;
    _precioReferencia = i.precioReferencia;
    _cantidadReferencia = i.cantidadReferencia;
    _fuenteCosto = i.fuenteCosto;
    _categoria = i.categoria ?? '';
    _notas = i.notas ?? '';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final datos = InsumoDatos(
      nombre: _nombre.trim(),
      unidad: _unidad,
      stockMinimo: _stockMinimo,
      precioReferencia: _precioReferencia,
      cantidadReferencia: _cantidadReferencia,
      fuenteCosto: _fuenteCosto,
      categoria: _categoria.trim().isEmpty ? null : _categoria.trim(),
      notas: _notas.trim().isEmpty ? null : _notas.trim(),
    );
    final repo = ref.read(insumosRepositorioProvider);
    if (widget.esEdicion) {
      await repo.actualizar(widget.id!, datos);
    } else {
      await repo.crear(
        datos,
        stockInicial: _stockInicial > 0 ? _stockInicial : 0,
      );
    }
    if (mounted) {
      mostrarExito(context, 'Insumo guardado');
      context.pop();
    }
  }

  Future<void> _archivar() async {
    final ok = await confirmar(
      context,
      titulo: 'Archivar insumo',
      mensaje: '¿Querés archivar este insumo?',
      textoConfirmar: 'Archivar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(insumosRepositorioProvider).archivar(widget.id!);
      if (mounted) {
        mostrarExito(context, 'Insumo archivado');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        mostrarError(context, e);
      }
    }
  }

  Widget _construirFormulario({InsumoConStock? itemConStock}) {
    return FormularioResponsivo(
      formKey: _formKey,
      campos: [
        if (itemConStock != null)
          TarjetaSeccion(
            titulo: 'Estado del stock',
            icono: Icons.inventory_2_outlined,
            accion: itemConStock.faltante
                ? InsigniaEstado(
                    texto:
                        'Falta ${itemConStock.insumo.unidad.formatear(itemConStock.cantidadFaltante)}',
                    color: ColorEstado.peligro,
                    icono: Icons.warning_amber_rounded,
                  )
                : const InsigniaEstado(
                    texto: 'Stock en nivel normal',
                    color: ColorEstado.exito,
                    icono: Icons.check_circle_outline,
                  ),
            children: [
              FilaDato(
                etiqueta: 'Stock disponible',
                valor: itemConStock.stockTexto,
                icono: Icons.inventory_outlined,
              ),
              FilaDato(
                etiqueta: 'Stock mínimo',
                valor: itemConStock.insumo.stockMinimo > 0
                    ? itemConStock.insumo.unidad.formatear(
                        itemConStock.insumo.stockMinimo,
                      )
                    : 'Sin mínimo configurado',
                icono: Icons.tune_outlined,
              ),
            ],
          ),
        CampoTexto(
          etiqueta: 'Nombre',
          valorInicial: _nombre,
          obligatorio: true,
          icono: Icons.label_outlined,
          onChanged: (v) => _nombre = v,
        ),
        SelectorOpcion<Unidad>(
          etiqueta: 'Unidad de medida',
          opciones: Unidad.values,
          valor: _unidad,
          etiquetaDe: (u) => u.etiqueta,
          obligatorio: true,
          onChanged: (u) {
            if (u != null) {
              setState(() => _unidad = u);
            }
          },
        ),
        CampoCantidad(
          etiqueta: 'Stock mínimo (avisa cuando falte)',
          unidad: _unidad,
          valorInicial: _stockMinimo,
          permitirCero: true,
          onChanged: (v) => _stockMinimo = v ?? 0,
        ),
        if (!widget.esEdicion)
          CampoCantidad(
            etiqueta: 'Stock inicial (opcional)',
            unidad: _unidad,
            valorInicial: _stockInicial,
            permitirCero: true,
            onChanged: (v) => _stockInicial = v ?? 0,
          ),
        SelectorOpcion<FuenteCostoInsumo>(
          etiqueta: 'Precio usado para calcular costos',
          opciones: FuenteCostoInsumo.values,
          valor: _fuenteCosto,
          etiquetaDe: (fuente) => fuente.etiqueta,
          obligatorio: true,
          onChanged: (v) {
            if (v != null) setState(() => _fuenteCosto = v);
          },
        ),
        Text(
          _fuenteCosto == FuenteCostoInsumo.referencia
              ? 'Se usa el precio de referencia. Si falta, el costo queda pendiente.'
              : 'Se usa la última compra. Si no hay compras, el costo queda pendiente.',
        ),
        CampoDinero(
          etiqueta: 'Precio de referencia por presentación (opcional)',
          valorInicial: _precioReferencia,
          onChanged: (v) => _precioReferencia = v,
        ),
        CampoCantidad(
          etiqueta: 'Cantidad de la presentación',
          unidad: _unidad,
          valorInicial: _cantidadReferencia,
          onChanged: (v) => _cantidadReferencia = v,
        ),
        CampoTexto(
          etiqueta: 'Categoría (opcional)',
          valorInicial: _categoria,
          icono: Icons.category_outlined,
          onChanged: (v) => _categoria = v,
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
        texto: widget.esEdicion ? 'Guardar cambios' : 'Crear insumo',
        onGuardar: _guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.esEdicion) {
      return PantallaBase(
        titulo: 'Nuevo insumo',
        cuerpo: _construirFormulario(),
      );
    }

    final asyncInsumo = ref.watch(insumoConStockProvider(widget.id!));
    return PantallaBase(
      titulo: 'Editar insumo',
      acciones: [
        RequierePermiso(
          modulo: Modulo.stock,
          nivel: NivelPermiso.editar,
          child: IconButton(
            tooltip: 'Archivar',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _archivar,
          ),
        ),
      ],
      cuerpo: VistaAsync<InsumoConStock?>(
        valor: asyncInsumo,
        builder: (context, item) {
          _precargar(item!.insumo);
          return _construirFormulario(itemConStock: item);
        },
      ),
    );
  }
}
