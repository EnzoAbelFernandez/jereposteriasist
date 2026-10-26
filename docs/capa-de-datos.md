# Capa de datos – Contrato (API Dart)

> [!IMPORTANT]
> Este documento es el **contrato** entre la capa de datos (hecha y testeada por el modelo fuerte en la Fase 0) y las pantallas (hechas por agentes).
> **Los agentes solo pueden usar lo que figura acá.** Si falta algo, se detienen y lo reportan. No se agregan métodos, columnas ni providers por cuenta propia.

Ubicaciones:
- Tipos compartidos: `app/lib/compartido/tipos/`
- Modelos: `app/lib/data/modelos/`
- Repositorios y providers: `app/lib/data/repositorios/`
- Sesión y permisos: `app/lib/core/sesion/`

Para importar todo de una vez: `import 'package:jereposteria/data/data.dart';` (exporta modelos, repositorios, providers y tipos).

---

## 1. Reglas generales

| Regla | Detalle |
|---|---|
| IDs | `String` (UUID v4 generado en el dispositivo por el repositorio). |
| Dinero | Siempre `Dinero` (centavos enteros). **Nunca `double`.** |
| Cantidades de insumos | `int` en unidad base (`g`, `ml`, `u`) + `Unidad` para mostrar. |
| Fechas | `DateTime` en hora local. Fechas "solo día" (gasto, vencimiento, cumpleaños) usan `DateTime` con hora 00:00. |
| Lecturas | `observar...()` devuelven `Stream` que se actualiza solo (local + sincronización). |
| Escrituras | Métodos `Future`. Funcionan **sin conexión**; se suben solas al volver internet. |
| Errores de validación | Lanzan `ErrorDeNegocio(mensaje)` con un texto listo para mostrar al usuario. |
| Acciones online | Solo `EquipoRepositorio.invitarEmpleado/desactivar/reactivar`. Lanzan `SinConexion` si no hay internet. |
| Uso en pantallas | Leer con los **providers** (`ref.watch(...)`). Escribir con `ref.read(xxxRepositorioProvider).metodo(...)`. |

```dart
class ErrorDeNegocio implements Exception { final String mensaje; }
class SinConexion implements Exception { final String mensaje; }
```

---

## 2. Tipos compartidos (`compartido/tipos/`)

### `Dinero`
```dart
class Dinero implements Comparable<Dinero> {
  const Dinero(this.centavos);
  final int centavos;
  static const cero = Dinero(0);
  factory Dinero.pesos(int pesos);            // Dinero.pesos(1500) == Dinero(150000)
  static Dinero? parsear(String texto);       // "15000", "15.000", "15.000,50", "$ 1.500" -> Dinero; inválido -> null
  Dinero operator +(Dinero o); Dinero operator -(Dinero o); Dinero operator -();
  Dinero por(int cantidad);
  bool get esCero; bool get esPositivo; bool get esNegativo;
  bool operator <(Dinero o); bool operator >(Dinero o); bool operator <=(Dinero o); bool operator >=(Dinero o);
  String formatear();                          // "$ 15.000" | "$ 15.000,50" | "-$ 200"
  String formatearParaCampo();                 // "15000" | "15000,50" (para precargar un TextField)
}
```

### `Unidad` (insumos)
```dart
enum Unidad {
  gramos('g'), mililitros('ml'), unidades('u');
  final String valor;
  String get etiqueta;                        // "Gramos / kilos", "Mililitros / litros", "Unidades"
  String formatear(int cantidad);             // gramos: 500 -> "500 g", 2500 -> "2,5 kg"; ml: "750 ml", "1,5 l"; u: "12 u."
  static Unidad desdeValor(String v);
}
```

### Enums de dominio
Todos tienen `String get etiqueta` (texto para la interfaz, en español) y `String get valor` (valor en base de datos), y `static X desdeValor(String)`.

