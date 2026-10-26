import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/tipos/enums.dart';
import 'package:jereposteria/core/sesion/sesion.dart';

class RequierePermiso extends ConsumerWidget {
  const RequierePermiso({
    super.key,
    required this.modulo,
    required this.nivel,
    required this.child,
    this.alternativa,
  });

  final Modulo modulo;
  final NivelPermiso nivel;
  final Widget child;
  final Widget? alternativa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosActualesProvider);
    if (permisos.puede(modulo, nivel)) {
      return child;
    }
    return alternativa ?? const SizedBox.shrink();
  }
}

class SoloJefe extends ConsumerWidget {
  const SoloJefe({super.key, required this.child, this.alternativa});

  final Widget child;
  final Widget? alternativa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permisos = ref.watch(permisosActualesProvider);
    if (permisos.esJefe) {
      return child;
    }
    return alternativa ?? const SizedBox.shrink();
  }
}
