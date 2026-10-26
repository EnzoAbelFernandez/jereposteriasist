import 'package:flutter/foundation.dart';

@immutable
class Proveedor {
  const Proveedor({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.notas,
    this.archivadoEn,
  });

  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? notas;
  final DateTime? archivadoEn;

  bool get archivado => archivadoEn != null;
}

class ProveedorDatos {
  ProveedorDatos({required this.nombre, this.telefono, this.email, this.notas});

  factory ProveedorDatos.desde(Proveedor p) => ProveedorDatos(
    nombre: p.nombre,
    telefono: p.telefono,
    email: p.email,
    notas: p.notas,
  );

  final String nombre;
  final String? telefono;
  final String? email;
  final String? notas;
}
