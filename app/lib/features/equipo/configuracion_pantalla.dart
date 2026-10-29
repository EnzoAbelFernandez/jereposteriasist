import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jereposteria/compartido/compartido.dart';
import 'package:jereposteria/data/data.dart';

class ConfiguracionPantalla extends ConsumerStatefulWidget {
  const ConfiguracionPantalla({super.key});

  @override
  ConsumerState<ConfiguracionPantalla> createState() =>
      _ConfiguracionPantallaState();
}

class _ConfiguracionPantallaState extends ConsumerState<ConfiguracionPantalla> {
  final _formKey = GlobalKey<FormState>();
  bool _inicializado = false;

  String _nombreNegocio = '';
  int? _diasAvisoCumple;
  AlcanceAvisoCumple? _avisoCumpleAlcance;
  int? _habitualMinPedidos;
  int? _habitualMeses;

  void _precargar(Configuracion c) {
    if (_inicializado) return;
    _inicializado = true;
    _nombreNegocio = c.nombreNegocio;
    _diasAvisoCumple = c.diasAvisoCumple;
    _avisoCumpleAlcance = c.avisoCumpleAlcance;
    _habitualMinPedidos = c.habitualMinPedidos;
    _habitualMeses = c.habitualMeses;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final nueva = Configuracion(
      nombreNegocio: _nombreNegocio.trim(),
      diasAvisoCumple: _diasAvisoCumple ?? 7,
      avisoCumpleAlcance: _avisoCumpleAlcance ?? AlcanceAvisoCumple.todos,
      habitualMinPedidos: _habitualMinPedidos ?? 3,
      habitualMeses: _habitualMeses ?? 12,
    );
    await ref.read(configuracionRepositorioProvider).actualizar(nueva);
    if (mounted) {
      mostrarExito(context, 'Configuración guardada');
    }
  }

  Future<void> _exportarBackup() async {
    final json = await ref
        .read(configuracionRepositorioProvider)
        .exportarBackupJson();
    if (mounted) {
      await mostrarDialogoExportacion(
        context,
        titulo: 'Exportación parcial (JSON)',
        nombreArchivo: 'respaldo_jereposteria.json',
        contenido: json,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final asyncConfig = ref.watch(configuracionProvider);
    final miPerfil = ref.watch(perfilActualProvider).value;

    return PantallaBase(
      titulo: 'Configuración',
      acciones: [
        IconButton(
          tooltip: 'Exportar datos parciales',
          icon: const Icon(Icons.backup_outlined),
          onPressed: _exportarBackup,
        ),
      ],
      cuerpo: VistaAsync<Configuracion>(
        valor: asyncConfig,
        builder: (context, config) {
          _precargar(config);
          return FormularioResponsivo(
            formKey: _formKey,
            campos: [
              if (miPerfil != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 20,
                        color: tema.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Perfil propio',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: tema.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Avatar(miPerfil.nombre, radio: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                miPerfil.nombre,
                                style: tema.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (miPerfil.telefono != null &&
                                  miPerfil.telefono!.isNotEmpty)
                                Text(
                                  miPerfil.telefono!,
                                  style: tema.textTheme.bodySmall?.copyWith(
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InsigniaEstado(
                          texto: miPerfil.rol.etiqueta,
                          color: miPerfil.esJefe
                              ? ColorEstado.info
                              : ColorEstado.neutro,
                          icono: miPerfil.esJefe
                              ? Icons.admin_panel_settings_outlined
                              : Icons.badge_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
                Separacion.chica,
              ],
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 20,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Datos de la pastelería',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              CampoTexto(
                etiqueta: 'Nombre de la repostería',
                valorInicial: _nombreNegocio,
                obligatorio: true,
                icono: Icons.storefront_outlined,
                onChanged: (v) => _nombreNegocio = v,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_outlined,
                      size: 18,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alertas de cumpleaños',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              CampoEntero(
                etiqueta: 'Avisar con cuántos días de anticipación',
                valorInicial: _diasAvisoCumple,
                minimo: 1,
                maximo: 60,
                obligatorio: true,
                onChanged: (v) => _diasAvisoCumple = v,
              ),
              SelectorOpcion<AlcanceAvisoCumple>(
                etiqueta: 'Avisar cumpleaños de',
                opciones: AlcanceAvisoCumple.values,
                valor: _avisoCumpleAlcance,
                etiquetaDe: (alcance) => alcance.etiqueta,
                onChanged: (v) => setState(() => _avisoCumpleAlcance = v),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 18,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cliente habitual automático',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              CampoEntero(
                etiqueta: 'Mínimo de pedidos entregados',
                valorInicial: _habitualMinPedidos ?? 3,
                minimo: 1,
                obligatorio: true,
                onChanged: (v) => _habitualMinPedidos = v,
              ),
              CampoEntero(
                etiqueta: 'En los últimos (meses)',
                valorInicial: _habitualMeses ?? 12,
                minimo: 1,
                maximo: 60,
                obligatorio: true,
                onChanged: (v) => _habitualMeses = v,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.backup_outlined,
                      size: 20,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exportación parcial de datos',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: tema.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Copiá un resumen parcial en formato JSON. No incluye todos los datos y no permite restaurar ni migrar la aplicación.',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _exportarBackup,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Ver datos para copiar (JSON)'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            botonGuardar: BotonGuardar(
              texto: 'Guardar configuración',
              onGuardar: _guardar,
            ),
          );
        },
      ),
    );
  }
}
