# F1-09 – Compras: formulario con ítems dinámicos

- **Dificultad:** 🟡 (modelo intermedio)
- **Depende de:** F1-08

## Objetivo
Implementar el formulario para registrar una compra con uno o más insumos, calculando el total en vivo. Al guardar, el repositorio genera automáticamente las entradas de stock y el egreso de caja.

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.6 Compras**)
- `docs/catalogo-widgets.md` (`SelectorProveedor`, `SelectorInsumo`, `CampoCantidad`, `CampoDinero`, `SelectorMedioPago`, `CampoFecha`, `BotonGuardar`)

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/compras/compra_formulario_pantalla.dart`
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `comprasRepositorioProvider.registrar(CompraDatos datos)`

## Comportamiento esperado

### `CompraFormularioPantalla`
- `PantallaBase` con título `'Registrar compra'`.
- Campos generales:
  - `CampoFecha` `'Fecha'` (`valor: _fecha`, por defecto `DateTime.now()`, `obligatorio: true`)
  - `SelectorProveedor` `'Proveedor (opcional)'` (`proveedorId: _proveedorId`, `onChanged: ...`)
  - `SelectorMedioPago` (`valor: _medioPago`, por defecto `MedioPago.efectivo`)
- Sección `'Insumos comprados'`:
  - Lista de renglones editables (empieza con 1 renglón vacío).
  - Cada renglón permite:
    - Elegir `Insumo` con `SelectorInsumo` (`obligatorio: true`).
    - Una vez elegido el insumo, mostrar `CampoCantidad` `'Cantidad'` con `unidad: renglon.insumo!.unidad` (`obligatorio: true`, `permitirCero: false`).
    - `CampoDinero` `'Precio total del ítem'` (`obligatorio: true`, `permitirCero: true`).
    - Botón quitar renglón (`Icons.delete_outline`), si hay más de 1 renglón.
  - Botón `'Agregar otro insumo'` (`TextButton.icon` con `Icons.add`).
  - Debajo de los renglones: fila destacada con `'Total de la compra'` y `TextoDinero(totalCalculado)` (suma de `precioTotal` de cada renglón).
- `CampoTexto` `'Notas (opcional)'` (`maxLineas: 2`).
- `BotonGuardar(texto: 'Registrar compra', ...)`:
  - Valida el `Form` y verifica que haya al menos 1 renglón con insumo y cantidad `> 0`.
  - Llama `ref.read(comprasRepositorioProvider).registrar(CompraDatos(...))`.
  - Muestra `mostrarExito(context, 'Compra registrada')` y hace `context.pop()`.

## Criterios de aceptación
- [ ] El total se recalcula en vivo a medida que se editan los precios o se agregan/quitan renglones.
- [ ] Cada renglón usa la unidad del insumo elegido (g/kg, ml/l o unidades).
- [ ] No usa `double` en ningún cálculo de dinero (todo con `Dinero`).

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/compras/compra_formulario_pantalla.dart"
```
