# Catálogo de widgets compartidos

> [!IMPORTANT]
> Las pantallas **deben** armarse con estos widgets. No crear versiones propias de un campo de dinero, de un selector de fecha, etc.
> Importar todo con: `import 'package:jereposteria/compartido/compartido.dart';`

Ubicación: `app/lib/compartido/widgets/`. Ver el módulo **Clientes** (`app/lib/features/clientes/`) como ejemplo de uso real.

---

## Estructura de pantalla

| Widget | Uso |
|---|---|
| `PantallaBase({required String titulo, List<Widget> acciones = const [], required Widget cuerpo, Widget? botonFlotante, Widget? pie})` | Scaffold estándar de **toda** pantalla: AppBar, ancho máximo en escritorio, `SafeArea`. |
| `FormularioResponsivo({required GlobalKey<FormState> formKey, required List<Widget> campos, required Widget botonGuardar})` | Formulario con scroll, separación uniforme entre campos y ancho máximo de 640 px en escritorio. |
| `TarjetaSeccion({String? titulo, Widget? accion, required List<Widget> children})` | Bloque con título dentro de pantallas de detalle. |
| `FilaDato({required String etiqueta, required String? valor, IconData? icono, VoidCallback? onTap})` | Par etiqueta/valor en detalles. Si `valor` es null o vacío, no se muestra. |
| `Separacion.chica` / `.media` / `.grande` | `SizedBox` estándar (8 / 16 / 24). **No usar números mágicos.** |

## Datos asíncronos

| Widget | Uso |
|---|---|
| `ListaAsync<T>({required AsyncValue<List<T>> valor, required Widget Function(BuildContext, T) itemBuilder, required Widget vacio, Future<void> Function()? onRefresh, Widget? encabezado, bool separadores = true})` | Lista con estados cargando / error / vacía. **Usar siempre para listas.** |
| `VistaAsync<T>({required AsyncValue<T> valor, required Widget Function(BuildContext, T) builder})` | Igual para un solo valor. Si `T` es nullable y llega `null`, muestra "No encontrado". |
| `EstadoVacio({required IconData icono, required String mensaje, String? textoAccion, VoidCallback? onAccion})` | Mensaje cuando no hay datos. |
| `CampoBusqueda({required ValueChanged<String> onChanged, String hint = 'Buscar...'})` | Campo con debounce de 300 ms. |
| `ChipsFiltro<T>({required List<T> opciones, required Set<T> seleccionados, required String Function(T) etiqueta, required ValueChanged<Set<T>> onChanged, bool multiple = true})` | Filtros horizontales con scroll. |
| `EncabezadoGrupo({required String texto})` | Encabezado de grupo dentro de listas (ej. "Hoy", "Mañana"). |

## Campos de formulario

Todos aceptan `etiqueta`, `obligatorio` (agrega validación y un asterisco) y se integran con `Form` (validan en `formKey.currentState!.validate()`).

| Widget | Valor | Notas |
|---|---|---|
| `CampoTexto({required String etiqueta, String? valorInicial, required ValueChanged<String> onChanged, bool obligatorio = false, TextInputType teclado = TextInputType.text, int maxLineas = 1, String? Function(String)? validador, IconData? icono})` | `String` (recortado) | Para texto libre, teléfono (`TextInputType.phone`), email. |
| `CampoDinero({required String etiqueta, Dinero? valorInicial, required ValueChanged<Dinero?> onChanged, bool obligatorio = false, bool permitirCero = false})` | `Dinero?` | Acepta "15000", "15.000", "15000,50". Muestra `$`. |
| `CampoCantidad({required String etiqueta, required Unidad unidad, int? valorInicial, required ValueChanged<int?> onChanged, bool obligatorio = false, bool permitirCero = false})` | `int?` en unidad base | Con selector kg/g (o l/ml). Devuelve siempre la unidad base. |
| `CampoEntero({required String etiqueta, int? valorInicial, required ValueChanged<int?> onChanged, bool obligatorio = false, int minimo = 0, int? maximo})` | `int?` | Cantidades de productos, días, etc. |
| `CampoFecha({required String etiqueta, DateTime? valor, required ValueChanged<DateTime?> onChanged, bool obligatorio = false, bool conHora = false, DateTime? primera, DateTime? ultima})` | `DateTime?` | Abre el selector en español. |
| `CampoCumpleanos({int? dia, int? mes, int? anio, required void Function(int? dia, int? mes, int? anio) onChanged})` | día/mes/año | Año opcional. |
| `SelectorOpcion<T>({required String etiqueta, required List<T> opciones, required T? valor, required String Function(T) etiquetaDe, required ValueChanged<T?> onChanged, bool obligatorio = false})` | `T?` | Desplegable para enums (estado, categoría, prioridad...). |
| `SelectorMedioPago({required MedioPago? valor, required ValueChanged<MedioPago> onChanged})` | `MedioPago` | Botones segmentados con íconos. |
| `SelectorCliente({String? clienteId, required ValueChanged<Cliente?> onChanged, bool obligatorio = false, bool permitirCrear = true})` | `Cliente?` | Busca y permite crear un cliente rápido (nombre + teléfono). |
| `SelectorProveedor({String? proveedorId, required ValueChanged<Proveedor?> onChanged, bool obligatorio = false})` | `Proveedor?` | |
| `SelectorInsumo({String? insumoId, required ValueChanged<Insumo?> onChanged, bool obligatorio = false, Set<String> excluir = const {}})` | `Insumo?` | `excluir`: ids ya elegidos en la lista. |
| `SelectorProducto({String? productoId, required ValueChanged<Producto?> onChanged, bool obligatorio = false})` | `Producto?` | |
| `SelectorCategoriaGasto({String? categoriaId, required ValueChanged<CategoriaGasto?> onChanged, bool obligatorio = false})` | `CategoriaGasto?` | |
| `SelectorPerfil({String? perfilId, required ValueChanged<Perfil?> onChanged, bool obligatorio = false})` | `Perfil?` | Empleados activos. |
| `SelectorPedido({String? pedidoId, required ValueChanged<PedidoResumen?> onChanged, bool obligatorio = false})` | `PedidoResumen?` | Solo pedidos activos. |
| `SelectorReceta({String? recetaId, required ValueChanged<RecetaResumen?> onChanged, bool obligatorio = false})` | `RecetaResumen?` | Recetas activas. |
| `BotonGuardar({required Future<void> Function() onGuardar, String texto = 'Guardar'})` | — | Muestra spinner, deshabilita doble toque y **captura errores** (`ErrorDeNegocio` → mensaje). |

