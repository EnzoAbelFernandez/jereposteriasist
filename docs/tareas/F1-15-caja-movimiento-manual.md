# F1-15 – Caja: registrar ingreso o egreso manual

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-14

## Objetivo
Permitir cargar un ingreso o egreso manual de caja (por ejemplo, aporte de cambio, retiro o un ingreso suelto que no viene de un pedido).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.7 Caja**)
- `docs/catalogo-widgets.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/caja/dialogo_movimiento_caja.dart` (crear)
  - `app/lib/features/caja/caja_pantalla.dart` (conectar el botón flotante)
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `cajaRepositorioProvider.registrarManual({required TipoMovimientoCaja tipo, required Dinero monto, required MedioPago medioPago, required String descripcion, DateTime? fecha})`

## Comportamiento esperado

### 1. `dialogo_movimiento_caja.dart`
- Función `Future<void> mostrarDialogoMovimientoCaja(BuildContext context)`:
  - Selector `TipoMovimientoCaja` (`Ingreso` / `Egreso`)
  - `CampoDinero` `'Monto'` (`obligatorio: true`, `permitirCero: false`)
  - `SelectorMedioPago` (por defecto `MedioPago.efectivo`)
  - `CampoTexto` `'Descripción / concepto'` (`obligatorio: true`, ej. "Fondo de caja", "Venta suelta")
  - `BotonGuardar(texto: 'Registrar movimiento', ...)` → llama `registrarManual(...)`, muestra `mostrarExito(context, 'Movimiento registrado')` y cierra el diálogo.

### 2. En `CajaPantalla`
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.caja, nivel: NivelPermiso.cargar, ...)`, botón `'Nuevo movimiento'` que llama `mostrarDialogoMovimientoCaja(context)`.

## Criterios de aceptación
- [ ] El movimiento aparece inmediatamente en la lista y actualiza los totales de ingresos/egresos/saldo.
- [ ] No permite guardar sin descripción ni con monto 0.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/caja/dialogo_movimiento_caja.dart","app/lib/features/caja/caja_pantalla.dart"
```
