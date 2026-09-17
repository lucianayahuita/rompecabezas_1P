import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/puzzle_tile.dart';

// Estructura de datos auxiliar para pasar parámetros al hilo secundario (Isolate)
class _CropParams {
  final Uint8List bytes;
  final int grid;

  _CropParams(this.bytes, this.grid);
}

// Resultado del procesamiento en Isolate (Piezas + Imagen Cuadrada Completa)
class _CropResult {
  final List<PuzzleTile> tiles;
  final Uint8List fullImageBytes;

  _CropResult(this.tiles, this.fullImageBytes);
}

class PuzzleController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  List<PuzzleTile> tiles = [];
  int gridSize;
  bool isLoading = false;
  bool isCompleted = false;

  // Propiedad requerida por GamePlayScreen para mostrar la vista previa
  Uint8List? _fullImageBytes;
  Uint8List? get fullImageBytes => _fullImageBytes;

  PuzzleController({this.gridSize = 2});

  // LÓGICA DE MOVIMIENTO 

  int obtenerFila(int indice) => indice ~/ gridSize;

  int obtenerColumna(int indice) => indice % gridSize;

  bool esMovimientoValido({
    required int filaPieza,
    required int colPieza,
    required int filaVacia,
    required int colVacia,
  }) {
    bool esArriba = (colPieza == colVacia) && (filaPieza - 1 == filaVacia);
    bool esAbajo = (colPieza == colVacia) && (filaPieza + 1 == filaVacia);
    bool esIzquierda = (filaPieza == filaVacia) && (colPieza - 1 == colVacia);
    bool esDerecha = (filaPieza == filaVacia) && (colPieza + 1 == colVacia);
    return esArriba || esAbajo || esIzquierda || esDerecha;
  }

  void moveTile(int indicePiezaTocada) {
    if (isCompleted) return;

    int indiceVacio = tiles.indexWhere((tile) => tile.isEmpty);
    if (indiceVacio == -1) return;

    int filaPieza = obtenerFila(indicePiezaTocada);
    int colPieza = obtenerColumna(indicePiezaTocada);
    int filaVacia = obtenerFila(indiceVacio);
    int colVacia = obtenerColumna(indiceVacio);

    if (esMovimientoValido(
      filaPieza: filaPieza,
      colPieza: colPieza,
      filaVacia: filaVacia,
      colVacia: colVacia,
    )) {
      final aux = tiles[indicePiezaTocada];
      tiles[indicePiezaTocada] = tiles[indiceVacio];
      tiles[indiceVacio] = aux;

      tiles[indicePiezaTocada].currentIndex = indicePiezaTocada;
      tiles[indiceVacio].currentIndex = indiceVacio;

      _verificarVictoria();
      notifyListeners();
    }
  }

  void _verificarVictoria() {
    for (var tile in tiles) {
      if (tile.currentIndex != tile.correctIndex) {
        isCompleted = false;
        return;
      }
    }
    isCompleted = true;
  }

  // MÉTODOS DE CÁMARA Y GALERÍA CON ISOLATES (COMPUTE)

  Future<bool> capturePhotoAndCreatePuzzle({int? size}) async {
    return _processImage(ImageSource.camera, size);
  }

  Future<bool> pickGalleryImageAndCreatePuzzle({int? size}) async {
    return _processImage(ImageSource.gallery, size);
  }

  Future<bool> _processImage(ImageSource source, int? size) async {
    if (size != null) gridSize = size;
    isLoading = true;
    isCompleted = false;
    notifyListeners();

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (photo == null) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      final Uint8List bytes = await File(photo.path).readAsBytes();

      // Ejecuta el recorte y guardado de imagen en un hilo secundario
      _CropResult result = await compute(
        _splitAndRoundImageTask,
        _CropParams(bytes, gridSize),
      );

      // Guarda la imagen completa recortada para la vista previa
      _fullImageBytes = result.fullImageBytes;

      // Mezcla realizando movimientos válidos para garantizar resolubilidad
      tiles = _mezclarPiezasGarantizadas(result.tiles);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error al procesar la imagen: $e");
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mezcla inteligente: Simula movimientos aleatorios válidos para asegurar que el tablero sea 100% resoluble
  List<PuzzleTile> _mezclarPiezasGarantizadas(List<PuzzleTile> list) {
    List<PuzzleTile> mezcladas = List.from(list);
    final random = Random();
    int totalMovimientos = gridSize * gridSize * 20;

    for (int i = 0; i < totalMovimientos; i++) {
      int indiceVacio = mezcladas.indexWhere((tile) => tile.isEmpty);
      List<int> vecinosValidos = [];

      int filaVacia = obtenerFila(indiceVacio);
      int colVacia = obtenerColumna(indiceVacio);

      for (int j = 0; j < mezcladas.length; j++) {
        if (esMovimientoValido(
          filaPieza: obtenerFila(j),
          colPieza: obtenerColumna(j),
          filaVacia: filaVacia,
          colVacia: colVacia,
        )) {
          vecinosValidos.add(j);
        }
      }

      if (vecinosValidos.isNotEmpty) {
        int indiceElegido = vecinosValidos[random.nextInt(vecinosValidos.length)];
        final aux = mezcladas[indiceElegido];
        mezcladas[indiceElegido] = mezcladas[indiceVacio];
        mezcladas[indiceVacio] = aux;
      }
    }

    for (int i = 0; i < mezcladas.length; i++) {
      mezcladas[i].currentIndex = i;
    }

    return mezcladas;
  }
}

