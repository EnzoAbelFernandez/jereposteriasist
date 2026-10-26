/// Unidad base de un insumo.
///
/// Las cantidades se guardan siempre como `int` en la unidad base:
/// gramos (`g`), mililitros (`ml`) o unidades (`u`).
enum Unidad {
  gramos('g', 'Gramos / kilos', 'g', 'kg'),
  mililitros('ml', 'Mililitros / litros', 'ml', 'l'),
  unidades('u', 'Unidades', 'u.', 'u.');

  const Unidad(this.valor, this.etiqueta, this.sufijoBase, this.sufijoMayor);

  final String valor;
  final String etiqueta;
  final String sufijoBase;
  final String sufijoMayor;

  bool get admiteSubmultiplo => this != Unidad.unidades;

  /// Formatea una cantidad en unidad base para mostrar al usuario:
  /// - `gramos`: `500 -> "500 g"`, `2500 -> "2,5 kg"`, `3000 -> "3 kg"`
  /// - `mililitros`: `750 -> "750 ml"`, `1500 -> "1,5 l"`
  /// - `unidades`: `12 -> "12 u."`
  String formatear(int cantidad, {bool conSigno = false}) {
    final prefijo = conSigno && cantidad > 0 ? '+' : '';
    final abs = cantidad.abs();
    final signo = cantidad < 0 ? '-' : prefijo;
    if (this == Unidad.unidades || abs < 1000) {
      return '$signo$abs $sufijoBase';
    }
    final entero = abs ~/ 1000;
    final resto = abs % 1000;
    if (resto == 0) {
      return '$signo$entero $sufijoMayor';
    }
    // Hasta 2 decimales sin ceros finales
    final centesimas = (resto / 10).round();
    if (centesimas == 100) {
      return '$signo${entero + 1} $sufijoMayor';
    }
    var dec = centesimas.toString().padLeft(2, '0');
    if (dec.endsWith('0')) dec = dec.substring(0, 1);
    return '$signo$entero,$dec $sufijoMayor';
  }

  static Unidad desdeValor(String valor) {
    return Unidad.values.firstWhere(
      (u) => u.valor == valor,
      orElse: () => Unidad.unidades,
    );
  }
}
