# F1-08 – Compras: lista y detalle (con anulación)

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-01

## Objetivo
Implementar el listado de compras de insumos y la pantalla de detalle de una compra, desde donde también se puede anular (revirtiendo el ingreso de stock y el egreso de caja).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.6 Compras**)
- `docs/catalogo-widgets.md` (`pedirTexto`, `TextoDinero`, `InsigniaEstado`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/compras/compras_lista_pantalla.dart`
  - `app/lib/features/compras/compra_detalle_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `comprasProvider(FiltroCompras(...))` → `AsyncValue<List<CompraResumen>>`
- `compraDetalleProvider(String id)` → `AsyncValue<CompraDetalle?>`
- `comprasRepositorioProvider.anular(String id, {required String motivo})`

## Comportamiento esperado

### 1. `ComprasListaPantalla`
- `PantallaBase` con título `'Compras'`.
- En `acciones`: botón `'Proveedores'` (`Icons.local_shipping_outlined`) que navega a `Rutas.proveedores`, y `FilterChip` `'Ver anuladas'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.compras, nivel: NivelPermiso.cargar, ...)`, botón `'Registrar compra'` → `Rutas.compraNueva`.
- `ListaAsync<CompraResumen>` con `EstadoVacio(icono: Icons.shopping_cart_outlined, mensaje: 'No hay compras registradas')`.
- Cada fila (`ListTile`):
  - `title`: `r.proveedorNombre ?? 'Compra sin proveedor'`
  - `subtitle`: `'${formatearFecha(r.compra.fecha)} · ${r.cantidadItems} ítem(s) · ${r.compra.medioPago.etiqueta}'`
  - `trailing`: `TextoDinero(r.total)` + si `r.compra.anulada`, `InsigniaEstado(texto: 'Anulada', color: ColorEstado.peligro)`
  - `onTap`: `context.push(Rutas.compra(r.compra.id))`

### 2. `CompraDetallePantalla` (`required this.id`)
- `VistaAsync<CompraDetalle?>` sobre `compraDetalleProvider(id)`.
- `PantallaBase` con título `'Detalle de compra'`.
- En `acciones`: si `!detalle.compra.anulada`, botón `'Anular compra'` envuelto en `RequierePermiso(modulo: Modulo.compras, nivel: NivelPermiso.editar, ...)`:
  - Pide el motivo con `pedirTexto(context, titulo: 'Anular compra', etiqueta: 'Motivo de la anulación', textoConfirmar: 'Anular')`.
  - Si no canceló, llama `anular(id, motivo: motivo)` con `ejecutarConManejo(context, ..., mensajeExito: 'Compra anulada')`.
- Contenido:
  - Si está anulada: tarjeta de aviso con `motivoAnulacion` y fecha de anulación.
  - `TarjetaSeccion(titulo: 'Datos')`: fecha, proveedor (si tiene), medio de pago, cargada por (`creadoPorNombre`), notas.
  - `TarjetaSeccion(titulo: 'Insumos comprados')`: cada `CompraItemDetalle` con `insumoNombre`, `cantidadTexto` y `TextoDinero(item.precioTotal)`, más una fila final con el **Total** (`TextoDinero(detalle.total)`).

## Criterios de aceptación
- [ ] Al anular una compra pide motivo obligatorio y la compra pasa a verse como "Anulada".
- [ ] El botón de anular no aparece si ya está anulada o si el usuario no tiene `compras:editar`.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/compras/compras_lista_pantalla.dart","app/lib/features/compras/compra_detalle_pantalla.dart"
```