| Enum | Valores (`etiqueta`) | Extras |
|---|---|---|
| `MedioPago` | efectivo (Efectivo), transferencia (Transferencia), mercadoPago (Mercado Pago) | `IconData get icono` |
| `EstadoPedido` | presupuesto (Presupuesto), confirmado (Confirmado), enProduccion (En producción), listo (Listo), entregado (Entregado), cancelado (Cancelado) | `List<EstadoPedido> get siguientes` (transiciones permitidas), `bool get esFinal`, `bool get esActivo` (no final y no presupuesto), `ColorEstado get color` |
| `TipoEntrega` | retira (Retira en el local), envio (Envío) | |
| `CategoriaProducto` | torta (Torta), tarta (Tarta), mesaDulce (Mesa dulce), otro (Otro) | |
| `EstadoDocumento` | registrado (Registrado), anulado (Anulado) | compras, gastos, producciones |
| `TipoMovimientoStock` | inicial (Stock inicial), compra (Compra), produccion (Producción), ajuste (Ajuste por conteo), merma (Merma / pérdida), anulacion (Anulación) | |
| `TipoMovimientoCaja` | ingreso (Ingreso), egreso (Egreso) | |
| `ConceptoCaja` | sena (Seña), pagoPedido (Pago de pedido), compra (Compra), gasto (Gasto), otroIngreso (Otro ingreso), otroEgreso (Otro egreso), anulacion (Anulación) | `bool get esManual` (otroIngreso/otroEgreso) |
| `TipoTarea` | compra, produccion, stock, gasto, pedido, limpieza, otro | `IconData get icono` |
| `PrioridadTarea` | baja, media, alta | `ColorEstado get color` |
| `EstadoTarea` | pendiente (Pendiente), enProgreso (En progreso), hecha (Hecha), cancelada (Cancelada) | `bool get esFinal` |
| `TipoAlerta` | cumpleanos, stockBajo, entregaProxima, tareaAsignada, tareaVencida | `IconData get icono` |
| `HabitualModo` | auto (Automático), si (Siempre habitual), no (Nunca habitual) | |
| `Rol` | jefe (Jefe), empleado (Empleado) | |
| `Modulo` | clientes, pedidos, catalogo (Catálogo), stock, compras, produccion (Producción), gastos, caja, reportes | `IconData get icono` |
| `NivelPermiso` | ninguno, ver, cargar, editar | `bool alcanza(NivelPermiso minimo)`; `String get descripcion` |

`ColorEstado` es un enum semántico (`neutro, info, exito, advertencia, peligro`). El widget `InsigniaEstado` lo traduce a colores del tema. **Nunca usar `Colors.xxx` directamente.**

### Fechas (`compartido/formato/fechas.dart`)
```dart
String formatearFecha(DateTime d);             // "25/10/2026"
String formatearFechaCorta(DateTime d);        // "25/10"
String formatearFechaHora(DateTime d);         // "25/10/2026 14:30"
String formatearHora(DateTime d);              // "14:30"
String formatearFechaRelativa(DateTime d);     // "Hoy", "Mañana", "Ayer", "Lun 27/10"
String formatearDiaSemana(DateTime d);         // "lunes"
DateTime hoy();                                // hoy a las 00:00
DateTime inicioDeMes(DateTime d); DateTime finDeMes(DateTime d);
bool esMismoDia(DateTime a, DateTime b);
```

---

## 3. Sesión y permisos (`core/sesion/`)

```dart
final perfilActualProvider = StreamProvider<Perfil?>(...);           // null = no logueado
final permisosActualesProvider = Provider<PermisosUsuario>(...);       // siempre disponible (vacío si no hay sesión)

class PermisosUsuario {
  bool get esJefe;
  NivelPermiso nivel(Modulo m);
  bool puede(Modulo m, NivelPermiso minimo);   // ej: puede(Modulo.compras, NivelPermiso.cargar)
}

final sesionControllerProvider = ...;           // usado solo por core (login/logout)
```

En pantallas, para mostrar/ocultar botones usar el widget `RequierePermiso` (ver `docs/catalogo-widgets.md`).

---

## 4. Modelos y repositorios por módulo

Notación: `?` = puede ser null. Todos los modelos son inmutables, con `==` por valor.

### 4.1 Clientes — `ClientesRepositorio` (módulo de REFERENCIA, ya implementado)

