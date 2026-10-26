import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reglas de arquitectura (AGENTS.md)', () {
    final dirFeatures = Directory('lib/features');

    test('Las pantallas en lib/features cumplen las restricciones de AGENTS.md', () {
      expect(dirFeatures.existsSync(), isTrue);

      final archivos = dirFeatures
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(archivos, isNotEmpty);

      final patronImport = RegExp(r"^import\s+'([^']+)';", multiLine: true);
      final patronDineroDouble = RegExp(
        r'\bdouble\??\s+\w*(monto|precio|saldo|total|sena|descuento|costo)\w*\b',
        caseSensitive: false,
      );

      for (final archivo in archivos) {
        final rutaRelativa = archivo.path.replaceAll(r'\', '/');
        final partes = rutaRelativa.split('/');
        // lib/features/<modulo>/...
        final idxFeatures = partes.indexOf('features');
        final moduloActual = partes[idxFeatures + 1];
        final contenido = archivo.readAsStringSync();

        for (final match in patronImport.allMatches(contenido)) {
          final uri = match.group(1)!;
          expect(
            uri.contains('supabase_flutter') ||
                uri.contains('powersync') ||
                uri.contains('sqlite3'),
            isFalse,
            reason:
                '$rutaRelativa importa "$uri" (prohibido llamar a Supabase/PowerSync/SQLite desde features/).',
          );

          if (uri.startsWith('package:jereposteria/features/')) {
            final resto = uri.substring(
              'package:jereposteria/features/'.length,
            );
            final otroModulo = resto.split('/').first;
            expect(
              otroModulo,
              equals(moduloActual),
              reason: '$rutaRelativa importa otro módulo de features ($uri).',
            );
          }
        }

        expect(
          contenido.contains('Scaffold('),
          isFalse,
          reason:
              '$rutaRelativa usa Scaffold directo en lugar de PantallaBase.',
        );

        expect(
          contenido.contains('Colors.'),
          isFalse,
          reason:
              '$rutaRelativa usa Colors.xxx directo en lugar del tema o ColorEstado.',
        );

        expect(
          patronDineroDouble.hasMatch(contenido),
          isFalse,
          reason:
              '$rutaRelativa declara montos/precios/saldos con double en lugar de Dinero.',
        );
      }
    });
  });
}
