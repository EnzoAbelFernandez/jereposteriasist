# F1-23 – Inicio: resumen del día según permisos

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-22

## Objetivo
Implementar la pantalla de Inicio (la primera que se abre tras iniciar sesión) con el resumen operativo del día adaptado a los permisos de cada usuario: entregas de hoy y mañana, tareas pendientes, insumos en falta y próximos cumpleaños (con botón para saludar u ofrecer descuento por WhatsApp).

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md`
- `docs/catalogo-widgets.md` (`RequierePermiso`, `TarjetaMetrica`, `TarjetaSeccion`, `abrirWhatsApp`)
- `docs/pantallas-y-rutas.md`

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/inicio/inicio_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `perfilActualProvider`
- `misTareasProvider(false)` y `cantidadTareasPendientesProvider`
- `pedidosProvider(FiltroPedidos(...))` (si tiene `pedidos:ver` o `produccion:ver`)
- `insumosConStockProvider(const FiltroStock(soloFaltantes: true))` y `cantidadFaltantesProvider` (si tiene `stock:ver` o `compras:ver`)
- `proximosCumpleanosProvider` (si tiene `clientes:ver`)
- `resumenCajaProvider(FiltroCaja.mesActual())` (si tiene `caja:ver`)

## Comportamiento esperado

### `InicioPantalla`
- `PantallaBase` con saludo (`'Hola, ${perfil.nombre}'`).
- Mostrar **solo** las secciones para las que el usuario tiene permiso (`RequierePermiso`):
  1. **Tarjetas rápidas (arriba):**
     - `Mis tareas pendientes` → `Rutas.tareas`
     - Si tiene `pedidos:ver` o `produccion:ver`: `Entregas de hoy` → `Rutas.pedidos`
     - Si tiene `stock:ver` o `compras:ver`: `Insumos en falta` (`ColorEstado.peligro` si `> 0`) → `Rutas.stock`
     - Si tiene `caja:ver`: `Saldo del mes` → `Rutas.caja`
  2. **Sección `'Entregas de hoy y mañana'`** (`pedidos:ver` o `produccion:ver`):
     - Hasta 5 pedidos cuyas entregas sean hoy o mañana, con hora, cliente, estado y toque hacia `Rutas.pedido(id)`. Botón `'Ver calendario'` → `Rutas.pedidosCalendario`.
  3. **Sección `'Próximos cumpleaños'`** (`clientes:ver`):
     - Lista de `proximosCumpleanosProvider` (`ClienteConCumple`): nombre, `InsigniaHabitual()` si `c.cliente.esHabitual`, `'Hoy'` / `'Mañana'` / `'En ${c.dias} días (${formatearFechaCorta(c.fecha)})'`.
     - Si tiene teléfono, botón `'Enviar saludo / descuento'` que llama `abrirWhatsApp(c.cliente.telefono!, mensaje: '¡Hola ${c.cliente.nombre}! Se acerca tu cumpleaños y queremos regalarte un descuento especial en tu próximo pedido 🎂')`.
  4. **Sección `'Mis tareas pendientes'`** (siempre visible):
     - Hasta 5 tareas de `misTareasProvider(false)`, con casilla para marcarlas hechas directamente desde acá y botón `'Ver todas'` → `Rutas.tareas`.
  5. **Sección `'Insumos en falta'`** (`stock:ver` o `compras:ver`, solo si hay faltantes):
     - Hasta 5 insumos en falta con cuánto falta y botón `'Registrar compra'` → `Rutas.compraNueva`.

## Criterios de aceptación
- [ ] Un empleado sin permiso de `caja` ni `clientes` no ve ni el saldo ni los cumpleaños (ni se suscriben esos providers si el widget no se monta gracias a `RequierePermiso`).
- [ ] El botón de WhatsApp en los cumpleaños abre el chat con el mensaje prellenado.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/inicio/inicio_pantalla.dart"
```
