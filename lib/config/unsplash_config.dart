/// Configuración de acceso a la API de Unsplash.
///
/// La clave NO se hardcodea acá a propósito (para no dejarla guardada en el
/// código fuente / el historial de git). Se pasa al compilar o correr la app
/// con --dart-define, por ejemplo:
///
///   flutter run --dart-define=UNSPLASH_ACCESS_KEY=tu_access_key_aca
///
/// Si no se provee, [accessKey] queda vacío y la galería de Unsplash lo
/// avisa en pantalla en vez de fallar en silencio.
class UnsplashConfig {
  static const String accessKey = String.fromEnvironment('UNSPLASH_ACCESS_KEY');

  static bool get isConfigured => accessKey.isNotEmpty;
}
