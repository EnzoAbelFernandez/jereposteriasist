import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/formato/fechas.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';
import 'package:jereposteria/compartido/widgets/dialogos_widgets.dart';
import 'package:jereposteria/compartido/widgets/estructura_widgets.dart';

class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    this.valorInicial,
    required this.onChanged,
    this.obligatorio = false,
    this.teclado = TextInputType.text,
    this.maxLineas = 1,
    this.validador,
    this.icono,
  });

  final String etiqueta;
  final String? valorInicial;
  final ValueChanged<String> onChanged;
  final bool obligatorio;
  final TextInputType teclado;
  final int maxLineas;
  final String? Function(String)? validador;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: valorInicial,
      keyboardType: teclado,
      maxLines: maxLineas,
      decoration: InputDecoration(
        labelText: obligatorio ? '$etiqueta *' : etiqueta,
        prefixIcon: icono != null ? Icon(icono) : null,
      ),
      onChanged: (v) => onChanged(v.trim()),
      validator: (v) {
        final limpio = (v ?? '').trim();
        if (obligatorio && limpio.isEmpty) {
          return 'Completá este campo.';
        }
        if (validador != null) {
          return validador!(limpio);
        }
        return null;
      },
    );
  }
}

class CampoDinero extends StatelessWidget {
  const CampoDinero({
    super.key,
    required this.etiqueta,
    this.valorInicial,
    required this.onChanged,
    this.obligatorio = false,
    this.permitirCero = false,
  });

  final String etiqueta;
  final Dinero? valorInicial;
  final ValueChanged<Dinero?> onChanged;
  final bool obligatorio;
  final bool permitirCero;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: valorInicial?.formatearParaCampo(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: obligatorio ? '$etiqueta *' : etiqueta,
        prefixText: r'$ ',
      ),
      onChanged: (v) {
        final limpio = v.trim();
        if (limpio.isEmpty) {
          onChanged(null);
          return;
        }
        onChanged(Dinero.parsear(limpio));
      },
      validator: (v) {
        final limpio = (v ?? '').trim();
        if (limpio.isEmpty) {
          return obligatorio ? 'Ingresá un monto.' : null;
        }
        final m = Dinero.parsear(limpio);
        if (m == null) {
          return 'Ingresá un monto válido.';
        }
        if (m.esNegativo || (!permitirCero && m.esCero)) {
          return permitirCero
              ? 'El monto no puede ser negativo.'
              : 'El monto debe ser mayor a cero.';
        }
        return null;
      },
    );
  }
}

class CampoCantidad extends StatefulWidget {
  const CampoCantidad({
    super.key,
    required this.etiqueta,
    required this.unidad,
    this.valorInicial,
    required this.onChanged,
    this.obligatorio = false,
    this.permitirCero = false,
  });

  final String etiqueta;
  final Unidad unidad;
  final int? valorInicial;
  final ValueChanged<int?> onChanged;
  final bool obligatorio;
  final bool permitirCero;

  @override
  State<CampoCantidad> createState() => _CampoCantidadState();
}

class _CampoCantidadState extends State<CampoCantidad> {
  late final TextEditingController _controller;
  bool _usarMayor = false;

  @override
  void initState() {
    super.initState();
    final inicial = widget.valorInicial;
    if (inicial != null &&
        widget.unidad.admiteSubmultiplo &&
        inicial >= 1000 &&
        inicial % 1000 == 0) {
      _usarMayor = true;
      _controller = TextEditingController(text: (inicial ~/ 1000).toString());
    } else {
      _controller = TextEditingController(
        text: inicial != null ? inicial.toString() : '',
      );
    }
  }

