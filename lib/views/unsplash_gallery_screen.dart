import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/unsplash_config.dart';
import '../models/unsplash_photo.dart';
import '../services/unsplash_service.dart';
import '../theme/app_colors.dart';

class _Category {
  final String label;
  final String query;
  const _Category(this.label, this.query);
}

/// Pantalla que deja elegir una foto de Unsplash por categoría para armar el
/// rompecabezas. Al tocar una foto, la descarga y devuelve sus bytes con
/// `Navigator.pop(context, bytes)`.
class UnsplashGalleryScreen extends StatefulWidget {
  const UnsplashGalleryScreen({super.key});

  @override
  State<UnsplashGalleryScreen> createState() => _UnsplashGalleryScreenState();
}

class _UnsplashGalleryScreenState extends State<UnsplashGalleryScreen> {
  static const List<_Category> _categories = [
    _Category('Naturaleza', 'nature landscape'),
    _Category('Animales', 'animals'),
    _Category('Ciudades', 'city skyline'),
    _Category('Arte', 'art painting'),
    _Category('Comida', 'food'),
    _Category('Deportes', 'sports'),
    _Category('Espacio', 'space galaxy'),
    _Category('Minimalista', 'minimal abstract'),
  ];

  final UnsplashService _service = UnsplashService();
  int _selectedCategory = 0;
  String? _downloadingPhotoId;
  late Future<List<UnsplashPhoto>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.searchPhotos(_categories[_selectedCategory].query);
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategory = index;
      _future = _service.searchPhotos(_categories[_selectedCategory].query);
    });
  }

  Future<void> _choosePhoto(UnsplashPhoto photo) async {
    if (_downloadingPhotoId != null) return;
    setState(() => _downloadingPhotoId = photo.id);

    try {
      final Uint8List bytes = await _service.downloadPhoto(photo);
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadingPhotoId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo descargar la foto: $e'),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.3,
            colors: [AppColors.primaryLight, AppColors.primaryDark, AppColors.darkBackground],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Elegí una foto',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Fotos de Unsplash por categoría',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!UnsplashConfig.isConfigured)
                Expanded(child: _buildNotConfigured())
              else ...[
                _buildCategoryChips(),
                const SizedBox(height: 10),
                Expanded(child: _buildGrid()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotConfigured() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_off_rounded, color: Colors.white.withOpacity(0.5), size: 40),
            const SizedBox(height: 14),
            const Text(
              'Falta configurar la clave de Unsplash',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Corré la app con --dart-define=UNSPLASH_ACCESS_KEY=tu_clave o completá dart_define.json.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => _selectCategory(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: selected
                    ? const LinearGradient(colors: [AppColors.accentAmberLight, AppColors.accentAmber])
                    : null,
                color: selected ? null : Colors.white.withOpacity(0.08),
                border: Border.all(color: selected ? Colors.transparent : Colors.white.withOpacity(0.14)),
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index].label,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    return FutureBuilder<List<UnsplashPhoto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentAmber));
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(0.5), size: 36),
                  const SizedBox(height: 12),
                  Text('${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => _selectCategory(_selectedCategory),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final photos = snapshot.data ?? [];
        if (photos.isEmpty) {
          return Center(
            child: Text('No encontramos fotos para esta categoría.',
                style: TextStyle(color: Colors.white.withOpacity(0.6))),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _photoTile(photos[index]),
        );
      },
    );
  }

  Widget _photoTile(UnsplashPhoto photo) {
    final downloading = _downloadingPhotoId == photo.id;
    return GestureDetector(
      onTap: () => _choosePhoto(photo),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photo.thumbUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.white.withOpacity(0.06));
              },
              errorBuilder: (context, error, stack) => Container(
                color: Colors.white.withOpacity(0.06),
                child: const Icon(Icons.broken_image_outlined, color: Colors.white38),
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Text(
              photo.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
          if (downloading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accentAmber),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
