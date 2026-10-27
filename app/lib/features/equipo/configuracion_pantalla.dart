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
        titulo: 'Copia de seguridad (JSON)',
        nombreArchivo: 'respaldo_jereposteria.json',
        contenido: json,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncConfig = ref.watch(configuracionProvider);

    return PantallaBase(
      titulo: 'Configuración',
      acciones: [
        IconButton(
          tooltip: 'Exportar respaldo',
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
              CampoTexto(
                etiqueta: 'Nombre de la repostería',
                valorInicial: _nombreNegocio,
                obligatorio: true,
                icono: Icons.storefront_outlined,
                onChanged: (v) => _nombreNegocio = v,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cumpleaños',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
                child: Text(
                  'Cliente habitual automático',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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
            ],
            botonGuardar: BotonGuardar(texto: 'Guardar', onGuardar: _guardar),
          );
        },
      ),
    );
  }
}
