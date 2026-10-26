import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp hacia [telefono] con un [mensaje] opcional prellenado.
/// Normaliza teléfonos argentinos (si tiene 10 dígitos sin código de país, antepone `549`).
Future<bool> abrirWhatsApp(String telefono, {String? mensaje}) async {
  var digitos = telefono.replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return false;
  if (digitos.startsWith('0')) {
    digitos = digitos.substring(1);
  }
  if (!digitos.startsWith('54') && digitos.length == 10) {
    digitos = '549$digitos';
  }
  final query = (mensaje != null && mensaje.trim().isNotEmpty)
      ? '?text=${Uri.encodeComponent(mensaje.trim())}'
      : '';
  final uri = Uri.parse('https://wa.me/$digitos$query');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Inicia una llamada telefónica a [telefono].
Future<bool> llamar(String telefono) async {
  final limpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
  if (limpio.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: limpio);
  return launchUrl(uri);
}
