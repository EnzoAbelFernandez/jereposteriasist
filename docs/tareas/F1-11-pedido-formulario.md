# F1-11 – Pedidos: formulario de alta y edición

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-10

## Objetivo
Implementar el formulario para crear o editar un pedido (cliente, fecha y hora de entrega, retiro/envío, ítems con producto opcional del catálogo, descuento y seña inicial al crearlo).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.5 Pedidos**)
- `docs/catalogo-widgets.md` (`SelectorCliente`, `SelectorProducto`, `CampoFecha`, `CampoDinero`, `CampoEntero`, `SelectorMedioPago`, `BotonGuardar`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/pedidos/pedido_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `pedidoDetalleProvider(String id)` → `AsyncValue<PedidoDetalle?>`
- `pedidosRepositorioProvider`:
  - `Future<String> crear(PedidoDatos datos, {PagoDatos? sena})`
  - `Future<void> actualizar(String id, PedidoDatos datos)`

## Comportamiento esperado

### `PedidoFormularioPantalla` (`this.id` opcional, `this.clienteIdInicial` opcional)
- Título: `'Nuevo pedido'` o `'Editar pedido'`.
- Si `id != null`, observar `pedidoDetalleProvider(id!)` con `VistaAsync` y precargar una sola vez (`PedidoDatos.desde(detalle)`).
- Campos:
  1. `SelectorCliente` (`clienteId: _clienteId`, `obligatorio: true`, `permitirCrear: true`)
  2. `CampoFecha` `'Fecha y hora de entrega'` (`conHora: true`, `obligatorio: true`)
  3. `SelectorOpcion<TipoEntrega>` `'Entrega'` (`opciones: TipoEntrega.values`, por defecto `TipoEntrega.retira`)
     - Si es `TipoEntrega.envio`, mostrar `CampoTexto` `'Dirección de entrega'` (`obligatorio: true`).
  4. **Solo al crear (`id == null`):** `SelectorOpcion<EstadoPedido>` `'Estado inicial'` con opciones `[EstadoPedido.confirmado, EstadoPedido.presupuesto]` (por defecto `confirmado`).
  5. **Sección `'Detalle del pedido'` (ítems dinámicos, mínimo 1):**
     - Cada ítem tiene:
       - `SelectorProducto` opcional: al elegir un producto del catálogo, si la descripción está vacía copia `producto.nombre`, y si el precio es 0 y `producto.precioBase != null` copia `producto.precioBase!`.
       - `CampoTexto` `'Descripción'` (`obligatorio: true`, ej. "Torta cumple 2 pisos relleno dulce de leche y ganache")
       - `CampoEntero` `'Cantidad'` (`minimo: 1`, valor inicial `1`, `obligatorio: true`)
       - `CampoDinero` `'Precio unitario'` (`obligatorio: true`, `permitirCero: true`)
       - `CampoTexto` `'Notas del ítem (opcional)'`
       - Botón eliminar ítem (si hay más de 1).
     - Botón `'Agregar ítem'`.
  6. **Descuento y totales:**
     - `CampoDinero` `'Descuento (opcional)'` (`permitirCero: true`)
     - Si el descuento es `> 0`, mostrar `CampoTexto` `'Motivo del descuento'` (ej. "Cumpleaños cliente habitual").
     - Resumen en vivo: **Subtotal**, **Descuento** y **Total** (`TextoDinero`).
  7. **Seña inicial (solo al crear, `id == null`):**
     - `SwitchListTile` `'Registrar seña ahora'` (`_cobraSena`).
     - Si está activo: `CampoDinero` `'Monto de la seña'` (`obligatorio: true`) + `SelectorMedioPago` + resumen `'Saldo pendiente: ${(total - sena).formatear()}'`.
  8. `CampoTexto` `'Notas generales (opcional)'` (`maxLineas: 3`).
- `BotonGuardar`:
  - Llama `crear(datos, sena: _cobraSena ? PagoDatos(...) : null)` o `actualizar(id!, datos)`.
  - Al crear, navega o vuelve con `context.pop()` y `mostrarExito(context, 'Pedido guardado')`.

## Criterios de aceptación
- [ ] Elegir un producto del catálogo autocompleta nombre y precio sugerido, pero permite editarlos.
- [ ] En modo edición no aparece la sección de seña inicial (los pagos se registran desde el detalle, F1-12).
- [ ] Todos los cálculos usan `Dinero` (sin `double`).

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/pedidos/pedido_formulario_pantalla.dart"
```
