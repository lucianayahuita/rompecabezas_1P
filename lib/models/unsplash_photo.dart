class UnsplashPhoto {
  final String id;
  final String thumbUrl;
  final String regularUrl;
  final String downloadLocation;
  final String authorName;
  final String authorProfileUrl;

  UnsplashPhoto({
    required this.id,
    required this.thumbUrl,
    required this.regularUrl,
    required this.downloadLocation,
    required this.authorName,
    required this.authorProfileUrl,
  });

  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    final urls = json['urls'] as Map<String, dynamic>;
    final links = json['links'] as Map<String, dynamic>;
    final user = json['user'] as Map<String, dynamic>;
    final userLinks = user['links'] as Map<String, dynamic>;

    return UnsplashPhoto(
      id: json['id'] as String,
      thumbUrl: urls['small'] as String,
      regularUrl: urls['regular'] as String,
      downloadLocation: links['download_location'] as String,
      authorName: user['name'] as String? ?? 'Autor desconocido',
      authorProfileUrl: userLinks['html'] as String? ?? '',
    );
  }
}