// FUNCIÓN AISLADA (Se ejecuta fuera del UI Thread)
_CropResult _splitAndRoundImageTask(_CropParams params) {
  img.Image? original = img.decodeImage(params.bytes);
  if (original == null) return _CropResult([], Uint8List(0));

  int cropSize = original.width < original.height ? original.width : original.height;

  img.Image square = img.copyCrop(
    original,
    x: (original.width - cropSize) ~/ 2,
    y: (original.height - cropSize) ~/ 2,
    width: cropSize,
    height: cropSize,
  );

  // Codifica la imagen completa cuadrada recortada
  Uint8List fullSquareBytes = Uint8List.fromList(img.encodePng(square));

  int pieceSize = cropSize ~/ params.grid;
  List<PuzzleTile> generatedTiles = [];
  int totalTiles = params.grid * params.grid;

  final random = Random();
  int randomEmptyIndex = random.nextInt(totalTiles);

  for (int y = 0; y < params.grid; y++) {
    for (int x = 0; x < params.grid; x++) {
      int index = y * params.grid + x;
      bool isBlank = (index == randomEmptyIndex);

      if (isBlank) {
        generatedTiles.add(PuzzleTile(
          correctIndex: index,
          currentIndex: index,
          imageBytes: Uint8List(0),
          isEmpty: true,
        ));
      } else {
        img.Image piece = img.copyCrop(
          square,
          x: x * pieceSize,
          y: y * pieceSize,
          width: pieceSize,
          height: pieceSize,
        );

        img.Image roundedPiece = _applyRoundedCornersTask(piece, radius: 12);
        Uint8List encodedPng = Uint8List.fromList(img.encodePng(roundedPiece));

        generatedTiles.add(PuzzleTile(
          correctIndex: index,
          currentIndex: index,
          imageBytes: encodedPng,
          isEmpty: false,
        ));
      }
    }
  }

  return _CropResult(generatedTiles, fullSquareBytes);
}

img.Image _applyRoundedCornersTask(img.Image src, {required int radius}) {
  img.Image dst = img.Image.from(src);
  int w = dst.width;
  int h = dst.height;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool isCorner = false;
      if (x < radius && y < radius) {
        if ((x - radius) * (x - radius) + (y - radius) * (y - radius) > radius * radius) isCorner = true;
      } else if (x >= w - radius && y < radius) {
        if ((x - (w - radius - 1)) * (x - (w - radius - 1)) + (y - radius) * (y - radius) > radius * radius) isCorner = true;
      } else if (x < radius && y >= h - radius) {
        if ((x - radius) * (x - radius) + (y - (h - radius - 1)) * (y - (h - radius - 1)) > radius * radius) isCorner = true;
      } else if (x >= w - radius && y >= h - radius) {
        if ((x - (w - radius - 1)) * (x - (w - radius - 1)) + (y - (h - radius - 1)) * (y - (h - radius - 1)) > radius * radius) isCorner = true;
      }

      if (isCorner) {
        dst.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  return dst;
}