```dart
class Cliente {
  String id; String nombre; String? telefono; String? email; String? direccion;
  int? cumpleDia; int? cumpleMes; int? cumpleAnio;
  String? preferencias; String? alergias; String? notas;
  HabitualModo habitualModo; bool habitualAuto; DateTime? archivadoEn; DateTime creadoEn;
  bool get esHabitual;                       // si -> true, no -> false, auto -> habitualAuto
  bool get archivado;
  bool get tieneCumple;
  DateTime? proximoCumple(DateTime desde);   // maneja 29/02
  int? diasParaCumple(DateTime desde);       // 0 = hoy
  String? get cumpleTexto;                   // "3 de noviembre"
}

class ClienteDatos {                         // para crear/editar
  String nombre; String? telefono; String? email; String? direccion;
  int? cumpleDia; int? cumpleMes; int? cumpleAnio;
  String? preferencias; String? alergias; String? notas; HabitualModo habitualModo;
  factory ClienteDatos.desde(Cliente c);
}

class ClienteConCumple { Cliente cliente; DateTime fecha; int dias; }

abstract class ClientesRepositorio {
  Stream<List<Cliente>> observarActivos({String busqueda = ''});   // orden: nombre
  Stream<List<Cliente>> observarArchivados();
  Stream<Cliente?> observarPorId(String id);
  Stream<List<ClienteConCumple>> observarProximosCumpleanos({int dias = 7}); // orden: más cercano primero
  Future<String> crear(ClienteDatos datos);                          // ErrorDeNegocio si nombre vacío
  Future<void> actualizar(String id, ClienteDatos datos);
  Future<void> archivar(String id);
  Future<void> desarchivar(String id);
}
```
Providers:
```dart
clientesRepositorioProvider
clientesProvider            // StreamProvider.autoDispose.family<List<Cliente>, String /*busqueda*/>
clientesArchivadosProvider  // StreamProvider.autoDispose<List<Cliente>>
clienteProvider             // StreamProvider.autoDispose.family<Cliente?, String /*id*/>
proximosCumpleanosProvider  // StreamProvider.autoDispose<List<ClienteConCumple>> (usa configuracion.diasAvisoCumple)
```

### 4.2 Proveedores — `ProveedoresRepositorio`
```dart
class Proveedor { String id; String nombre; String? telefono; String? email; String? notas; DateTime? archivadoEn; bool get archivado; }
class ProveedorDatos { String nombre; String? telefono; String? email; String? notas; factory ProveedorDatos.desde(Proveedor p); }

abstract class ProveedoresRepositorio {
  Stream<List<Proveedor>> observarActivos({String busqueda = ''});
  Stream<Proveedor?> observarPorId(String id);
  Future<String> crear(ProveedorDatos datos);
  Future<void> actualizar(String id, ProveedorDatos datos);
  Future<void> archivar(String id);
}
```
Providers: `proveedoresRepositorioProvider`, `proveedoresProvider` (family busqueda), `proveedorProvider` (family id).

### 4.3 Productos (catálogo) — `ProductosRepositorio`
```dart
class Producto { String id; String nombre; CategoriaProducto categoria; Dinero? precioBase; String? descripcion; DateTime? archivadoEn; bool get archivado; }
class ProductoDatos { String nombre; CategoriaProducto categoria; Dinero? precioBase; String? descripcion; factory ProductoDatos.desde(Producto p); }

abstract class ProductosRepositorio {
  Stream<List<Producto>> observarActivos({String busqueda = '', CategoriaProducto? categoria});
  Stream<Producto?> observarPorId(String id);
  Future<String> crear(ProductoDatos datos);
  Future<void> actualizar(String id, ProductoDatos datos);
  Future<void> archivar(String id);
}
```
Providers: `productosRepositorioProvider`, `productosProvider` (family `FiltroProductos(busqueda, categoria)`), `productoProvider` (family id).

