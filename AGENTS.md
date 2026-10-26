# Instrucciones para agentes (`AGENTS.md`)

Leé este archivo **antes** de escribir cualquier línea de código. Si algo de tu tarea contradice estas reglas, **frená y avisá**.

---

## 1. Qué es este proyecto
Aplicación de gestión para una repostería (tortas, tartas y mesas dulces por encargo), hecha en **Flutter** (Android + Windows) con **modo sin conexión primero** (SQLite local sincronizada con Supabase mediante PowerSync).

La **Fase 0** (esquema SQL, sincronización, autenticación, permisos, modelos, repositorios, operaciones de negocio, widgets compartidos, rutas y el módulo **Clientes** completo) **ya está hecha y probada**. Tu trabajo en las Fases 1–3 es **únicamente construir pantallas** sobre esa base.

---

## 2. Reglas inquebrantables

1. **Tocá solo los archivos listados en tu ficha de tarea.**
   Cada ficha en `docs/tareas/F1-XX-*.md` indica los archivos exactos que podés modificar o crear. **Todo lo demás está prohibido**, incluyendo:
   - `supabase/`, `powersync/`, `app/pubspec.yaml`
   - `app/lib/core/`, `app/lib/data/`, `app/lib/compartido/`
   - otros módulos dentro de `app/lib/features/`
   - `app/lib/core/router/` (las rutas ya apuntan a los archivos de tu módulo)

2. **Nunca llames a Supabase ni a SQLite desde una pantalla.**
   En `app/lib/features/` solo se importa:
   - `package:flutter/material.dart`
   - `package:flutter_riverpod/flutter_riverpod.dart`
   - `package:go_router/go_router.dart`
   - `package:jereposteria/compartido/compartido.dart`
   - `package:jereposteria/core/router/rutas.dart`
   - `package:jereposteria/core/sesion/sesion.dart`
   - `package:jereposteria/data/data.dart`
   - archivos del **mismo** módulo (`features/<tu_modulo>/...`)

   Un test de arquitectura (`app/test/arquitectura_test.dart`) falla si importás `supabase_flutter`, `powersync`, `sqlite3`, u otro módulo de `features/`.

3. **Dinero siempre con `Dinero` (centavos enteros). Prohibido `double` para plata.**
   El test de arquitectura busca `double` en montos/precios/saldos/totales y falla.

4. **Cantidades de insumos siempre en `int` (unidad base: `g`, `ml`, `u`) + `Unidad`.**
   Para pedirlas al usuario usá `CampoCantidad`; para mostrarlas, `TextoCantidad` o `unidad.formatear(cantidad)`.

5. **Usá los widgets compartidos.**
   Antes de armar cualquier pantalla, leé `docs/catalogo-widgets.md`. Prohibido:
   - usar `Scaffold` directo (usá `PantallaBase`)
   - usar `Colors.xxx` (usá el tema o `ColorEstado` + `InsigniaEstado`)
   - escribir rutas como texto (`'/pedidos/123'`); usá `Rutas.pedido(id)`
   - armar a mano el manejo de `AsyncValue` para listas (usá `ListaAsync` / `VistaAsync`)
   - armar tu propio botón de guardado con `CircularProgressIndicator` (usá `BotonGuardar`)

6. **Respetá los permisos.**
   Los botones que crean, editan o anulan deben ir envueltos en `RequierePermiso(modulo: ..., nivel: NivelPermiso.cargar / editar, child: ...)` o `SoloJefe(child: ...)`.

7. **Todo el texto visible al usuario va en español rioplatense** ("Cargá", "Elegí", "No tenés tareas pendientes", "¿Seguro que querés anular esta compra?").

8. **Si te falta un método, un campo o un widget: PARÁ y reportalo.**
   No inventes métodos en los repositorios, no agregues paquetes, no metas SQL en la pantalla. Explicá qué falta y en qué archivo de `data/` o `compartido/` debería agregarse.

---

## 3. Flujo de trabajo obligatorio para cada tarea

1. **Leer** la ficha de tu tarea en `docs/tareas/F1-XX-*.md`.
2. **Leer** las referencias indicadas en la ficha:
   - `docs/capa-de-datos.md` (sección de tu módulo)
   - `docs/catalogo-widgets.md`
   - `docs/pantallas-y-rutas.md`
   - `app/lib/features/clientes/` (el módulo modelo; copiá su estructura y estilo)
3. **Implementar** únicamente los archivos permitidos por la ficha.
4. **Correr la verificación:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool/check.ps1
   ```
   Tiene que terminar con **`TODO OK`** (0 errores de análisis, formato limpio, tests y test de arquitectura en verde).
5. **Entregar** un resumen corto con:
   - archivos modificados/creados
   - salida final de `tool/check.ps1`
   - cualquier duda o borde que hayas encontrado

---

## 4. Patrón estándar de una pantalla (resumen rápido)

### Lista (`xxx_lista_pantalla.dart`)
```dart
class ProveedoresListaPantalla extends ConsumerStatefulWidget {
  const ProveedoresListaPantalla({super.key});
  @override
  ConsumerState<ProveedoresListaPantalla> createState() => _ProveedoresListaPantallaState();
}

class _ProveedoresListaPantallaState extends ConsumerState<ProveedoresListaPantalla> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(proveedoresProvider(_busqueda));
    return PantallaBase(
      titulo: 'Proveedores',
      botonFlotante: RequierePermiso(
        modulo: Modulo.compras,
        nivel: NivelPermiso.cargar,
        child: FloatingActionButton.extended(
          onPressed: () => context.push(Rutas.proveedorNuevo),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo proveedor'),
        ),
      ),
      cuerpo: Column(
        children: [
          CampoBusqueda(onChanged: (v) => setState(() => _busqueda = v)),
          Expanded(
            child: ListaAsync<Proveedor>(
              valor: asyncItems,
              vacio: const EstadoVacio(
                icono: Icons.local_shipping_outlined,
                mensaje: 'Todavía no cargaste proveedores',
              ),
              itemBuilder: (context, p) => ListTile(
                leading: Avatar(p.nombre),
                title: Text(p.nombre),
                subtitle: p.telefono != null ? Text(p.telefono!) : null,
                onTap: () => context.push(Rutas.proveedorEditar(p.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Formulario (`xxx_formulario_pantalla.dart`)
```dart
class ProveedorFormularioPantalla extends ConsumerStatefulWidget {
  const ProveedorFormularioPantalla({super.key, this.id});
  final String? id;
  bool get esEdicion => id != null;
  @override
  ConsumerState<ProveedorFormularioPantalla> createState() => _ProveedorFormularioPantallaState();
}
```
- Si `esEdicion == true`, observar la entidad con su provider (`ref.watch(proveedorProvider(widget.id!))`), envolver en `VistaAsync` y precargar los campos **una sola vez** (`bool _inicializado = false`).
- Guardar con `BotonGuardar(onGuardar: () async { if (!_formKey.currentState!.validate()) return; ... if (mounted) context.pop(); })`.
- `BotonGuardar` ya muestra el error si el repositorio lanza `ErrorDeNegocio`.
