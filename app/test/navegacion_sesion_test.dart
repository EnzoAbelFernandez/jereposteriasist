import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jereposteria/data/data.dart';
import 'package:jereposteria/core/router/router.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/main.dart';

void main() {
  testWidgets('permite cerrar sesión con solo Inicio, Tareas y Alertas', (
    tester,
  ) async {
    final almacen = AlmacenLocal()
      ..usuarioActualId = '00000000-0000-4000-8000-000000000099';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [almacenLocalProvider.overrideWithValue(almacen)],
        child: const JeReposteriaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Más'), findsOneWidget);
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(almacen.usuarioActualId, isNull);
    expect(find.text('Ingresar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    almacen.dispose();
  });

  testWidgets('restringe rutas directas y al revocar permisos', (tester) async {
    const uid = 'empleado-prueba';
    final almacen = AlmacenLocal()..usuarioActualId = uid;
    almacen.perfiles[uid] = Perfil(
      id: uid,
      nombre: 'Empleado',
      rol: Rol.empleado,
    );
    almacen.permisos[uid] = {Modulo.pedidos: NivelPermiso.ver};
    final container = ProviderContainer(
      overrides: [almacenLocalProvider.overrideWithValue(almacen)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const JeReposteriaApp(),
      ),
    );
    await tester.pumpAndSettle();
    final router = container.read(routerProvider);
    router.go(Rutas.clientes);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, Rutas.inicio);
    router.go(Rutas.pedidos);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, Rutas.pedidos);
    almacen.permisos[uid] = {};
    almacen.notificar();
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, Rutas.inicio);
    router.go(Rutas.configuracion);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, Rutas.inicio);
    almacen.permisos[uid] = {Modulo.produccion: NivelPermiso.ver};
    almacen.notificar();
    router.go(Rutas.pedido('pedido-prueba'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      Rutas.pedido('pedido-prueba'),
    );
    router.go(Rutas.pedidos);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, Rutas.inicio);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    almacen.dispose();
  });
}