## Diálogos y mensajes

| Función | Uso |
|---|---|
| `Future<bool> confirmar(BuildContext context, {required String titulo, required String mensaje, String textoConfirmar = 'Confirmar', bool peligroso = false})` | Confirmación antes de anular, archivar, etc. |
| `Future<String?> pedirTexto(BuildContext context, {required String titulo, required String etiqueta, bool obligatorio = true, String textoConfirmar = 'Aceptar'})` | Ej.: motivo de anulación. `null` = canceló. |
| `void mostrarExito(BuildContext context, String mensaje)` | SnackBar de éxito. |
| `void mostrarError(BuildContext context, Object error)` | SnackBar de error. Traduce `ErrorDeNegocio`/`SinConexion` a su mensaje; cualquier otro error → "Ocurrió un error inesperado". |
| `Future<void> ejecutarConManejo(BuildContext context, Future<void> Function() accion, {String? mensajeExito})` | Ejecuta, muestra éxito o error. Usar en botones que no son `BotonGuardar`. |

## Visualización

| Widget | Uso |
|---|---|
| `InsigniaEstado({required String texto, required ColorEstado color, IconData? icono})` | Chip de estado. |
| `InsigniaEstadoPedido(EstadoPedido estado)` | Atajo para pedidos. |
| `InsigniaHabitual()` | Estrella "Habitual". |
| `TextoDinero(Dinero monto, {bool colorear = false, bool conSigno = false, TextStyle? estilo})` | `colorear`: verde si es positivo, rojo si es negativo. |
| `TextoCantidad(int cantidad, Unidad unidad, {TextStyle? estilo})` | |
| `Avatar(String nombre, {double radio = 20})` | Iniciales con color estable. |
| `TarjetaMetrica({required String titulo, required String valor, IconData? icono, ColorEstado color = ColorEstado.neutro, VoidCallback? onTap})` | Números destacados (inicio, caja). |
| `IconoAlerta(TipoAlerta tipo)` | |

## Permisos

| Widget | Uso |
|---|---|
| `RequierePermiso({required Modulo modulo, required NivelPermiso nivel, required Widget child, Widget? alternativa})` | Muestra `child` solo si el usuario tiene el permiso. |
| `SoloJefe({required Widget child, Widget? alternativa})` | Igual, para funciones del jefe (equipo, configuración, asignar tareas a otros). |

En código (no widget): `ref.watch(permisosActualesProvider).puede(Modulo.compras, NivelPermiso.editar)`.

## Navegación

- Rutas: **solo** constantes y funciones de `Rutas` (`app/lib/core/router/rutas.dart`). Ver `docs/pantallas-y-rutas.md`.
- Ir a otra pantalla: `context.push(Rutas.pedido(id))`. Volver: `context.pop()`.
- Después de guardar un formulario: `context.pop()` (la lista se actualiza sola, no hace falta refrescar nada).
- Abrir WhatsApp o llamar: `abrirWhatsApp(telefono, {String? mensaje})`, `llamar(telefono)` (de `compartido/utilidades/contacto.dart`).
