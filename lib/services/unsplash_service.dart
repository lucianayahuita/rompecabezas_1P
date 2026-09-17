import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/unsplash_config.dart';
import '../models/unsplash_photo.dart';

class UnsplashException implements Exception {
  final String message;
  UnsplashException(this.message);

  @override
  String toString() => message;
}

/// Cliente mínimo para la API pública de Unsplash: buscar fotos por
/// categoría/consulta y descargar la elegida para armar el rompecabezas.
class UnsplashService {
  static const String _baseUrl = 'https://api.unsplash.com';

  Map<String, String> get _headers => {
        'Authorization': 'Client-ID ${UnsplashConfig.accessKey}',
        'Accept-Version': 'v1',
      };

  Future<List<UnsplashPhoto>> searchPhotos(String query, {int perPage = 24}) async {
    if (!UnsplashConfig.isConfigured) {
      throw UnsplashException(
        'Falta configurar la clave de Unsplash (UNSPLASH_ACCESS_KEY).',
      );
    }

    final uri = Uri.parse('$_baseUrl/search/photos').replace(queryParameters: {
      'query': query,
      'per_page': '$perPage',
      'orientation': 'squarish',
      'content_filter': 'high',
    });

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw UnsplashException('La clave de Unsplash no es válida o fue rechazada.');
    }
    if (response.statusCode != 200) {
      throw UnsplashException('Unsplash respondió con error ${response.statusCode}.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? []);
    return results
        .map((json) => UnsplashPhoto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Descarga los bytes de la foto elegida y le avisa a Unsplash que se usó
  /// (requisito de sus guías de API para fotos que el usuario "descarga").
  Future<Uint8List> downloadPhoto(UnsplashPhoto photo) async {
    // Registro de descarga (no bloqueante si falla: no es crítico para el uso).
    try {
      await http.get(Uri.parse(photo.downloadLocation), headers: _headers);
    } catch (_) {
      // Ignorar: el tracking de descarga es best-effort.
    }

    final response = await http.get(Uri.parse(photo.regularUrl));
    if (response.statusCode != 200) {
      throw UnsplashException('No se pudo descargar la imagen elegida.');
    }
    return response.bodyBytes;
  }
}
