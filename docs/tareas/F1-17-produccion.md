# F1-17 – Producción: lista, detalle y registro con consumo de insumos

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-02

## Objetivo
Implementar las pantallas de Producción: listado, detalle (con anulación) y formulario para registrar qué se produjo y qué insumos se usaron (descontándolos automáticamente del stock).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.9 Producción**)
- `docs/catalogo-widgets.md` (`SelectorProducto`, `SelectorPedido`, `SelectorInsumo`, `CampoCantidad`, `CampoEntero`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/produccion/produccion_lista_pantalla.dart`
  - `app/lib/features/produccion/produccion_detalle_pantalla.dart`
  - `app/lib/features/produccion/produccion_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `produccionesProvider(FiltroProduccion(...))` → `AsyncValue<List<ProduccionResumen>>`
- `produccionDetalleProvider(String id)` → `AsyncValue<ProduccionDetalle?>`
- `produccionRepositorioProvider`:
  - `Future<String> registrar(ProduccionDatos datos)`
  - `Future<void> anular(String id, {required String motivo})`

## Comportamiento esperado

### 1. `ProduccionListaPantalla`
- `PantallaBase` con título `'Producción'`.
- En `acciones`: `FilterChip` `'Ver anuladas'`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.produccion, nivel: NivelPermiso.cargar, ...)`, botón `'Registrar producción'` → `Rutas.produccionNueva()`.
- `ListaAsync<ProduccionResumen>` con `EstadoVacio(icono: Icons.bakery_dining_outlined, mensaje: 'No hay producciones registradas')`.
- Cada fila:
  - Título: `'${r.produccion.cantidad} × ${r.produccion.descripcion}'`
  - Subtítulo: `formatearFechaHora(r.produccion.fecha)` + (si `r.pedidoNumero != null`, `' · Pedido #${r.pedidoNumero}'`) + `' · ${r.cantidadInsumos} insumo(s)'`
  - Si `r.produccion.anulada`: `InsigniaEstado(texto: 'Anulada', color: ColorEstado.peligro)`
  - `onTap`: `context.push(Rutas.produccionDetalle(r.produccion.id))`

### 2. `ProduccionDetallePantalla` (`required this.id`)
- `VistaAsync<ProduccionDetalle?>` sobre `produccionDetalleProvider(id)`.
- Acción `'Anular'` si `!d.produccion.anulada` (`produccion:editar` → `pedirTexto` motivo → `anular(...)`).
- `TarjetaSeccion(titulo: 'Datos')`: fecha, descripción, cantidad, pedido vinculado (tocable para ir a `Rutas.pedido(...)`), registrado por, notas.
- `TarjetaSeccion(titulo: 'Insumos consumidos')`: lista de `d.consumos` (`insumoNombre` + `cantidadTexto`), o texto `'No se registraron consumos de insumos'` si está vacía.

### 3. `ProduccionFormularioPantalla` (`this.pedidoIdInicial` opcional)
- `PantallaBase` con título `'Registrar producción'`.
- Campos:
  - `CampoFecha` `'Fecha'` (`valor: _fecha`, por defecto `DateTime.now()`, `obligatorio: true`)
  - `SelectorProducto` `'Producto del catálogo (opcional)'`: al elegir uno, si la descripción está vacía copia `producto.nombre`.
  - `CampoTexto` `'Qué se produjo'` (`obligatorio: true`, ej. "Bizcochuelo vainilla 24 cm")
  - `CampoEntero` `'Cantidad producida'` (`minimo: 1`, inicial `1`, `obligatorio: true`)
  - `SelectorPedido` `'Pedido vinculado (opcional)'` (`pedidoId: _pedidoId`)
  - Sección `'Insumos utilizados (opcional)'`:
    - Lista de renglones (`SelectorInsumo` + `CampoCantidad` con la unidad del insumo elegido + botón quitar).
    - Botón `'Agregar insumo utilizado'`.
  - `CampoTexto` `'Notas (opcional)'` (`maxLineas: 2`).
- `BotonGuardar(texto: 'Registrar producción', ...)` → `registrar(ProduccionDatos(...))` → `mostrarExito(context, 'Producción registrada')` → `context.pop()`.

## Criterios de aceptación
- [ ] Permite registrar una producción tanto con insumos consumidos como sin insumos.
- [ ] Al anular una producción se revierte el descuento de stock.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/produccion/*"
```
