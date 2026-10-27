import 'package:flutter/material.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/compartido/tipos/unidad.dart';

({Color fondo, Color frente}) resolverColorEstado(
  BuildContext context,
  ColorEstado estado,
) {
  final cs = Theme.of(context).colorScheme;
  switch (estado) {
    case ColorEstado.neutro:
      return (fondo: cs.surfaceContainerHighest, frente: cs.onSurfaceVariant);
    case ColorEstado.info:
      return (fondo: cs.secondaryContainer, frente: cs.onSecondaryContainer);
    case ColorEstado.exito:
      return (fondo: cs.tertiaryContainer, frente: cs.onTertiaryContainer);
    case ColorEstado.advertencia:
      return (fondo: cs.primaryContainer, frente: cs.onPrimaryContainer);
    case ColorEstado.peligro:
      return (fondo: cs.errorContainer, frente: cs.onErrorContainer);
  }
}

class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado({
    super.key,
    required this.texto,
    required this.color,
    this.icono,
  });

  final String texto;
  final ColorEstado color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final paleta = resolverColorEstado(context, color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: paleta.fondo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: paleta.frente.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: paleta.frente),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: paleta.frente, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class InsigniaEstadoPedido extends StatelessWidget {
  const InsigniaEstadoPedido(this.estado, {super.key});
  final EstadoPedido estado;

  @override
  Widget build(BuildContext context) {
    return InsigniaEstado(texto: estado.etiqueta, color: estado.color);
  }
}

class InsigniaHabitual extends StatelessWidget {
  const InsigniaHabitual({super.key});

  @override
  Widget build(BuildContext context) {
    return const InsigniaEstado(
      texto: 'Habitual',
      color: ColorEstado.advertencia,
      icono: Icons.star_rounded,
    );
  }
}

class TextoDinero extends StatelessWidget {
  const TextoDinero(
    this.monto, {
    super.key,
    this.colorear = false,
    this.conSigno = false,
    this.estilo,
  });

  final Dinero monto;
  final bool colorear;
  final bool conSigno;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color? colorTexto;
    if (colorear) {
      if (monto.esPositivo) {
        colorTexto = cs.tertiary;
      } else if (monto.esNegativo) {
        colorTexto = cs.error;
      }
    }
    final baseStyle = (estilo ?? Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Text(
      monto.formatear(conSigno: conSigno),
      style: colorTexto != null
          ? baseStyle?.copyWith(color: colorTexto, fontWeight: FontWeight.w600)
          : baseStyle,
    );
  }
}

class TextoCantidad extends StatelessWidget {
  const TextoCantidad(this.cantidad, this.unidad, {super.key, this.estilo});

  final int cantidad;
  final Unidad unidad;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Text(unidad.formatear(cantidad), style: estilo);
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.nombre, {super.key, this.radio = 20});
  final String nombre;
  final double radio;

  String _iniciales(String texto) {
    final partes = texto
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radio,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      child: Text(
        _iniciales(nombre),
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: radio * 0.75),
      ),
    );
  }
}

class TarjetaMetrica extends StatelessWidget {
  const TarjetaMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    this.icono,
    this.color = ColorEstado.neutro,
    this.onTap,
  });

  final String titulo;
  final String valor;
  final IconData? icono;
  final ColorEstado color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final paleta = resolverColorEstado(context, color);
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: paleta.fondo.withValues(alpha: 0.8), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (icono != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: paleta.fondo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: paleta.frente, size: 22),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconoAlerta extends StatelessWidget {
  const IconoAlerta(this.tipo, {super.key});
  final TipoAlerta tipo;

  ColorEstado get _color {
    switch (tipo) {
      case TipoAlerta.cumpleanos:
        return ColorEstado.info;
      case TipoAlerta.stockBajo:
      case TipoAlerta.tareaVencida:
        return ColorEstado.peligro;
      case TipoAlerta.entregaProxima:
        return ColorEstado.advertencia;
      case TipoAlerta.tareaAsignada:
        return ColorEstado.neutro;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paleta = resolverColorEstado(context, _color);
    return CircleAvatar(
      backgroundColor: paleta.fondo,
      foregroundColor: paleta.frente,
      child: Icon(tipo.icono, size: 20),
    );
  }
}
