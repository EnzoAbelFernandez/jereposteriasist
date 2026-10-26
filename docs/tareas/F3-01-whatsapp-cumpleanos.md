# F3-01 – Saludo de cumpleaños y descuento por WhatsApp

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** Fase 1 (`F1-22`, `Clientes`)

## Objetivo
Agregar acciones directas de **"Enviar saludo / descuento de cumpleaños por WhatsApp"** en el detalle del cliente (`ClienteDetallePantalla`) cuando tiene teléfono y cumpleaños cargado, y en el centro de alertas (`AlertasPantalla`) para las alertas de tipo `TipoAlerta.cumpleanos` cuyo cliente tenga teléfono cargado.

## Leer antes de empezar
- `AGENTS.md`
- `app/lib/features/clientes/cliente_detalle_pantalla.dart`
- `app/lib/features/alertas/alertas_pantalla.dart`
- `app/lib/features/inicio/inicio_pantalla.dart` (ver cómo envía el saludo de cumpleaños con `abrirWhatsApp`)

## Alcance de archivos
- **Modificar únicamente:**
  - `app/lib/features/clientes/cliente_detalle_pantalla.dart`
  - `app/lib/features/alertas/alertas_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Métodos y utilidades disponibles (`package:jereposteria/compartido/compartido.dart` y `package:jereposteria/data/data.dart`)
- `Future<bool> abrirWhatsApp(String telefono, {String? mensaje})`
- `clienteProvider(String id)` → `AsyncValue<Cliente?>`
- `Cliente`:
  - `c.telefono` (`String?`)
  - `c.cumpleDia` (`int?`), `c.cumpleMes` (`int?`)
  - `c.esHabitual` (`bool`)
- `Alerta`:
  - `a.tipo == TipoAlerta.cumpleanos`
  - `a.entidadId` (`String?`, ID del cliente cuando `a.entidadTipo == 'cliente'`)

## Comportamiento esperado

### 1. En `ClienteDetallePantalla` (`app/lib/features/clientes/cliente_detalle_pantalla.dart`)
- Dentro de `TarjetaSeccion(titulo: 'Datos de contacto')`, donde están los botones `'Escribir por WhatsApp'` y `'Llamar'` (cuando `c.telefono != null && c.telefono!.isNotEmpty`):
- Si además el cliente tiene cumpleaños cargado (`c.cumpleDia != null && c.cumpleMes != null`), agregar un botón `OutlinedButton.icon` con ícono `Icons.cake_outlined` y etiqueta `'Saludo de cumpleaños'`:
  - Al presionarlo, llama a `abrirWhatsApp(c.telefono!, mensaje: ...)`.
  - Si `c.esHabitual` es `true`, el mensaje debe ser:
    `'¡Hola ${c.nombre}! Se acerca tu cumpleaños y, por ser cliente habitual, queremos regalarte un descuento especial en tu próximo pedido 🎂'`
  - Si `c.esHabitual` es `false`, el mensaje debe ser:
    `'¡Hola ${c.nombre}! Queremos desearte un muy feliz cumpleaños de parte de todo el equipo 🎂'`

### 2. En `AlertasPantalla` (`app/lib/features/alertas/alertas_pantalla.dart`)
- En cada ítem de la lista (`itemBuilder`), si `a.tipo == TipoAlerta.cumpleanos && a.entidadId != null`:
  - Observar el cliente con `ref.watch(clienteProvider(a.entidadId!)).value`.
  - Si el cliente existe y tiene `telefono != null && telefono!.trim().isNotEmpty`, mostrar en `trailing` del `ListTile` un `IconButton`:
    - `tooltip: 'Enviar saludo por WhatsApp'`
    - `icon: const Icon(Icons.chat_outlined)`
    - `onPressed`: marca la alerta como leída si no lo estaba (`ref.read(alertasRepositorioProvider).marcarLeida(a.id)`) y llama a `abrirWhatsApp` con el teléfono del cliente y el mensaje:
      `'¡Hola ${cliente.nombre}! Se acerca tu cumpleaños y queremos regalarte un descuento especial en tu próximo pedido 🎂'`

## Criterios de aceptación
- [ ] En `ClienteDetallePantalla` aparece el botón `'Saludo de cumpleaños'` solo si el cliente tiene teléfono y fecha de cumpleaños.
- [ ] En `AlertasPantalla` las alertas de cumpleaños de clientes con teléfono muestran el botón de envío rápido por WhatsApp.
- [ ] Sin errores de análisis ni de formato.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/clientes/cliente_detalle_pantalla.dart","app/lib/features/alertas/alertas_pantalla.dart"
```
