const List<String> _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const List<String> _diasSemanaLargos = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const List<String> _diasSemanaCortos = [
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom',
];

String _dos(int n) => n.toString().padLeft(2, '0');

/// `"25/10/2026"`
String formatearFecha(DateTime d) {
  final l = d.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}/${l.year}';
}

/// `"25/10"`
String formatearFechaCorta(DateTime d) {
  final l = d.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)}';
}

/// `"25/10/2026 14:30"`
String formatearFechaHora(DateTime d) {
  final l = d.toLocal();
  return '${formatearFecha(l)} ${formatearHora(l)}';
}

/// `"14:30"`
String formatearHora(DateTime d) {
  final l = d.toLocal();
  return '${_dos(l.hour)}:${_dos(l.minute)}';
}

/// `"lunes"`, `"martes"`, ...
String formatearDiaSemana(DateTime d) {
  final l = d.toLocal();
  return _diasSemanaLargos[l.weekday - 1];
}

/// `"octubre 2026"`
String formatearMesAnio(DateTime d) {
  final l = d.toLocal();
  final mes = _mesesLargos[l.month - 1];
  return '${mes[0].toUpperCase()}${mes.substring(1)} ${l.year}';
}

/// `"3 de noviembre"`
String formatearDiaMesLargo(int dia, int mes) {
  if (mes < 1 || mes > 12) return '$dia/$mes';
  return '$dia de ${_mesesLargos[mes - 1]}';
}

/// `"Hoy"`, `"Mañana"`, `"Ayer"`, `"Lun 27/10"`
String formatearFechaRelativa(DateTime d, {DateTime? referencia}) {
  final base = soloFecha(referencia ?? DateTime.now());
  final objetivo = soloFecha(d.toLocal());
  final diff = objetivo.difference(base).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  final diaCorto = _diasSemanaCortos[objetivo.weekday - 1];
  return '$diaCorto ${formatearFechaCorta(objetivo)}';
}

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

/// Hoy a las 00:00 (hora local).
DateTime hoy() => soloFecha(DateTime.now());

DateTime inicioDeMes(DateTime d) => DateTime(d.year, d.month, 1);

DateTime finDeMes(DateTime d) =>
    DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);

bool esMismoDia(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Calcula la fecha del próximo cumpleaños desde [desde] (maneja 29/02 en años no bisiestos).
DateTime proximoCumpleanos({
  required int dia,
  required int mes,
  required DateTime desde,
}) {
  final base = soloFecha(desde);
  var fecha = _fechaCumpleEnAnio(base.year, dia, mes);
  if (fecha.isBefore(base)) {
    fecha = _fechaCumpleEnAnio(base.year + 1, dia, mes);
  }
  return fecha;
}

DateTime _fechaCumpleEnAnio(int anio, int dia, int mes) {
  final ultimoDiaDelMes = DateTime(anio, mes + 1, 0).day;
  final diaAjustado = dia > ultimoDiaDelMes ? ultimoDiaDelMes : dia;
  return DateTime(anio, mes, diaAjustado);
}
