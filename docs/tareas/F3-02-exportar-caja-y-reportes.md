# F3-02 – Exportar Caja y Reportes mensuales a CSV

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 2 (`F1-14`, `F2-05`)

## Objetivo
Agregar el botón de **exportar a CSV** en la barra superior (`acciones` de `PantallaBase`) tanto en `CajaPantalla` como en `ReportesPantalla`, mostrando el diálogo compartido `mostrarDialogoExportacion` para copiar o guardar la planilla lista para Excel / Google Sheets.

## Leer antes de empezar
- `AGENTS.md`
- `app/lib/features/caja/caja_pantalla.dart`
- `app/lib/features/reportes/reportes_pantalla.dart`
- `app/lib/compartido/widgets/dialogos_widgets.dart` (`mostrarDialogoExportacion`)

## Alcance de archivos
- **Modificar únicamente:**
  - `app/lib/features/caja/caja_pantalla.dart`
  - `app/lib/features/reportes/reportes_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Métodos y widgets disponibles
- En `cajaRepositorioProvider` (`CajaRepositorio`):
  - `Future<String> exportarCsv(FiltroCaja filtro)`
- En `reportesRepositorioProvider` (`ReportesRepositorio`):
  - `Future<String> exportarResumenCsv(PeriodoMensual periodo)`
- En `package:jereposteria/compartido/compartido.dart`:
  - `Future<void> mostrarDialogoExportacion(BuildContext context, {required String titulo, required String nombreArchivo, required String contenido})`

## Comportamiento esperado

### 1. En `CajaPantalla` (`app/lib/features/caja/caja_pantalla.dart`)
- Agregar en `PantallaBase(titulo: 'Caja', acciones: [...])` un `IconButton`:
  - `tooltip: 'Exportar CSV'`
  - `icon: const Icon(Icons.download_outlined)`
  - Al presionarlo:
    1. Llama a `final csv = await ref.read(cajaRepositorioProvider).exportarCsv(_filtro);`
    2. Si `mounted`, llama a:
       ```dart
       await mostrarDialogoExportacion(
         context,
         titulo: 'Exportar movimientos de caja (CSV)',
         nombreArchivo: 'caja_${_desde.year}_${_desde.month.toString().padLeft(2, '0')}.csv',
         contenido: csv,
       );
       ```

### 2. En `ReportesPantalla` (`app/lib/features/reportes/reportes_pantalla.dart`)
- Agregar en `PantallaBase(titulo: 'Reportes', acciones: [...])` un `IconButton`:
  - `tooltip: 'Exportar reporte CSV'`
  - `icon: const Icon(Icons.download_outlined)`
  - Al presionarlo:
    1. Llama a `final csv = await ref.read(reportesRepositorioProvider).exportarResumenCsv(_periodo);`
    2. Si `mounted`, llama a:
       ```dart
       await mostrarDialogoExportacion(
         context,
         titulo: 'Exportar reporte mensual (CSV)',
         nombreArchivo: 'reporte_${_periodo.anio}_${_periodo.mes.toString().padLeft(2, '0')}.csv',
         contenido: csv,
       );
       ```

## Criterios de aceptación
- [ ] `CajaPantalla` permite exportar los movimientos filtrados actuales a CSV mediante `mostrarDialogoExportacion`.
- [ ] `ReportesPantalla` permite exportar el reporte mensual actual a CSV mediante `mostrarDialogoExportacion`.
- [ ] Sin errores de análisis ni de formato.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/caja/caja_pantalla.dart","app/lib/features/reportes/reportes_pantalla.dart"
```