  @override
  void didUpdateWidget(covariant CampoCantidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unidad != widget.unidad && !widget.unidad.admiteSubmultiplo) {
      _usarMayor = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _calcularBase(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    if (!_usarMayor || !widget.unidad.admiteSubmultiplo) {
      return int.tryParse(limpio);
    }
    final partes = limpio.split('.');
    if (partes.length > 2) return null;
    final entero = int.tryParse(partes[0].isEmpty ? '0' : partes[0]);
    if (entero == null) return null;
    var mil = 0;
    if (partes.length == 2 && partes[1].isNotEmpty) {
      if (partes[1].length > 3) return null;
      final dec = int.tryParse(partes[1].padRight(3, '0'));
      if (dec == null) return null;
      mil = dec;
    }
    return entero * 1000 + mil;
  }

  void _notificar() {
    widget.onChanged(_calcularBase(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final sufijo = _usarMayor && widget.unidad.admiteSubmultiplo
        ? widget.unidad.sufijoMayor
        : widget.unidad.sufijoBase;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: _usarMayor && widget.unidad.admiteSubmultiplo,
            ),
            decoration: InputDecoration(
              labelText: widget.obligatorio
                  ? '${widget.etiqueta} *'
                  : widget.etiqueta,
              suffixText: sufijo,
            ),
            onChanged: (_) => _notificar(),
            validator: (v) {
              final limpio = (v ?? '').trim();
              if (limpio.isEmpty) {
                return widget.obligatorio ? 'Ingresá una cantidad.' : null;
              }
              final base = _calcularBase(limpio);
              if (base == null) {
                return 'Cantidad inválida.';
              }
              if (base < 0 || (!widget.permitirCero && base == 0)) {
                return widget.permitirCero
                    ? 'No puede ser negativa.'
                    : 'Debe ser mayor a cero.';
              }
              return null;
            },
          ),
        ),
        if (widget.unidad.admiteSubmultiplo) ...[
          Separacion.chica,
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(widget.unidad.sufijoBase),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(widget.unidad.sufijoMayor),
                ),
              ],
              selected: {_usarMayor},
              onSelectionChanged: (sel) {
                setState(() => _usarMayor = sel.first);
                _notificar();
              },
            ),
          ),
        ],
      ],
    );
  }
}

class CampoEntero extends StatelessWidget {
  const CampoEntero({
    super.key,
    required this.etiqueta,
    this.valorInicial,
    required this.onChanged,
    this.obligatorio = false,
    this.minimo = 0,
    this.maximo,
  });

  final String etiqueta;
  final int? valorInicial;
  final ValueChanged<int?> onChanged;
  final bool obligatorio;
  final int minimo;
  final int? maximo;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: valorInicial?.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: obligatorio ? '$etiqueta *' : etiqueta,
      ),
      onChanged: (v) => onChanged(int.tryParse(v.trim())),
      validator: (v) {
        final limpio = (v ?? '').trim();
        if (limpio.isEmpty) {
          return obligatorio ? 'Completá este campo.' : null;
        }
        final n = int.tryParse(limpio);
        if (n == null) return 'Ingresá un número entero.';
        if (n < minimo) return 'Debe ser al menos $minimo.';
        if (maximo != null && n > maximo!) return 'Máximo $maximo.';
        return null;
      },
    );
  }
}

