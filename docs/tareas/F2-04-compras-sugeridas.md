# F2-04 – Compras sugeridas según pedidos y stock mínimo

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F2-01, F1-08

## Objetivo
Implementar `ComprasSugeridasPantalla` para calcular qué insumos hace falta comprar considerando tanto el **stock mínimo** como los **ingredientes requeridos por los pedidos activos** de los próximos $N$ días (según las recetas de los productos pedidos), y agregar un botón en `ComprasListaPantalla` para abrir esta pantalla.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.16 Compras sugeridas y reportes**)
- `docs/catalogo-widgets.md`
- `app/lib/features/compras/compras_lista_pantalla.dart`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/compras/compras_sugeridas_pantalla.dart`
  - `app/lib/features/compras/compras_lista_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers disponibles (`package:jereposteria/data/data.dart`)
- `comprasSugeridasProvider(int diasHorizonte)` → `AsyncValue<ResumenComprasSugeridas>`
  - `diasHorizonte` (`int`)
  - `pedidosActivosEnHorizonte` (`int`)
  - `items` (`List<ItemCompraSugerida>`):
    - `insumo` (`Insumo`)
    - `stockActualTexto`, `stockMinimoTexto`, `requeridoTexto`, `sugeridoTexto` (`String`)
    - `requeridoPorPedidos` (`int`)
    - `sugeridoComprar` (`int`)
    - `costoEstimado` (`Dinero?`)
  - `costoTotalEstimado` (`Dinero`)

## Comportamiento esperado

### 1. `ComprasSugeridasPantalla`
- Estado local: `int _diasHorizonte = 7` (opciones en `ChipsFiltro<int>` con `multiple: false`: `[3, 7, 14, 30]`, etiqueta `'Próximos $d días'`).
- Observa `comprasSugeridasProvider(_diasHorizonte)` con `VistaAsync<ResumenComprasSugeridas>`.
- `botonFlotante`: envuelto en `RequierePermiso(modulo: Modulo.compras, nivel: NivelPermiso.cargar, ...)`, botón `'Registrar compra'` → `context.push(Rutas.compraNueva)`.
- Encabezado con `TarjetaMetrica` o `TarjetaSeccion`:
  - Cantidad de pedidos activos en los próximos `_diasHorizonte` días (`resumen.pedidosActivosEnHorizonte`).
  - Cantidad de insumos a reponer (`resumen.items.length`).
  - Costo total estimado (`resumen.costoTotalEstimado.formatear()`).
- Si `resumen.items.isEmpty`: mostrar `EstadoVacio(icono: Icons.check_circle_outline, mensaje: 'Tenés stock suficiente para cubrir los pedidos y el stock mínimo')`.
- Si hay ítems: lista de `ItemCompraSugerida` donde cada fila muestra:
  - Título: `item.insumo.nombre` + `InsigniaEstado(texto: 'Comprar ${item.sugeridoTexto}', color: ColorEstado.advertencia)`
  - Subtítulo: `'En stock: ${item.stockActualTexto} · Mínimo: ${item.stockMinimoTexto} · Para pedidos: ${item.requeridoTexto}'`
  - `trailing`: si `item.costoEstimado != null`, `TextoDinero(item.costoEstimado!)`.
  - `onTap`: `context.push(Rutas.stockMovimientos(item.insumo.id))`.

### 2. En `ComprasListaPantalla`
- Agregar en `acciones` de `PantallaBase` un botón `'Sugeridas'` (`Icons.playlist_add_check_outlined`) que navegue a `context.push(Rutas.comprasSugeridas)`.

## Criterios de aceptación
- [ ] Permite cambiar el horizonte entre 3, 7, 14 y 30 días y actualiza la lista.
- [ ] Muestra tanto lo requerido por pedidos con receta como el stock mínimo de cada insumo.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/compras/compras_sugeridas_pantalla.dart","app/lib/features/compras/compras_lista_pantalla.dart"
```
