import 'package:flutter/foundation.dart';

/// Representa un monto en dinero usando siempre **centavos enteros**.
///
/// Nunca usar `double` para montos, precios, saldos ni totales.
@immutable
class Dinero implements Comparable<Dinero> {
  const Dinero(this.centavos);

  /// Crea un [Dinero] a partir de pesos enteros (`Dinero.pesos(1500) == Dinero(150000)`).
  factory Dinero.pesos(int pesos) => Dinero(pesos * 100);

  final int centavos;

  static const Dinero cero = Dinero(0);

  bool get esCero => centavos == 0;
  bool get esPositivo => centavos > 0;
  bool get esNegativo => centavos < 0;

  Dinero operator +(Dinero otro) => Dinero(centavos + otro.centavos);
  Dinero operator -(Dinero otro) => Dinero(centavos - otro.centavos);
  Dinero operator -() => Dinero(-centavos);

  Dinero por(int cantidad) => Dinero(centavos * cantidad);

  bool operator <(Dinero otro) => centavos < otro.centavos;
  bool operator >(Dinero otro) => centavos > otro.centavos;
  bool operator <=(Dinero otro) => centavos <= otro.centavos;
  bool operator >=(Dinero otro) => centavos >= otro.centavos;

  /// Parsea cadenas como `"15000"`, `"15.000"`, `"15.000,50"`, `"$ 1.500"`.
  /// Devuelve `null` si el texto no es un monto válido.
  static Dinero? parsear(String texto) {
    var limpio = texto.trim().replaceAll(r'$', '').replaceAll(' ', '');
    if (limpio.isEmpty) return null;

    var negativo = false;
    if (limpio.startsWith('-')) {
      negativo = true;
      limpio = limpio.substring(1).trim();
    } else if (limpio.startsWith('+')) {
      limpio = limpio.substring(1).trim();
    }
    if (limpio.isEmpty) return null;

    String parteEntera;
    var parteDecimal = '';

    if (limpio.contains(',')) {
      final partes = limpio.split(',');
      if (partes.length != 2) return null;
      parteEntera = partes[0].replaceAll('.', '');
      parteDecimal = partes[1];
    } else {
      // Si tiene puntos, distinguir separador de miles ("15.000") de decimal ("15.5").
      final partes = limpio.split('.');
      if (partes.length == 1) {
        parteEntera = partes[0];
      } else if (partes.length == 2 && partes[1].length <= 2) {
        parteEntera = partes[0];
        parteDecimal = partes[1];
      } else {
        // Todos los bloques salvo el primero deben tener 3 dígitos (miles).
        final milesValidos = partes.skip(1).every((p) => p.length == 3);
        if (!milesValidos) return null;
        parteEntera = partes.join();
      }
    }

    if (parteEntera.isEmpty) parteEntera = '0';
    if (!RegExp(r'^\d+$').hasMatch(parteEntera)) return null;
    if (parteDecimal.isNotEmpty &&
        !RegExp(r'^\d{1,2}$').hasMatch(parteDecimal)) {
      return null;
    }

    final pesos = int.tryParse(parteEntera);
    if (pesos == null) return null;
    final cent = parteDecimal.isEmpty
        ? 0
        : int.parse(parteDecimal.padRight(2, '0'));
    final total = pesos * 100 + cent;
    return Dinero(negativo ? -total : total);
  }

  /// Formato argentino: `"$ 15.000"`, `"$ 15.000,50"`, `"-$ 200"`.
  String formatear({bool incluirSignoPositivo = false, bool conSigno = false}) {
    final mostrarMas = incluirSignoPositivo || conSigno;
    final abs = centavos.abs();
    final pesos = abs ~/ 100;
    final resto = abs % 100;
    final miles = _conPuntosDeMiles(pesos);
    final dec = resto == 0 ? '' : ',${resto.toString().padLeft(2, '0')}';
    final prefijo = centavos < 0
        ? r'-$ '
        : (mostrarMas && centavos > 0 ? r'+$ ' : r'$ ');
    return '$prefijo$miles$dec';
  }

  /// Formato limpio para precargar un `TextField`: `"15000"` o `"15000,50"`.
  String formatearParaCampo() {
    final abs = centavos.abs();
    final pesos = abs ~/ 100;
    final resto = abs % 100;
    final signo = centavos < 0 ? '-' : '';
    if (resto == 0) return '$signo$pesos';
    return '$signo$pesos,${resto.toString().padLeft(2, '0')}';
  }

  static String _conPuntosDeMiles(int valor) {
    final s = valor.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  int compareTo(Dinero other) => centavos.compareTo(other.centavos);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Dinero && other.centavos == centavos);

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => formatear();
}
