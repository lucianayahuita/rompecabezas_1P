import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../controller/puzzle_controller.dart';
import '../controller/algorithm_controller.dart'; // Import del controlador de A*
import '../theme/app_colors.dart';

class GamePlayScreen extends StatefulWidget {
  final int gridSize;

  const GamePlayScreen({super.key, required this.gridSize});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late PuzzleController _controller;
  late AlgorithmController _algorithmController; // Controlador para el algoritmo A*

  @override
  void initState() {
    super.initState();
    _controller = PuzzleController(gridSize: widget.gridSize);
    _algorithmController = AlgorithmController();
  }

  /// Muestra la imagen completa de referencia en un diálogo flotante
  void _showReferenceImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Imagen de referencia',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Ejecuta la resolución automática usando la lógica A*
  Future<void> _autoSolve() async {
    if (_controller.tiles.isEmpty || _controller.isCompleted) return;

    // Llamada al método de A* pasando el controlador del puzzle o las fichas actuales
    await _algorithmController.solveWithAStar(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text('Rompecabezas ${widget.gridSize}x${widget.gridSize}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón A* en la barra de acciones superior
          if (_controller.tiles.isNotEmpty && !_controller.isCompleted)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
              tooltip: 'Resolver con A*',
              onPressed: _autoSolve,
            ),
          // Botón para ver la imagen de referencia si ya hay un juego en curso
          if (_controller.fullImageBytes != null)
            IconButton(
              icon: const Icon(Icons.preview, color: Colors.white),
              tooltip: 'Ver imagen completa',
              onPressed: () => _showReferenceImage(
                context,
                _controller.fullImageBytes!,
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Botones de Selección con Expanded para evitar desbordamiento
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                          onPressed: () {
                            _controller.capturePhotoAndCreatePuzzle(
                              size: widget.gridSize,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                          onPressed: () {
                            _controller.pickGalleryImageAndCreatePuzzle(
                              size: widget.gridSize,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Botón destacado de Resolución Automática (A*)
                if (_controller.tiles.isNotEmpty && !_controller.isCompleted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.psychology),
                        label: const Text(
                          'Resolver con A*',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _autoSolve,
                      ),
                    ),
                  ),

                if (_controller.tiles.isNotEmpty && !_controller.isCompleted)
                  const SizedBox(height: 12),

                // Vista previa miniatura fija cuando ya hay imagen seleccionada
                if (_controller.fullImageBytes != null)
                  GestureDetector(
                    onTap: () => _showReferenceImage(
                      context,
                      _controller.fullImageBytes!,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _controller.fullImageBytes!,
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guía de armado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Toca para ampliar la foto original',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.zoom_in, color: Colors.white54, size: 28),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Mensaje de victoria
                if (_controller.isCompleted)
                  // Código corregido para la línea 249
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.8), // <--- Cambiado aquí
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '¡Felicidades! Completaste el rompecabezas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Área principal de juego o bienvenida
                Expanded(
                  child: _controller.tiles.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'Toma una foto o elige una de la galería para comenzar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _controller.gridSize,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _controller.tiles.length,
                            itemBuilder: (context, index) {
                              final tile = _controller.tiles[index];
                              final isTileEmpty =
                                  tile.isEmpty || tile.imageBytes.isEmpty;

                              return GestureDetector(
                                onTap: () => _controller.moveTile(index),
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: isTileEmpty
                                        ? Colors.black38
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isTileEmpty
                                          ? Colors.white24
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: isTileEmpty
                                      ? const SizedBox.expand()
                                      : Image.memory(
                                          tile.imageBytes,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}