### 4.4 Insumos y stock — `InsumosRepositorio`, `StockRepositorio`
```dart
class Insumo { String id; String nombre; Unidad unidad; int stockMinimo; String? categoria; String? notas; DateTime? archivadoEn; bool get archivado; }
class InsumoConStock {
  Insumo insumo; int stock;
  bool get faltante;            // stockMinimo > 0 && stock < stockMinimo
  int get cantidadFaltante;     // max(0, stockMinimo - stock)
  String get stockTexto;        // insumo.unidad.formatear(stock)
}
class InsumoDatos { String nombre; Unidad unidad; int stockMinimo; String? categoria; String? notas; factory InsumoDatos.desde(Insumo i); }

class MovimientoStock {
  String id; String insumoId; DateTime fecha; int cantidad; TipoMovimientoStock tipo;
  String? compraId; String? produccionId; String? anulaId; String? nota; String? creadoPor; String? creadoPorNombre;
  bool anulado;                 // true si existe una anulación que lo referencia
  bool get esEntrada;           // cantidad > 0
  bool get anulable;            // tipo in (inicial, ajuste, merma) && !anulado
}

abstract class InsumosRepositorio {
  Stream<List<Insumo>> observarActivos({String busqueda = ''});
  Stream<List<InsumoConStock>> observarConStock({String busqueda = '', bool soloFaltantes = false}); // orden: faltantes primero, luego nombre
  Stream<InsumoConStock?> observarPorId(String id);
  Stream<int> observarCantidadFaltantes();
  Future<String> crear(InsumoDatos datos, {int stockInicial = 0});  // stockInicial > 0 crea movimiento 'inicial'
  Future<void> actualizar(String id, InsumoDatos datos);             // ErrorDeNegocio si cambia la unidad y ya tiene movimientos
  Future<void> archivar(String id);
}

abstract class StockRepositorio {
  Stream<List<MovimientoStock>> observarMovimientos(String insumoId);   // orden: fecha desc
  Future<int> ajustarAConteo({required String insumoId, required int cantidadContada, String? nota}); // devuelve la diferencia aplicada (0 = no hizo nada)
  Future<void> registrarMerma({required String insumoId, required int cantidad, String? nota});       // cantidad > 0 (se descuenta)
  Future<void> anularMovimiento(String movimientoId);                   // solo si anulable; si no, ErrorDeNegocio
}
```
Providers: `insumosRepositorioProvider`, `stockRepositorioProvider`, `insumosProvider` (family busqueda → `List<Insumo>`), `insumosConStockProvider` (family `FiltroStock(busqueda, soloFaltantes)`), `insumoConStockProvider` (family id), `cantidadFaltantesProvider`, `movimientosStockProvider` (family insumoId).

### 4.5 Pedidos — `PedidosRepositorio`
```dart
class Pedido {
  String id; int? numero;          // null hasta que sincroniza: mostrar "Nº pendiente"
  String clienteId; DateTime fechaEntrega; TipoEntrega tipoEntrega; String? direccionEntrega;
  EstadoPedido estado; Dinero descuento; String? motivoDescuento; String? notas;
  DateTime? entregadoEn; DateTime? canceladoEn; String? motivoCancelacion; DateTime creadoEn;
  String get numeroTexto;          // "#123" o "Nº pendiente"
}
class PedidoItem { String id; String pedidoId; String? productoId; String descripcion; int cantidad; Dinero precioUnitario; String? notas; int orden; Dinero get subtotal; }

class PedidoResumen {
  Pedido pedido; String clienteNombre; String? clienteTelefono; Dinero total; Dinero pagado; int cantidadItems; String? primerItem;
  Dinero get saldo;                // total - pagado
  bool get pagadoCompleto;         // saldo <= 0
}
class PedidoDetalle {
  Pedido pedido; Cliente cliente; List<PedidoItem> items; List<MovimientoCaja> pagos; // pagos incluye anulaciones
  Dinero get subtotal; Dinero get total; Dinero get pagado; Dinero get saldo;
}

class PedidoItemDatos { String? id /*null = nuevo*/; String? productoId; String descripcion; int cantidad; Dinero precioUnitario; String? notas; }
class PedidoDatos {
  String clienteId; DateTime fechaEntrega; TipoEntrega tipoEntrega; String? direccionEntrega;
  EstadoPedido estadoInicial;      // solo presupuesto o confirmado (se ignora al actualizar)
  Dinero descuento; String? motivoDescuento; String? notas; List<PedidoItemDatos> items;
  factory PedidoDatos.desde(PedidoDetalle d);
  Dinero get total;                // para mostrar en el formulario
}
class PagoDatos { Dinero monto; MedioPago medioPago; DateTime? fecha; }

class FiltroPedidos { Set<EstadoPedido>? estados; DateTime? desde; DateTime? hasta; String busqueda; }
// Constantes útiles: FiltroPedidos.activos (presupuesto, confirmado, enProduccion, listo), FiltroPedidos.todos

abstract class PedidosRepositorio {
  Stream<List<PedidoResumen>> observarResumenes(FiltroPedidos filtro);   // orden: fechaEntrega asc
  Stream<List<PedidoResumen>> observarPorCliente(String clienteId);       // orden: fechaEntrega desc
  Stream<PedidoDetalle?> observarDetalle(String id);
  Future<String> crear(PedidoDatos datos, {PagoDatos? sena});  // ErrorDeNegocio: sin ítems, seña > total, estado inicial inválido
  Future<void> actualizar(String id, PedidoDatos datos);        // ErrorDeNegocio si el pedido está entregado/cancelado
  Future<void> cambiarEstado(String id, EstadoPedido nuevo, {String? motivoCancelacion}); // valida EstadoPedido.siguientes
  Future<void> registrarPago(String pedidoId, PagoDatos pago, {bool esSena = false});     // ErrorDeNegocio si monto <= 0 o > saldo
  Future<void> anularPago(String movimientoCajaId);
}
```
Providers: `pedidosRepositorioProvider`, `pedidosProvider` (family `FiltroPedidos`), `pedidosPorClienteProvider` (family clienteId), `pedidoDetalleProvider` (family id).

