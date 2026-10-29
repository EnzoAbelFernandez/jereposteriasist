// El constructor del SDK permite fabricar estados de conexión para estas pruebas.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jereposteria/core/sync/sincronizacion_directa.dart';
import 'package:jereposteria/core/sync/supabase_connector.dart';
import 'package:jereposteria/data/data.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _BaseDePrueba extends Fake implements PowerSyncDatabase {
  CrudTransaction? transaction;

  @override
  Future<CrudTransaction?> getNextCrudTransaction() async => transaction;
}

void main() {
  const uid = '00000000-0000-4000-8000-000000000099';

  Map<String, dynamic> respuestaDeLogin({int vigencia = 3600}) {
    final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + vigencia;
    String segmento(Map<String, dynamic> valor) =>
        base64Url.encode(utf8.encode(jsonEncode(valor))).replaceAll('=', '');
    return {
      'access_token':
          '${segmento({'alg': 'HS256'})}.${segmento({'sub': uid, 'exp': exp})}.firma',
      'token_type': 'bearer',
      'expires_in': 3600,
      'refresh_token': 'refresh-de-prueba',
      'user': {
        'id': uid,
        'aud': 'authenticated',
        'email': 'prueba@example.com',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': {},
        'user_metadata': {},
      },
    };
  }

  group('Autenticación y cola de subida', () {
    late HttpServer server;
    late SupabaseClient client;
    late int statusCode;
    late Map<String, dynamic> respuesta;
    late List<String> rutas;
    late List<Map<String, dynamic>> perfilesRemotos;
    late List<Map<String, dynamic>> permisosRemotos;
    late List<Map<String, dynamic>> cuerpos;
    Completer<void>? produccionRecibida;
    Completer<void>? permitirProduccion;

    setUp(() async {
      statusCode = 200;
      respuesta = {};
      rutas = [];
      perfilesRemotos = [];
      permisosRemotos = [];
      cuerpos = [];
      produccionRecibida = null;
      permitirProduccion = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        rutas.add(request.uri.path);
        final cuerpo = await utf8.decoder.bind(request).join();
        if (cuerpo.isNotEmpty) {
          cuerpos.add(jsonDecode(cuerpo) as Map<String, dynamic>);
        }
        if (request.uri.path == '/rest/v1/producciones' &&
            permitirProduccion != null) {
          produccionRecibida!.complete();
          await permitirProduccion!.future;
        }
        request.response
          ..statusCode = statusCode
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(switch (request.uri.path) {
              '/rest/v1/perfiles' => perfilesRemotos,
              '/rest/v1/permisos' => permisosRemotos,
              _ => respuesta,
            }),
          );
        await request.response.close();
      });
      client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'clave-publica-de-prueba',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
    });

    tearDown(() async {
      await client.dispose();
      await server.close(force: true);
    });

    test('renueva un token por vencer antes de conectar PowerSync', () async {
      respuesta = respuestaDeLogin(vigencia: 5);
      await client.auth.signInWithPassword(
        email: 'prueba@example.com',
        password: 'clave',
      );
      final tokenAnterior = client.auth.currentSession!.accessToken;
      respuesta = respuestaDeLogin();
      final connector = SupabasePowerSyncConnector(
        supabase: client,
        powersyncUrl: 'https://powersync.example.com',
      );
      final credenciales = await connector.fetchCredentials();
      expect(credenciales, isNotNull);
      expect(credenciales!.token, isNot(tokenAnterior));
      expect(rutas.where((ruta) => ruta == '/auth/v1/token').length, 2);
    });

    test('intenta el login aunque PowerSync figure desconectado', () async {
      respuesta = respuestaDeLogin();
      final almacen = AlmacenLocal(db: _BaseDePrueba())
        ..usuarioActualId = null
        ..conectadoAInternet = false;
      addTearDown(almacen.dispose);

      await SesionController(almacen, supabase: client).iniciarSesion(
        email: 'prueba@example.com',
        password: 'password-de-prueba',
      );

      expect(rutas, contains('/auth/v1/token'));
      expect(client.auth.currentSession?.user.id, uid);
      expect(almacen.usuarioActualId, uid);
      expect(almacen.perfiles[uid], isNull);
      expect(almacen.permisos[uid], isEmpty);
    });

    for (final rol in ['jefe', 'empleado']) {
      test(
        'carga el perfil real $rol aunque PowerSync no esté conectado',
        () async {
          respuesta = respuestaDeLogin();
          perfilesRemotos = [
            {'id': uid, 'nombre': 'Usuario real', 'rol': rol, 'activo': true},
          ];
          permisosRemotos = [
            {'perfil_id': uid, 'modulo': 'stock', 'nivel': 'ver'},
          ];
          final almacen = AlmacenLocal(db: _BaseDePrueba())
            ..usuarioActualId = null
            ..conectadoAInternet = false;
          addTearDown(almacen.dispose);
          await SesionController(almacen, supabase: client).iniciarSesion(
            email: 'prueba@example.com',
            password: 'password-de-prueba',
          );
          expect(almacen.perfiles[uid]?.esJefe, rol == 'jefe');
          expect(almacen.permisos[uid], {Modulo.stock: NivelPermiso.ver});
          expect(
            rutas,
            containsAll(['/rest/v1/perfiles', '/rest/v1/permisos']),
          );
        },
      );
    }

    test(
      'reemplaza permisos revocados y no inventa un perfil faltante',
      () async {
        respuesta = respuestaDeLogin();
        await client.auth.signInWithPassword(
          email: 'prueba@example.com',
          password: 'password-de-prueba',
        );
        final almacen = AlmacenLocal()..usuarioActualId = uid;
        almacen.perfiles[uid] = const Perfil(
          id: uid,
          nombre: 'Viejo',
          rol: Rol.jefe,
          activo: true,
        );
        almacen.permisos[uid] = {Modulo.stock: NivelPermiso.editar};
        addTearDown(almacen.dispose);
        await SincronizacionDirectaSupabase.cargarAcceso(almacen, client);
        expect(almacen.perfiles[uid], isNull);
        expect(almacen.permisos[uid], isEmpty);
      },
    );

    test('un login rechazado no entra como jefe local', () async {
      statusCode = 400;
      respuesta = {
        'msg': 'Credenciales inválidas',
        'code': 'invalid_credentials',
      };
      final almacen = AlmacenLocal()
        ..usuarioActualId = null
        ..conectadoAInternet = false;
      addTearDown(almacen.dispose);

      await expectLater(
        SesionController(
          almacen,
          supabase: client,
        ).iniciarSesion(email: 'prueba@example.com', password: 'incorrecta'),
        throwsA(isA<ErrorDeNegocio>()),
      );

      expect(rutas, contains('/auth/v1/token'));
      expect(almacen.usuarioActualId, isNull);
      expect(client.auth.currentSession, isNull);
    });

    test(
      'confirma el cumpleaños antes de reemplazar al cliente local',
      () async {
        respuesta = respuestaDeLogin();
        await client.auth.signInWithPassword(
          email: 'prueba@example.com',
          password: 'password-de-prueba',
        );
        respuesta = {'id': uid};
        final almacen = AlmacenLocal(
          onSincronizarDirecto: (tabla, datos) =>
              SincronizacionDirectaSupabase.guardar(client, tabla, datos),
        )..usuarioActualId = uid;
        addTearDown(almacen.dispose);
        almacen.clientes[uid] = Cliente(
          id: uid,
          nombre: 'enzo',
          creadoEn: DateTime(2026),
        );
        final container = ProviderContainer(
          overrides: [almacenLocalProvider.overrideWithValue(almacen)],
        );
        addTearDown(container.dispose);
        final repo = container.read(clientesRepositorioProvider);

        await repo.actualizar(
          uid,
          ClienteDatos(
            nombre: 'enzo',
            cumpleDia: 12,
            cumpleMes: 3,
            cumpleAnio: 1998,
          ),
        );
        expect(almacen.clientes[uid]?.cumpleDia, 12);
        expect(cuerpos.last['cumple_dia'], 12);
        expect(cuerpos.last['cumple_mes'], 3);
        expect(cuerpos.last['cumple_anio'], 1998);

        statusCode = 403;
        respuesta = {'code': '42501', 'message': 'Permiso rechazado'};
        await expectLater(
          repo.actualizar(
            uid,
            ClienteDatos(nombre: 'enzo', cumpleDia: 20, cumpleMes: 7),
          ),
          throwsA(
            isA<ErrorDeNegocio>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('42501'),
            ),
          ),
        );
        expect(almacen.clientes[uid]?.cumpleDia, 12);
        expect(almacen.clientes[uid]?.cumpleMes, 3);
      },
    );

    test(
      'no consume harina hasta confirmar producción y movimiento en orden',
      () async {
        respuesta = respuestaDeLogin();
        await client.auth.signInWithPassword(
          email: 'prueba@example.com',
          password: 'password-de-prueba',
        );
        respuesta = {'id': uid};
        final almacen = AlmacenLocal(
          onSincronizarDirecto: (tabla, datos) =>
              SincronizacionDirectaSupabase.guardar(client, tabla, datos),
        )..usuarioActualId = uid;
        addTearDown(almacen.dispose);
        almacen.insumos[uid] = const Insumo(
          id: uid,
          nombre: 'harina',
          unidad: Unidad.gramos,
        );
        almacen.movimientosStock['inicial'] = MovimientoStock(
          id: 'inicial',
          insumoId: uid,
          fecha: DateTime(2026),
          cantidad: 12000,
          tipo: TipoMovimientoStock.inicial,
        );
        final container = ProviderContainer(
          overrides: [almacenLocalProvider.overrideWithValue(almacen)],
        );
        addTearDown(container.dispose);
        final repo = container.read(produccionRepositorioProvider);
        final datos = ProduccionDatos(
          fecha: DateTime(2026),
          descripcion: 'Prueba',
          consumos: [ConsumoDatos(insumoId: uid, cantidad: 3000)],
        );
        statusCode = 403;
        respuesta = {'code': '42501', 'message': 'Permiso rechazado'};
        await expectLater(
          repo.registrar(datos),
          throwsA(isA<ErrorDeNegocio>()),
        );
        expect(almacen.producciones, isEmpty);
        expect(almacen.stockDe(uid), 12000);
        expect(rutas, isNot(contains('/rest/v1/movimientos_stock')));

        statusCode = 200;
        respuesta = {'id': uid};
        permitirProduccion = Completer<void>();
        produccionRecibida = Completer<void>();
        final guardado = repo.registrar(datos);
        await produccionRecibida!.future;
        expect(rutas, isNot(contains('/rest/v1/movimientos_stock')));
        expect(almacen.stockDe(uid), 12000);
        permitirProduccion!.complete();
        final id = await guardado;
        expect(rutas.last, '/rest/v1/movimientos_stock');
        expect(cuerpos.last['produccion_id'], id);
        expect(cuerpos.last['cantidad'], -3000);
        expect(almacen.stockDe(uid), 9000);
      },
    );

    test(
      'recupera alerta local de stock sin descartar otras operaciones',
      () async {
        var completada = false;
        final clave = 'stock_bajo:$uid:2026-10-29';
        final db = _BaseDePrueba()
          ..transaction = CrudTransaction(
            transactionId: 1,
            crud: [
              CrudEntry(1, UpdateType.put, 'alertas', clave, 1, {
                'tipo': 'stock_bajo',
                'clave': clave,
                'leida_en': null,
              }),
              CrudEntry(2, UpdateType.put, 'clientes', uid, 1, {
                'nombre': 'Ana',
              }),
            ],
            complete: ({String? writeCheckpoint}) async {
              completada = true;
            },
          );
        final connector = SupabasePowerSyncConnector(
          supabase: client,
          powersyncUrl: 'http://127.0.0.1:${server.port}',
        );
        await connector.uploadData(db);
        expect(completada, isTrue);
        expect(rutas, ['/rest/v1/clientes']);
        expect(cuerpos.single['nombre'], 'Ana');
      },
    );

    test('sincroniza una alerta anterior solo como lectura', () async {
      respuesta = {'id': uid};
      var completada = false;
      final db = _BaseDePrueba()
        ..transaction = CrudTransaction(
          transactionId: 1,
          crud: [
            CrudEntry(1, UpdateType.put, 'alertas', uid, 1, {
              'titulo': 'Alerta',
              'leida_en': '2026-10-29T12:00:00Z',
            }),
          ],
          complete: ({String? writeCheckpoint}) async {
            completada = true;
          },
        );
      final connector = SupabasePowerSyncConnector(
        supabase: client,
        powersyncUrl: 'http://127.0.0.1:${server.port}',
      );
      await connector.uploadData(db);
      expect(completada, isTrue);
      expect(cuerpos.single, {'leida_en': '2026-10-29T12:00:00Z'});
    });

    test(
      'conserva en cola una alerta antigua que no puede verificarse',
      () async {
        var completada = false;
        final db = _BaseDePrueba()
          ..transaction = CrudTransaction(
            transactionId: 1,
            crud: [
              CrudEntry(1, UpdateType.put, 'alertas', uid, 1, {
                'titulo': 'Alerta',
              }),
            ],
            complete: ({String? writeCheckpoint}) async {
              completada = true;
            },
          );
        final connector = SupabasePowerSyncConnector(
          supabase: client,
          powersyncUrl: 'http://127.0.0.1:${server.port}',
        );
        await expectLater(
          connector.uploadData(db),
          throwsA(isA<AuthException>()),
        );
        expect(completada, isFalse);
      },
    );

    test('la vía directa sin sesión rechaza el guardado', () async {
      await expectLater(
        SincronizacionDirectaSupabase.guardar(client, 'clientes', {'id': uid}),
        throwsA(isA<ErrorDeNegocio>()),
      );
      expect(rutas, isEmpty);
    });

    test(
      'reintenta pedidos antiguos sin enviar su número local duplicado',
      () async {
        var completada = false;
        final datosAntiguos = <String, dynamic>{'numero': 1, 'cliente_id': uid};
        final db = _BaseDePrueba()
          ..transaction = CrudTransaction(
            transactionId: 1,
            crud: [
              CrudEntry(1, UpdateType.put, 'pedidos', uid, 1, datosAntiguos),
            ],
            complete: ({String? writeCheckpoint}) async {
              completada = true;
            },
          );
        final connector = SupabasePowerSyncConnector(
          supabase: client,
          powersyncUrl: 'http://127.0.0.1:${server.port}',
        );
        await connector.uploadData(db);
        expect(completada, isTrue);
        expect(cuerpos.single.containsKey('numero'), isFalse);
        expect(cuerpos.single['id'], uid);
        expect(cuerpos.single['cliente_id'], uid);
        expect(datosAntiguos['numero'], 1);
        completada = false;
        await connector.uploadData(db);
        expect(completada, isTrue);
        expect(cuerpos.last.containsKey('numero'), isFalse);
        expect(cuerpos.last['id'], uid);

        db.transaction = CrudTransaction(
          transactionId: 2,
          crud: [
            CrudEntry(2, UpdateType.patch, 'pedidos', uid, 2, {
              'numero': 1,
              'notas': 'Cambio',
            }),
          ],
          complete: ({String? writeCheckpoint}) async {},
        );
        await connector.uploadData(db);
        expect(cuerpos.last, {'notas': 'Cambio'});
      },
    );

    test('Desktop tampoco envía número de pedido, incluso si llega de una versión anterior', () async {
      respuesta = respuestaDeLogin();
      await client.auth.signInWithPassword(
        email: 'prueba@example.com',
        password: 'password-de-prueba',
      );
      respuesta = {'id': uid};
      await SincronizacionDirectaSupabase.guardar(client, 'pedidos', {
        'id': uid,
        'numero': 1,
        'cliente_id': uid,
      });
      expect(cuerpos.last.containsKey('numero'), isFalse);
      expect(cuerpos.last['id'], uid);
    });

    test(
      'un pedido nuevo permanece sin numeración hasta que responda el servidor',
      () async {
        final almacen = AlmacenLocal();
        addTearDown(almacen.dispose);
        almacen.clientes[uid] = Cliente(
          id: uid,
          nombre: 'César',
          creadoEn: DateTime(2026),
        );
        final container = ProviderContainer(
          overrides: [almacenLocalProvider.overrideWithValue(almacen)],
        );
        addTearDown(container.dispose);
        final id = await container
            .read(pedidosRepositorioProvider)
            .crear(
              PedidoDatos(
                clienteId: uid,
                fechaEntrega: DateTime(2026, 12),
                items: [
                  PedidoItemDatos(
                    descripcion: 'Torta',
                    cantidad: 1,
                    precioUnitario: const Dinero(10000),
                  ),
                ],
              ),
            );
        expect(almacen.pedidos[id]?.numero, isNull);
        expect(almacen.pedidos[id]?.numeroTexto, 'Nº pendiente');
      },
    );

    for (final code in ['42501', '23503', 'P0001']) {
      test(
        'rechazo $code conserva la transacción hasta una subida exitosa',
        () async {
          statusCode = 403;
          respuesta = {'code': code, 'message': 'Escritura rechazada'};
          var completada = false;
          final db = _BaseDePrueba()
            ..transaction = CrudTransaction(
              transactionId: 1,
              crud: [
                CrudEntry(1, UpdateType.put, 'clientes', uid, 1, {
                  'nombre': 'Cliente de prueba',
                }),
              ],
              complete: ({String? writeCheckpoint}) async {
                completada = true;
              },
            );
          final connector = SupabasePowerSyncConnector(
            supabase: client,
            powersyncUrl: 'http://127.0.0.1:${server.port}',
          );

          await expectLater(
            connector.uploadData(db),
            throwsA(
              isA<ErrorSubidaSync>()
                  .having((e) => e.tabla, 'tabla', 'clientes')
                  .having((e) => e.codigo, 'codigo', code),
            ),
          );
          expect(completada, isFalse);

          statusCode = 201;
          respuesta = {};
          await connector.uploadData(db);
          expect(completada, isTrue);
          expect(
            rutas.where((ruta) => ruta == '/rest/v1/clientes'),
            hasLength(2),
          );
        },
      );
    }
  });

  group('Estado de sincronización', () {
    test(
      'muestra la tabla y el código de subida sin exponer datos del registro',
      () {
        final estado = EstadoSync.desdePowerSync(
          const SyncStatus(
            uploadError: ErrorSubidaSync(
              tabla: 'clientes',
              operacion: 'put',
              codigo: '42501',
            ),
          ),
          cambiosPendientes: 2,
          sesionIniciada: true,
        );
        expect(estado.detalle, contains('Tabla: clientes'));
        expect(estado.detalle, contains('42501'));
        expect(estado.detalle, contains('Operaciones pendientes: 2'));
        expect(estado.alDia, isFalse);
      },
    );
    test(
      'el modo web no confunde la ausencia intencional de SQLite con un fallo',
      () {
        const web = EstadoSync(baseDisponible: false, modoWeb: true);
        expect(web.tieneError, isFalse);
        expect(web.textoEstado, 'Modo web');
        expect(web.detalle, contains('Necesitás conexión para guardar'));
        expect(web.alDia, isFalse);
        expect(web.ultimaSync, isNull);
        const nativo = EstadoSync(baseDisponible: false);
        expect(nativo.tieneError, isTrue);
        expect(nativo.textoEstado, 'Sin base local');
        const sinSesion = EstadoSync(
          baseDisponible: false,
          modoWeb: true,
          sesionIniciada: false,
        );
        expect(sinSesion.textoEstado, 'Sin sesión');
        const errorWeb = EstadoSync(
          baseDisponible: false,
          modoWeb: true,
          error: 'Error',
        );
        expect(errorWeb.tieneError, isTrue);
        expect(errorWeb.textoEstado, 'Error de sincronización');
      },
    );
    test(
      'un 401 conserva su causa y no inventa una fecha de sincronización',
      () {
        final estado = EstadoSync.desdePowerSync(
          const SyncStatus(downloadError: '401 PSYNC_S2101'),
          cambiosPendientes: 3,
          sesionIniciada: true,
        );
        expect(estado.conectado, isFalse);
        expect(estado.alDia, isFalse);
        expect(estado.ultimaSync, isNull);
        expect(estado.cambiosPendientes, 3);
        expect(estado.detalle, contains('PSYNC_S2101'));
      },
    );

    test('Al día exige descarga previa, cola vacía y ausencia de errores', () {
      final fecha = DateTime.utc(2026, 10, 27);
      for (final status in [
        SyncStatus(connected: true),
        SyncStatus(
          connected: true,
          hasSynced: true,
          lastSyncedAt: fecha,
          uploading: true,
        ),
        SyncStatus(
          connected: true,
          hasSynced: true,
          lastSyncedAt: fecha,
          downloading: true,
        ),
        SyncStatus(
          connected: true,
          hasSynced: true,
          lastSyncedAt: fecha,
          uploadError: '42501',
        ),
      ]) {
        expect(
          EstadoSync.desdePowerSync(
            status,
            cambiosPendientes: 0,
            sesionIniciada: true,
          ).alDia,
          isFalse,
        );
      }
      final completo = SyncStatus(
        connected: true,
        hasSynced: true,
        lastSyncedAt: fecha,
      );
      for (final pendientes in [null, 1, 7]) {
        expect(
          EstadoSync.desdePowerSync(
            completo,
            cambiosPendientes: pendientes,
            sesionIniciada: true,
          ).alDia,
          isFalse,
        );
      }
      expect(
        EstadoSync.desdePowerSync(
          completo,
          cambiosPendientes: 0,
          sesionIniciada: true,
        ).alDia,
        isTrue,
      );
      expect(
        EstadoSync.desdePowerSync(
          completo,
          cambiosPendientes: 0,
          sesionIniciada: false,
        ).alDia,
        isFalse,
      );
    });

    test(
      'sin base no afirma conexión aunque la variable de internet sea true',
      () async {
        final almacen = AlmacenLocal()..conectadoAInternet = true;
        addTearDown(almacen.dispose);
        final container = ProviderContainer(
          overrides: [almacenLocalProvider.overrideWithValue(almacen)],
        );
        addTearDown(container.dispose);
        final sub = container.listen(estadoSyncProvider, (_, _) {});
        addTearDown(sub.close);
        final estado = await container.read(estadoSyncProvider.future);
        expect(estado.baseDisponible, isFalse);
        expect(estado.alDia, isFalse);
        expect(estado.ultimaSync, isNull);
      },
    );

    test('un perfil ausente no concede permisos de jefe', () async {
      final almacen = AlmacenLocal()..usuarioActualId = uid;
      addTearDown(almacen.dispose);
      final container = ProviderContainer(
        overrides: [almacenLocalProvider.overrideWithValue(almacen)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(permisosActualesProvider, (_, _) {});
      addTearDown(sub.close);
      final perfilSub = container.listen(perfilActualProvider, (_, _) {});
      addTearDown(perfilSub.close);
      await container.read(perfilActualProvider.future);
      expect(container.read(permisosActualesProvider).esJefe, isFalse);
      expect(
        container
            .read(permisosActualesProvider)
            .puede(Modulo.stock, NivelPermiso.editar),
        isFalse,
      );
    });
  });
}
