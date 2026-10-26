class ErrorDeNegocio implements Exception {
  const ErrorDeNegocio(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class SinConexion implements Exception {
  const SinConexion([
    this.mensaje = 'Necesitás conexión a internet para realizar esta acción.',
  ]);
  final String mensaje;

  @override
  String toString() => mensaje;
}