### 4.6 Compras — `ComprasRepositorio`
```dart
class Compra { String id; String? proveedorId; DateTime fecha; MedioPago medioPago; EstadoDocumento estado; DateTime? anuladoEn; String? motivoAnulacion; String? notas; String? creadoPor; bool get anulada; }
class CompraItem { String id; String compraId; String insumoId; int cantidad; Dinero precioTotal; }
class CompraItemDetalle { CompraItem item; String insumoNombre; Unidad unidad; String get cantidadTexto; }
class CompraResumen { Compra compra; String? proveedorNombre; Dinero total; int cantidadItems; String? creadoPorNombre; }
class CompraDetalle { Compra compra; Proveedor? proveedor; List<CompraItemDetalle> items; Dinero get total; String? creadoPorNombre; }

class CompraItemDatos { String insumoId; int cantidad; Dinero precioTotal; }
class CompraDatos { String? proveedorId; DateTime fecha; MedioPago medioPago; String? notas; List<CompraItemDatos> items; Dinero get total; }
class FiltroCompras { DateTime? desde; DateTime? hasta; bool incluirAnuladas; }

abstract class ComprasRepositorio {
  Stream<List<CompraResumen>> observarResumenes(FiltroCompras filtro);  // orden: fecha desc
  Stream<CompraDetalle?> observarDetalle(String id);
  Future<String> registrar(CompraDatos datos);   // compra + ítems + entradas de stock + egreso de caja. ErrorDeNegocio si no hay ítems o cantidad <= 0
  Future<void> anular(String id, {required String motivo}); // contramovimientos de stock y caja
}
```
Providers: `comprasRepositorioProvider`, `comprasProvider` (family `FiltroCompras`), `compraDetalleProvider` (family id).

### 4.7 Caja — `CajaRepositorio`
```dart
class MovimientoCaja {
  String id; DateTime fecha; TipoMovimientoCaja tipo; Dinero monto; MedioPago medioPago; ConceptoCaja concepto; String? descripcion;
  String? pedidoId; String? compraId; String? gastoId; String? anulaId; String? creadoPor; String? creadoPorNombre;
  bool anulado;                     // existe una anulación que lo referencia
  Dinero get montoConSigno;         // + ingreso / - egreso
  bool get anulable;                // concepto.esManual && !anulado (los demás se anulan desde su módulo)
  String get descripcionTexto;      // descripcion o texto según concepto ("Seña pedido #12", "Compra", ...)
}
class ResumenCaja { Dinero ingresos; Dinero egresos; Dinero get saldo; Map<MedioPago, Dinero> saldoPorMedio; }
class FiltroCaja { DateTime desde; DateTime hasta; TipoMovimientoCaja? tipo; MedioPago? medio; }
// FiltroCaja.mesActual()

abstract class CajaRepositorio {
  Stream<List<MovimientoCaja>> observarMovimientos(FiltroCaja filtro);  // orden: fecha desc
  Stream<ResumenCaja> observarResumen(FiltroCaja filtro);
  Future<String> registrarManual({required TipoMovimientoCaja tipo, required Dinero monto, required MedioPago medioPago, required String descripcion, DateTime? fecha});
  Future<void> anularMovimiento(String id);   // solo si anulable; si no, ErrorDeNegocio con el motivo
}
```
Providers: `cajaRepositorioProvider`, `movimientosCajaProvider` (family `FiltroCaja`), `resumenCajaProvider` (family `FiltroCaja`).

