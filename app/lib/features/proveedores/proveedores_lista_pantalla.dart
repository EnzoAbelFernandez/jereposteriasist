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
                final tema = Theme.of(context);
                final telefono = p.telefono?.trim();
                final email = p.email?.trim();
                final notas = p.notas?.trim();
                final tieneTelefono = telefono != null && telefono.isNotEmpty;
                final tieneEmail = email != null && email.isNotEmpty;
                final tieneNotas = notas != null && notas.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: puedeEditar
                        ? () => context.push(Rutas.proveedorEditar(p.id))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Avatar(p.nombre, radio: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.nombre,
                                  style: tema.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tieneTelefono) ...[
                                IconButton(
                                  icon: const Icon(Icons.chat_outlined),
                                  tooltip: 'WhatsApp',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => abrirWhatsApp(telefono),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_outlined),
                                  tooltip: 'Llamar',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => llamar(telefono),
                                ),
                              ],
                              if (puedeEditar)
                                const Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                          if (tieneTelefono || tieneEmail) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                if (tieneTelefono)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 15,
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        telefono,
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                if (tieneEmail)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 15,
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        email,
                                        style: tema.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tema
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                          if (tieneNotas) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.notes_outlined,
                                    size: 14,
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      notas,
                                      style: tema.textTheme.bodySmall?.copyWith(
                                        color:
                                            tema.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