class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    this.valor,
    required this.onChanged,
    this.obligatorio = false,
    this.conHora = false,
    this.primera,
    this.ultima,
  });

  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> onChanged;
  final bool obligatorio;
  final bool conHora;
  final DateTime? primera;
  final DateTime? ultima;

  Future<void> _elegir(
    BuildContext context,
    FormFieldState<DateTime?> state,
  ) async {
    final ahora = DateTime.now();
    final inicial = valor ?? ahora;
    final minDate = primera ?? DateTime(ahora.year - 5);
    final maxDate = ultima ?? DateTime(ahora.year + 5);
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(minDate)
          ? minDate
          : (inicial.isAfter(maxDate) ? maxDate : inicial),
      firstDate: minDate,
      lastDate: maxDate,
    );
    if (fecha == null || !context.mounted) return;
    DateTime resultado = DateTime(fecha.year, fecha.month, fecha.day);
    if (conHora) {
      final horaInicial = valor != null
          ? TimeOfDay.fromDateTime(valor!)
          : const TimeOfDay(hour: 12, minute: 0);
      final hora = await showTimePicker(
        context: context,
        initialTime: horaInicial,
      );
      if (hora != null) {
        resultado = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hora.hour,
          hora.minute,
        );
      }
    }
    state.didChange(resultado);
    onChanged(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime?>(
      initialValue: valor,
      validator: (_) {
        if (obligatorio && valor == null) {
          return 'Elegí una fecha.';
        }
        return null;
      },
      builder: (state) {
        final texto = valor == null
            ? ''
            : (conHora ? formatearFechaHora(valor!) : formatearFecha(valor!));
        return InkWell(
          onTap: () => _elegir(context, state),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: obligatorio ? '$etiqueta *' : etiqueta,
              errorText: state.errorText,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              suffixIcon: !obligatorio && valor != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        state.didChange(null);
                        onChanged(null);
                      },
                    )
                  : null,
            ),
            child: Text(
              texto.isEmpty ? 'Seleccionar...' : texto,
              style: texto.isEmpty
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}

class CampoCumpleanos extends StatelessWidget {
  const CampoCumpleanos({
    super.key,
    this.dia,
    this.mes,
    this.anio,
    required this.onChanged,
  });

  final int? dia;
  final int? mes;
  final int? anio;
  final void Function(int? dia, int? mes, int? anio) onChanged;

  static const List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int?>(
            key: ValueKey('dia_$dia'),
            initialValue: dia,
            decoration: const InputDecoration(labelText: 'Día de cumple'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Sin día')),
              for (var d = 1; d <= 31; d++)
                DropdownMenuItem<int?>(value: d, child: Text('$d')),
            ],
            onChanged: (nuevoDia) => onChanged(nuevoDia, mes, anio),
          ),
        ),
        Separacion.chica,
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int?>(
            key: ValueKey('mes_$mes'),
            initialValue: mes,
            decoration: const InputDecoration(labelText: 'Mes de cumple'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Sin mes')),
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem<int?>(value: m, child: Text(_meses[m - 1])),
            ],
            onChanged: (nuevoMes) => onChanged(dia, nuevoMes, anio),
          ),
        ),
        Separacion.chica,
        Expanded(
          child: TextFormField(
            initialValue: anio?.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Año (opc.)'),
            onChanged: (v) => onChanged(dia, mes, int.tryParse(v.trim())),
          ),
        ),
      ],
    );
  }
}

class SelectorOpcion<T> extends StatelessWidget {
  const SelectorOpcion({
    super.key,
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.etiquetaDe,
    required this.onChanged,
    this.obligatorio = false,
  });

  final String etiqueta;
  final List<T> opciones;
  final T? valor;
  final String Function(T) etiquetaDe;
  final ValueChanged<T?> onChanged;
  final bool obligatorio;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey(valor),
      initialValue: valor,
      decoration: InputDecoration(
        labelText: obligatorio ? '$etiqueta *' : etiqueta,
      ),
      items: [
        for (final op in opciones)
          DropdownMenuItem<T>(value: op, child: Text(etiquetaDe(op))),
      ],
      onChanged: onChanged,
      validator: (v) {
        if (obligatorio && v == null) {
          return 'Elegí una opción.';
        }
        return null;
      },
    );
  }
}

class SelectorMedioPago extends StatelessWidget {
  const SelectorMedioPago({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final MedioPago? valor;
  final ValueChanged<MedioPago> onChanged;

  @override
  Widget build(BuildContext context) {
    final seleccionado = valor ?? MedioPago.efectivo;
    return SegmentedButton<MedioPago>(
      segments: [
        for (final mp in MedioPago.values)
          ButtonSegment<MedioPago>(
            value: mp,
            icon: Icon(mp.icono),
            label: Text(mp.etiqueta),
          ),
      ],
      selected: {seleccionado},
      onSelectionChanged: (sel) => onChanged(sel.first),
    );
  }
}

class BotonGuardar extends StatefulWidget {
  const BotonGuardar({
    super.key,
    required this.onGuardar,
    this.texto = 'Guardar',
  });

  final Future<void> Function() onGuardar;
  final String texto;

  @override
  State<BotonGuardar> createState() => _BotonGuardarState();
}

class _BotonGuardarState extends State<BotonGuardar> {
  bool _guardando = false;

  Future<void> _ejecutar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar();
    } catch (e) {
      if (mounted) {
        mostrarError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _guardando ? null : _ejecutar,
      icon: _guardando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(widget.texto),
    );
  }
}