### 4.8 Gastos — `GastosRepositorio`
```dart
class CategoriaGasto { String id; String nombre; DateTime? archivadoEn; bool get archivada; }
class Gasto { String id; DateTime fecha; String categoriaId; String descripcion; Dinero monto; MedioPago medioPago; EstadoDocumento estado; DateTime? anuladoEn; String? motivoAnulacion; String? notas; bool get anulado; }
class GastoResumen { Gasto gasto; String categoriaNombre; String? creadoPorNombre; }
class GastoDatos { DateTime fecha; String categoriaId; String descripcion; Dinero monto; MedioPago medioPago; String? notas; }
class FiltroGastos { DateTime desde; DateTime hasta; String? categoriaId; bool incluirAnulados; }  // FiltroGastos.mesActual()

abstract class GastosRepositorio {
  Stream<List<GastoResumen>> observarResumenes(FiltroGastos filtro);   // orden: fecha desc
  Stream<Dinero> observarTotal(FiltroGastos filtro);                   // sin anulados
  Future<String> registrar(GastoDatos datos);                          // gasto + egreso de caja
  Future<void> anular(String id, {required String motivo});
  Stream<List<CategoriaGasto>> observarCategorias({bool incluirArchivadas = false});
  Future<String> crearCategoria(String nombre);
  Future<void> renombrarCategoria(String id, String nombre);
  Future<void> archivarCategoria(String id);
  Future<void> desarchivarCategoria(String id);
}
```
Providers: `gastosRepositorioProvider`, `gastosProvider` (family `FiltroGastos`), `totalGastosProvider` (family `FiltroGastos`), `categoriasGastoProvider` (family bool incluirArchivadas).

### 4.9 Producción — `ProduccionRepositorio`
```dart
class Produccion { String id; DateTime fecha; String? productoId; String descripcion; int cantidad; String? pedidoId; String? recetaId; EstadoDocumento estado; DateTime? anuladoEn; String? motivoAnulacion; String? notas; bool get anulada; }
class ConsumoDetalle { MovimientoStock movimiento; String insumoNombre; Unidad unidad; String get cantidadTexto; } // cantidad en positivo
class ProduccionResumen { Produccion produccion; String? productoNombre; int? pedidoNumero; int cantidadInsumos; String? creadoPorNombre; }
class ProduccionDetalle { Produccion produccion; Producto? producto; PedidoResumen? pedido; List<ConsumoDetalle> consumos; String? creadoPorNombre; }

class ConsumoDatos { String insumoId; int cantidad; }   // cantidad > 0 (se descuenta del stock)
class ProduccionDatos { DateTime fecha; String? productoId; String descripcion; int cantidad; String? pedidoId; String? recetaId; String? notas; List<ConsumoDatos> consumos; }
class FiltroProduccion { DateTime desde; DateTime hasta; bool incluirAnuladas; }   // FiltroProduccion.ultimos30Dias()

abstract class ProduccionRepositorio {
  Stream<List<ProduccionResumen>> observarResumenes(FiltroProduccion filtro);  // orden: fecha desc
  Stream<ProduccionDetalle?> observarDetalle(String id);
  Future<String> registrar(ProduccionDatos datos);  // + salidas de stock. Los consumos pueden ser lista vacía.
  Future<void> anular(String id, {required String motivo});
}
```
Providers: `produccionRepositorioProvider`, `produccionesProvider` (family `FiltroProduccion`), `produccionDetalleProvider` (family id).

