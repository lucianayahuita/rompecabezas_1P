import 'dart:typed_data';

class PuzzleTile {
  final int correctIndex; // Posición correcta en la matriz
  int currentIndex;       // Posición actual donde se encuentra
  final Uint8List imageBytes; // Imagen del recorte de la ficha
  final bool isEmpty;     // Define si es el espacio en blanco (pivote)

  PuzzleTile({
    required this.correctIndex,
    required this.currentIndex,
    required this.imageBytes,
    this.isEmpty = false,
  });
}