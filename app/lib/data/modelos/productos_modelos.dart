import 'package:flutter/foundation.dart';
import 'package:jereposteria/compartido/tipos/dinero.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';

@immutable
class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    this.categoria = CategoriaProducto.torta,
    this.precioBase,
    this.descripcion,
    this.archivadoEn,
  });

  final String id;
  final String nombre;
  final CategoriaProducto categoria;
  final Dinero? precioBase;
  final String? descripcion;
  final DateTime? archivadoEn;

  bool get archivado => archivadoEn != null;
}

class ProductoDatos {
  ProductoDatos({
    required this.nombre,
    this.categoria = CategoriaProducto.torta,
    this.precioBase,
    this.descripcion,
  });

  factory ProductoDatos.desde(Producto p) => ProductoDatos(
    nombre: p.nombre,
    categoria: p.categoria,
    precioBase: p.precioBase,
    descripcion: p.descripcion,
  );

  final String nombre;
  final CategoriaProducto categoria;
  final Dinero? precioBase;
  final String? descripcion;
}

@immutable
class FiltroProductos {
  const FiltroProductos({this.busqueda = '', this.categoria});

  final String busqueda;
  final CategoriaProducto? categoria;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiltroProductos &&
          other.busqueda == busqueda &&
          other.categoria == categoria);

  @override
  int get hashCode => Object.hash(busqueda, categoria);
}
