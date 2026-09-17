import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controller/puzzle_controller.dart';
import '../controller/algorithm_controller.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'unsplash_gallery_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final int gridSize;
  final User user;

  const GamePlayScreen({super.key, required this.gridSize, required this.user});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late PuzzleController _controller;
  late AlgorithmController _algorithmController;

  @override
  void initState() {
    super.initState();
    _controller = PuzzleController(
      gridSize: widget.gridSize,
      userId: widget.user.id ?? -1,
    );
    _algorithmController = AlgorithmController();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showReferenceImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Imagen de referencia',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(imageBytes, fit: BoxFit.cover),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.accentAmber)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromUnsplash() async {
    final bytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(builder: (_) => const UnsplashGalleryScreen()),
    );
    if (bytes == null || !mounted) return;
    await _controller.useExternalImageBytes(bytes, size: widget.gridSize);
  }

  Future<void> _autoSolve() async {
    if (_controller.tiles.isEmpty || _controller.isCompleted) return;
    final messages = await _algorithmController.solveWithAStar(_controller);
    if (messages.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messages.first),
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
            center: Alignment(0, -0.6),
            radius: 1.3,
            colors: [AppColors.primaryLight, AppColors.primaryDark, AppColors.darkBackground],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([_controller, _algorithmController]),
            builder: (context, _) {
              return Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _controller.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.accentAmber),
                          )
                        : _buildBody(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 6),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rompecabezas ${widget.gridSize}×${widget.gridSize}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Deslizá las piezas hacia el espacio vacío',
                  style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_controller.tiles.isNotEmpty && !_controller.isCompleted)
            _iconButton(
              icon: Icons.auto_awesome,
              amber: true,
              loading: _algorithmController.isSolving,
              onTap: _autoSolve,
              tooltip: 'Resolver con A*',
            ),
          if (_controller.fullImageBytes != null) ...[
            const SizedBox(width: 8),
            _iconButton(
              icon: Icons.zoom_in_rounded,
              onTap: () => _showReferenceImage(context, _controller.fullImageBytes!),
              tooltip: 'Ver imagen completa',
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool amber = false,
    bool loading = false,
    String? tooltip,
  }) {
    final button = InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: amber ? AppColors.accentAmber.withOpacity(0.12) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: amber ? AppColors.accentAmber.withOpacity(0.35) : Colors.white.withOpacity(0.12),
          ),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentAmber),
              )
            : Icon(icon, size: 18, color: amber ? AppColors.accentAmber : Colors.white),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _glassButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Cámara',
                  onTap: () => _controller.capturePhotoAndCreatePuzzle(size: widget.gridSize),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _glassButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galería',
                  onTap: () => _controller.pickGalleryImageAndCreatePuzzle(size: widget.gridSize),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _glassButton(
                  icon: Icons.travel_explore_rounded,
                  label: 'Unsplash',
                  onTap: _pickFromUnsplash,
                ),
              ),
            ],
          ),

          if (_controller.tiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            _statsRow(),
          ],

          if (_controller.fullImageBytes != null) ...[
            const SizedBox(height: 12),
            _guideCard(),
          ],

          const SizedBox(height: 12),

          if (_controller.isCompleted) ...[
            _victoryBanner(),
            const SizedBox(height: 12),
          ],

          _controller.tiles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'Tomá una foto o elegí una de la galería para comenzar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15),
                  ),
                )
              : _board(),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statChip(Icons.touch_app_outlined, '${_controller.moveCount} mov.')),
        const SizedBox(width: 10),
        Expanded(child: _statChip(Icons.timer_outlined, _formatTime(_controller.elapsedSeconds))),
      ],
    );
  }

  Widget _statChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _guideCard() {
    return GestureDetector(
      onTap: () => _showReferenceImage(context, _controller.fullImageBytes!),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(_controller.fullImageBytes!, width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guía de armado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Tocá para ampliar la foto original', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _victoryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '¡Felicidades! Completaste el rompecabezas en ${_controller.moveCount} movimientos y ${_formatTime(_controller.elapsedSeconds)}. Se guardó en tu ranking.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _board() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _controller.gridSize,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: _controller.tiles.length,
          itemBuilder: (context, index) {
            final tile = _controller.tiles[index];
            final isTileEmpty = tile.isEmpty || tile.imageBytes.isEmpty;

            return GestureDetector(
              onTap: () => _controller.moveTile(index),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isTileEmpty ? Colors.black26 : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTileEmpty ? Colors.white.withOpacity(0.14) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: isTileEmpty
                    ? const SizedBox.expand()
                    : Image.memory(tile.imageBytes, fit: BoxFit.cover),
              ),
            );
          },
        ),
      ),
    );
  }
}