### 4.10 Tareas — `TareasRepositorio`
```dart
class Tarea {
  String id; String titulo; String? descripcion; TipoTarea tipo; PrioridadTarea prioridad; EstadoTarea estado;
  String asignadoA; DateTime? fechaVencimiento; String? pedidoId; DateTime? completadaEn; String? creadoPor; DateTime creadoEn;
  bool vencida(DateTime hoy);       // !estado.esFinal && fechaVencimiento < hoy
}
class TareaResumen { Tarea tarea; String asignadoNombre; String? creadoPorNombre; }
class TareaDatos { String titulo; String? descripcion; TipoTarea tipo; PrioridadTarea prioridad; String asignadoA; DateTime? fechaVencimiento; String? pedidoId; factory TareaDatos.desde(Tarea t); }
class FiltroTareas { String? asignadoA; bool incluirTerminadas; }

abstract class TareasRepositorio {
  Stream<List<TareaResumen>> observarMias({bool incluirTerminadas = false});  // orden: vencidas, prioridad, vencimiento
  Stream<List<TareaResumen>> observarTodas(FiltroTareas filtro);              // jefe
  Stream<TareaResumen?> observarPorId(String id);
  Stream<int> observarCantidadPendientesMias();
  Future<String> crear(TareaDatos datos);       // empleado: solo puede asignarse a sí mismo (ErrorDeNegocio)
  Future<void> actualizar(String id, TareaDatos datos);
  Future<void> cambiarEstado(String id, EstadoTarea estado);
}
```
Providers: `tareasRepositorioProvider`, `misTareasProvider` (family bool incluirTerminadas), `tareasProvider` (family `FiltroTareas`), `tareaProvider` (family id), `cantidadTareasPendientesProvider`.

### 4.11 Alertas — `AlertasRepositorio`
```dart
class Alerta { String id; TipoAlerta tipo; String titulo; String mensaje; String? entidadTipo; String? entidadId; DateTime? leidaEn; DateTime creadoEn; bool get leida; String? get rutaDestino; } // rutaDestino: ruta go_router a la entidad
abstract class AlertasRepositorio {
  Stream<List<Alerta>> observarTodas();          // orden: creadoEn desc (últimos 60 días)
  Stream<int> observarCantidadNoLeidas();
  Future<void> marcarLeida(String id);
  Future<void> marcarTodasLeidas();
}
```
Providers: `alertasRepositorioProvider`, `alertasProvider`, `cantidadAlertasNoLeidasProvider`.

### 4.12 Equipo (usuarios y permisos) — `EquipoRepositorio`
```dart
class Perfil { String id; String nombre; Rol rol; String? telefono; bool activo; bool get esJefe; }
abstract class EquipoRepositorio {
  Stream<List<Perfil>> observarPerfiles({bool incluirInactivos = false});  // orden: jefe primero, luego nombre
  Stream<Perfil?> observarPerfil(String id);
  Stream<Map<Modulo, NivelPermiso>> observarPermisos(String perfilId);
  Future<void> cambiarPermiso(String perfilId, Modulo modulo, NivelPermiso nivel); // funciona offline
  Future<void> actualizarMiPerfil({required String nombre, String? telefono});
  // ONLINE (lanzan SinConexion sin internet):
  Future<void> invitarEmpleado({required String nombre, required String email, String? telefono}); // envía email de invitación
  Future<void> desactivar(String perfilId);
  Future<void> reactivar(String perfilId);
}
```
Providers: `equipoRepositorioProvider`, `perfilesProvider` (family bool incluirInactivos), `perfilProvider` (family id), `permisosDePerfilProvider` (family perfilId).

### 4.13 Configuración — `ConfiguracionRepositorio`
```dart
class Configuracion { String nombreNegocio; int diasAvisoCumple; AlcanceAvisoCumple avisoCumpleAlcance; int habitualMinPedidos; int habitualMeses; }
enum AlcanceAvisoCumple { todos('Todos los clientes'), habituales('Solo clientes habituales') }
abstract class ConfiguracionRepositorio {
  Stream<Configuracion> observar();
  Future<void> actualizar(Configuracion c);   // solo jefe (la UI lo restringe; el servidor lo valida)
}
```
Providers: `configuracionRepositorioProvider`, `configuracionProvider`.

### 4.14 Estado de sincronización (`core/sync/`)
```dart
final estadoSyncProvider = StreamProvider<EstadoSync>(...);
class EstadoSync { bool conectado; bool subiendo; bool bajando; DateTime? ultimaSync; int cambiosPendientes; }
```
Lo muestra el núcleo (ícono en la barra). Las pantallas no lo necesitan.

