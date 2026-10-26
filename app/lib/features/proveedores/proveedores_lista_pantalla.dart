import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/core/router/rutas.dart';
import 'package:jereposteria/data/data.dart';

class ProveedoresListaPantalla extends ConsumerStatefulWidget {
  const ProveedoresListaPantalla({super.key});

  @override
  ConsumerState<ProveedoresListaPantalla> createState() =>
      _ProveedoresListaPantallaState();
}

class _ProveedoresListaPantallaState
    extends ConsumerState<ProveedoresListaPantalla> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final asyncProveedores = ref.watch(proveedoresProvider(_busqueda));
    final puedeEditar = ref
        .watch(permisosActualesProvider)
        .puede(Modulo.compras, NivelPermiso.editar);

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
          CampoBusqueda(
            hint: 'Buscar proveedor...',
            onChanged: (v) => setState(() => _busqueda = v),
          ),
          Expanded(
            child: ListaAsync<Proveedor>(
              valor: asyncProveedores,
              vacio: const EstadoVacio(
                icono: Icons.local_shipping_outlined,
                mensaje: 'Todavía no cargaste proveedores',
              ),
              itemBuilder: (context, p) {
                final telefono = p.telefono?.trim();
                final email = p.email?.trim();
                final tieneTelefono = telefono != null && telefono.isNotEmpty;
                final subtitulo = tieneTelefono
                    ? telefono
                    : ((email != null && email.isNotEmpty) ? email : null);

                return ListTile(
                  leading: Avatar(p.nombre),
                  title: Text(p.nombre),
                  subtitle: subtitulo != null ? Text(subtitulo) : null,
                  trailing: tieneTelefono
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_outlined),
                              tooltip: 'WhatsApp',
                              onPressed: () => abrirWhatsApp(telefono),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined),
                              tooltip: 'Llamar',
                              onPressed: () => llamar(telefono),
                            ),
                          ],
                        )
                      : null,
                  onTap: puedeEditar
                      ? () => context.push(Rutas.proveedorEditar(p.id))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
