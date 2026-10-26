# F1-16 – Gastos: lista, formulario y anulación

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-04

## Objetivo
Implementar el listado de gastos (alquiler, luz, gas, descartables, etc.) con total del mes, filtro por categoría y anulación, y el formulario para registrar un gasto (que impacta automáticamente en la caja).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.8 Gastos**)
- `docs/catalogo-widgets.md` (`SelectorCategoriaGasto`, `CampoDinero`, `SelectorMedioPago`, `CampoFecha`, `pedirTexto`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/gastos/gastos_lista_pantalla.dart`
  - `app/lib/features/gastos/gasto_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `gastosProvider(FiltroGastos(...))` → `AsyncValue<List<GastoResumen>>`
- `totalGastosProvider(FiltroGastos(...))` → `AsyncValue<Dinero>`
- `gastosRepositorioProvider`:
  - `Future<String> registrar(GastoDatos datos)`
  - `Future<void> anular(String id, {required String motivo})`

## Comportamiento esperado

### 1. `GastosListaPantalla`
- `PantallaBase` con título `'Gastos'`.
- En `acciones`:
  - `RequierePermiso` (`gastos:editar`): botón `'Categorías'` (`Icons.category_outlined`) → `Rutas.categoriasGasto`.
  - `FilterChip` `'Ver anulados'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.gastos, nivel: NivelPermiso.cargar, ...)`, botón `'Registrar gasto'` → `Rutas.gastoNuevo`.
- Arriba:
  - Selector de mes (`< Mes >`, por defecto mes actual) + `SelectorCategoriaGasto` opcional para filtrar.
  - `TarjetaMetrica` con el total de gastos del período (`totalGastosProvider`).
- `ListaAsync<GastoResumen>` con `EstadoVacio(icono: Icons.receipt_outlined, mensaje: 'No hay gastos en este período')`.
- Cada fila:
  - Título: `r.gasto.descripcion`
  - Subtítulo: `'${formatearFecha(r.gasto.fecha)} · ${r.categoriaNombre} · ${r.gasto.medioPago.etiqueta}'`
  - Derecha: `TextoDinero(r.gasto.monto)` + si `r.gasto.anulado`, `InsigniaEstado(texto: 'Anulado', color: ColorEstado.peligro)`; si no está anulado, botón de anular (`gastos:editar`) que pide motivo con `pedirTexto(...)` y llama `anular(r.gasto.id, motivo: motivo)`.

### 2. `GastoFormularioPantalla`
- `PantallaBase` con título `'Registrar gasto'`.
- `FormularioResponsivo` con:
  - `CampoFecha` `'Fecha'` (`valor: _fecha`, por defecto `hoy()`, `obligatorio: true`)
  - `SelectorCategoriaGasto` (`categoriaId: _categoriaId`, `obligatorio: true`)
  - `CampoTexto` `'Descripción'` (`obligatorio: true`, ej. "Factura de luz Edesur")
  - `CampoDinero` `'Monto'` (`obligatorio: true`, `permitirCero: false`)
  - `SelectorMedioPago` (`valor: _medioPago`, por defecto `MedioPago.efectivo`)
  - `CampoTexto` `'Notas (opcional)'` (`maxLineas: 2`)
- `BotonGuardar(texto: 'Registrar gasto', ...)` → `registrar(GastoDatos(...))` → `mostrarExito(context, 'Gasto registrado')` → `context.pop()`.

## Criterios de aceptación
- [ ] Al registrar un gasto sube el total del mes y se puede anular pidiendo motivo.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/gastos/gastos_lista_pantalla.dart","app/lib/features/gastos/gasto_formulario_pantalla.dart"
```