### 4.15 Recetas y costeo (Fase 2) — `RecetasRepositorio`
```dart
class Receta { String id; String nombre; String? productoId; int rindeCantidad; String? rindeDescripcion; String? notas; DateTime? archivadoEn; bool get archivada; String get rindeTexto; }
class RecetaItem { String id; String recetaId; String insumoId; int cantidad; }
class RecetaItemDetalle { RecetaItem item; String insumoNombre; Unidad unidad; Dinero? costoEstimado; String get cantidadTexto; }
class RecetaResumen { Receta receta; String? productoNombre; int cantidadIngredientes; Dinero costoTotalEstimado; bool tieneCostoCompleto; Dinero get costoPorUnidadRinde; }
class RecetaDetalle {
  Receta receta; String? productoNombre; List<RecetaItemDetalle> items; bool tieneCostoCompleto;
  Dinero get costoTotalEstimado; Dinero get costoPorUnidadRinde;
  List<ConsumoDatos> escalarConsumos({int lotes = 1});
}
class RecetaItemDatos { String insumoId; int cantidad; }
class RecetaDatos { String nombre; String? productoId; int rindeCantidad; String? rindeDescripcion; String? notas; List<RecetaItemDatos> items; factory RecetaDatos.desde(RecetaDetalle d); }

class CostoProductoEstimado {
  String productoId; String recetaId; String recetaNombre; Dinero costoUnitario; Dinero? precioVenta; bool tieneCostoCompleto;
  Dinero? get margenUnitario;       // precioVenta - costoUnitario
  int? get margenPorcentaje;        // 0..100
  Dinero precioSugerido({int multiplicadorCosto = 3});
}

abstract class RecetasRepositorio {
  Stream<List<RecetaResumen>> observarActivas({String busqueda = '', String? productoId});
  Stream<RecetaDetalle?> observarDetalle(String id);
  Stream<CostoProductoEstimado?> observarCostoDeProducto(String productoId);
  Future<String> crear(RecetaDatos datos);
  Future<void> actualizar(String id, RecetaDatos datos);
  Future<void> archivar(String id);
}
```
Providers: `recetasRepositorioProvider`, `recetasProvider` (family String busqueda), `recetaDetalleProvider` (family String id), `costoProductoProvider` (family String productoId).

### 4.16 Compras sugeridas y reportes (Fase 2) — `ReportesRepositorio`
```dart
class ItemCompraSugerida {
  Insumo insumo; int stockActual; int stockMinimo; int requeridoPorPedidos; int sugeridoComprar; Dinero? costoEstimado;
  String get stockActualTexto; String get stockMinimoTexto; String get requeridoTexto; String get sugeridoTexto;
}
class ResumenComprasSugeridas { int diasHorizonte; int pedidosActivosEnHorizonte; List<ItemCompraSugerida> items; Dinero get costoTotalEstimado; }

class PeriodoMensual {
  int anio; int mes;
  factory PeriodoMensual.actual();
  PeriodoMensual get anterior; PeriodoMensual get siguiente;
  String get etiqueta; // "Octubre 2026"
}
class GastoPorCategoria { String categoriaId; String categoriaNombre; Dinero monto; int porcentajeEntero; }
class ResumenFinancieroMensual {
  PeriodoMensual periodo;
  Dinero ingresosPedidos; Dinero otrosIngresos;
  Dinero egresosCompras; Dinero egresosGastos; Dinero otrosEgresos;
  int pedidosEntregados; int pedidosCancelados;
  List<GastoPorCategoria> gastosPorCategoria;
  Dinero get totalIngresos; Dinero get totalEgresos; Dinero get resultadoNeto;
}
class RankingProducto { String nombre; String? productoId; int unidadesVendidas; Dinero ingresosTotales; }
class RankingCliente { String clienteId; String nombre; bool esHabitual; int cantidadPedidos; Dinero montoTotal; }
class RankingsPeriodo { PeriodoMensual periodo; List<RankingProducto> productosMasVendidos; List<RankingCliente> mejoresClientes; }

abstract class ReportesRepositorio {
  Stream<ResumenComprasSugeridas> observarComprasSugeridas({int diasHorizonte = 7});
  Stream<ResumenFinancieroMensual> observarResumenFinanciero(PeriodoMensual periodo);
  Stream<RankingsPeriodo> observarRankings(PeriodoMensual periodo);
}
```
Providers: `reportesRepositorioProvider`, `comprasSugeridasProvider` (family int diasHorizonte), `resumenFinancieroMensualProvider` (family `PeriodoMensual`), `rankingsPeriodoProvider` (family `PeriodoMensual`).
