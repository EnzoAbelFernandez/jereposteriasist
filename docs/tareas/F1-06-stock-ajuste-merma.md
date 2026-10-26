# F1-06 – Stock: ajuste por conteo y registro de merma

- **Dificultad:** 🟢 (apto para modelo flash)
- **Depende de:** F1-05

## Objetivo
Permitir ajustar el stock de un insumo al hacer un conteo físico ("en la alacena hay 3,5 kg") y registrar una merma o descarte ("se tiraron 200 g").

## Leer antes de empezar
- `AGENTS.md`
- `docs/capa-de-datos.md` (sección **4.4 Insumos y stock** → `StockRepositorio`)
- `docs/catalogo-widgets.md` (`CampoCantidad`, `CampoTexto`, `BotonGuardar`)

## Alcance de archivos
- **Modificar / crear únicamente:**
  - `app/lib/features/stock/dialogos_stock.dart` (crear)
  - `app/lib/features/stock/stock_lista_pantalla.dart` (agregar acciones en cada insumo)
- **Prohibido tocar cualquier otro archivo.**

## Providers y métodos disponibles (`package:jereposteria/data/data.dart`)
- `stockRepositorioProvider`:
  - `Future<int> ajustarAConteo({required String insumoId, required int cantidadContada, String? nota})`
  - `Future<void> registrarMerma({required String insumoId, required int cantidad, String? nota})`

## Comportamiento esperado

### 1. En `dialogos_stock.dart`
Exponer dos funciones públicas (que también usará F1-07):
```dart
Future<void> mostrarDialogoAjusteStock(BuildContext context, InsumoConStock item);
Future<void> mostrarDialogoMerma(BuildContext context, InsumoConStock item);
```

- **`mostrarDialogoAjusteStock`** (bottom sheet o diálogo):
  - Título: `'Ajustar stock de ${item.insumo.nombre}'`
  - Muestra `'Stock registrado hoy: ${item.stockTexto}'`
  - `CampoCantidad` `'Cantidad real contada'` (`unidad: item.insumo.unidad`, `obligatorio: true`, `permitirCero: true`, inicializado en `item.stock`)
  - `CampoTexto` `'Motivo / nota (opcional)'`
  - `BotonGuardar(texto: 'Aplicar ajuste', ...)` → llama `ajustarAConteo(...)`, muestra `mostrarExito(context, 'Stock ajustado')` y cierra el diálogo.

- **`mostrarDialogoMerma`**:
  - Título: `'Registrar merma de ${item.insumo.nombre}'`
  - `CampoCantidad` `'Cantidad que se descartó o perdió'` (`unidad: item.insumo.unidad`, `obligatorio: true`, `permitirCero: false`)
  - `CampoTexto` `'Motivo (opcional)'` (ej. "Vencido", "Se volcó")
  - `BotonGuardar(texto: 'Registrar merma', ...)` → llama `registrarMerma(...)`, muestra `mostrarExito(context, 'Merma registrada')` y cierra el diálogo.

### 2. En `StockListaPantalla`
- En cada fila, si el usuario tiene `stock:cargar` (o en el `PopupMenuButton` de la fila), agregar las opciones:
  - `'Ajustar por conteo'` → `mostrarDialogoAjusteStock(context, item)`
  - `'Registrar merma'` → `mostrarDialogoMerma(context, item)`

## Criterios de aceptación
- [ ] Si en "Ajustar por conteo" se ingresa una cantidad distinta a la actual, el stock de la lista se actualiza automáticamente.
- [ ] En "Registrar merma" no permite guardar con cantidad 0.
- [ ] Las opciones de ajuste/merma no aparecen si el usuario solo tiene permiso `stock:ver`.

## Verificación obligatoria
```powershell
powershell -ExecutionPolicy Bypass -File tool/check.ps1 -ArchivosPermitidos "app/lib/features/stock/dialogos_stock.dart","app/lib/features/stock/stock_lista_pantalla.dart"
```
