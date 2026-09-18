import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
import '../models/game_result.dart';
import '../models/puzzle_tile.dart';
import 'algorithm_controller.dart' show AlgorithmController;

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

  final int userId;

  List<PuzzleTile> tiles = [];
  int gridSize;
  bool isLoading = false;
  bool isCompleted = false;

  int moveCount = 0;
  DateTime? _startedAt;
  int? _elapsedSecondsAtFinish;
  bool _resultSaved = false;
  int get elapsedSeconds {
    if (_elapsedSecondsAtFinish != null) return _elapsedSecondsAtFinish!;
    if (_startedAt == null) return 0;
    return DateTime.now().difference(_startedAt!).inSeconds;
  }

  Uint8List? _fullImageBytes;
  Uint8List? get fullImageBytes => _fullImageBytes;

  PuzzleController({this.gridSize = 2, required this.userId});

  // LÓGICA DE MOVIMIENTO 
  // Convierte un indice lineal en coordenadas (x,y) para la logica de movimiento
  int obtenerFila(int indice) => indice ~/ gridSize;

  int obtenerColumna(int indice) => indice % gridSize;

  bool esMovimientoValido({
    required int filaPieza,
    required int colPieza,
    required int filaVacia,
    required int colVacia,
  }) {
    //esta en la misma columna pero la pieza esta por encima del pivote
    bool esArriba = (colPieza == colVacia) && (filaPieza - 1 == filaVacia);
    //estan en la misma columna pero la pieza esta por debajo del pivote
    bool esAbajo = (colPieza == colVacia) && (filaPieza + 1 == filaVacia);
    //estan en la misma fila pero la pieza esta a la izquierda del pivote
    bool esIzquierda = (filaPieza == filaVacia) && (colPieza - 1 == colVacia);
    //estan en la misma fila pero la pieza esta a la derecha del pivote
    bool esDerecha = (filaPieza == filaVacia) && (colPieza + 1 == colVacia);
    return esArriba || esAbajo || esIzquierda || esDerecha;
  }
  // Funcion para mover y verificar piezas, primero busca el pivote, trasnforma a coordenadas, 
  // verifica que solo sean movimientos validos y realiza el intercambio con un auxiliar.
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

      moveCount++;
      _verificarVictoria();
      notifyListeners();
    }
  }
  // Verifica que se ha ganado el juego, comparando si las piezas del tamblero actual y del correcto sean iguales.
  // si es asi lo guarda en la BD 
  void _verificarVictoria() {
    for (var tile in tiles) {
      if (tile.currentIndex != tile.correctIndex) {
        isCompleted = false;
        return;
      }
    }

    final bool justFinished = !isCompleted;
    isCompleted = true;

    if (justFinished) {
      _elapsedSecondsAtFinish ??= elapsedSeconds;
      _saveResult();
    }
  }

  Future<void> _saveResult() async {
    if (_resultSaved) return;
    _resultSaved = true;

    try {
      await DBHelper.insertResult(GameResult(
        userId: userId,
        level: '${gridSize}x$gridSize',
        moves: moveCount,
        timeInSeconds: elapsedSeconds,
        date: _formatDate(DateTime.now()),
      ));
    } catch (e) {
      debugPrint('No se pudo guardar el resultado: $e');
      _resultSaved = false;
    }
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}D:${two(dt.minute)}';
  }

  // MÉTODOS DE CÁMARA Y GALERÍA CON ISOLATES (COMPUTE)

  Future<bool> capturePhotoAndCreatePuzzle({int? size}) async {
    return _processImage(ImageSource.camera, size);
  }

  Future<bool> pickGalleryImageAndCreatePuzzle({int? size}) async {
    return _processImage(ImageSource.gallery, size);
  }
  // LOGICA PARA EL MANEJO DE CAMARA
  //Funcion: captura la imagen y la coloca en un tamano de 1080x1080, luego la pasa a un hilo secundario para recortarla y dividirla en piezas.
  Future<bool> _processImage(ImageSource source, int? size) async {
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
      // el teclado del sistema visible al cerrarse. Lo forzamos a ocultarse.
      await SystemChannels.textInput.invokeMethod('TextInput.hide');

      if (photo == null) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      final Uint8List bytes = await File(photo.path).readAsBytes();
      return _buildPuzzleFromBytes(bytes, size);
    } catch (e) {
      debugPrint("Error al procesar la imagen: $e");
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Arma el rompecabezas a partir de bytes de imagen que no vienen de la
  /// cámara/galería o de unsplash
  /// Reutiliza exactamente el mismo pipeline de recorte y mezcla.
  Future<bool> useExternalImageBytes(Uint8List bytes, {int? size}) async {
    isLoading = true;
    isCompleted = false;
    notifyListeners();

    try {
      return await _buildPuzzleFromBytes(bytes, size);
    } catch (e) {
      debugPrint("Error al procesar la imagen: $e");
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
  // FUNCION PRINCIPAL
  // envia el trabajo del procesamiento de la imagen a un hilo secundario. La almacena para vista previa, las corta y mezcla y enciende el contador. 
  Future<bool> _buildPuzzleFromBytes(Uint8List bytes, int? size) async {
    if (size != null) gridSize = size;

    // Ejecuta el recorte y guardado de imagen en un hilo secundario
    _CropResult result = await compute(
      _splitAndRoundImageTask,
      _CropParams(bytes, gridSize),
    );

    // Guarda la imagen completa recortada para la vista previa
    _fullImageBytes = result.fullImageBytes;

    // Mezcla realizando movimientos válidos para garantizar resolubilidad,
    // y lo confirma explícitamente con el teorema de paridad antes de
    // entregarle el tablero al jugador.
    tiles = _generarTablasSolucionable(result.tiles);

    moveCount = 0;
    _elapsedSecondsAtFinish = null;
    _resultSaved = false;
    _startedAt = DateTime.now();

    isLoading = false;
    notifyListeners();
    return true;
  }

  /// Mezcla el tablero y, antes de entregarlo, verifica con el teorema de
  /// paridad de inversiones que efectivamente sea solucionable. El mezclado
  /// por movimientos válidos ya lo garantiza matemáticamente, pero se vuelve
  /// a comprobar de forma explícita como red de seguridad; si por algún
  /// motivo fallara, se reintenta con una nueva mezcla.
  List<PuzzleTile> _generarTablasSolucionable(List<PuzzleTile> original) {
    for (int intento = 0; intento < 5; intento++) {
      final List<PuzzleTile> mezcladas = _mezclarPiezasGarantizadas(original);
      // mapea el tablero a numeros enteros
      final List<int> board = mezcladas.map((t) => t.correctIndex).toList();
      final int blankValue = mezcladas.firstWhere((t) => t.isEmpty).correctIndex;

      if (AlgorithmController.isSolvable(board, gridSize, blankValue)) {
        return mezcladas;
      }

      debugPrint('Mezcla no solucionable detectada, reintentando ($intento)...');
    }

    // No debería llegar nunca hasta acá; se devuelve la última mezcla igual.
    return _mezclarPiezasGarantizadas(original);
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
      // elige a la suerte y mueve completamente al azar
      if (vecinosValidos.isNotEmpty) {
        int indiceElegido = vecinosValidos[random.nextInt(vecinosValidos.length)];
        final aux = mezcladas[indiceElegido];
        mezcladas[indiceElegido] = mezcladas[indiceVacio];
        mezcladas[indiceVacio] = aux;
      }
    }
    // le asigna a cada tile su nuevo current index
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
  //toma la medida menor como referencia para recortar la imagen a un cuadrado
  int cropSize = original.width < original.height ? original.width : original.height;
  //toma la foto original y la recorta en un cuadrado perfecto
  img.Image square = img.copyCrop(
    original,
    x: (original.width - cropSize) ~/ 2,
    y: (original.height - cropSize) ~/ 2,
    width: cropSize,
    height: cropSize,
  );

  // Codifica la imagen completa cuadrada recortada
  Uint8List fullSquareBytes = Uint8List.fromList(img.encodePng(square));
  //calcula el tamano de cada ficha y elige al azar el indice del pivot, luego recorta cada pieza y le aplica bordes redondeados.
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

// Declara la función privada que recibe una imagen original y el radio de redondeo deseado
img.Image _applyRoundedCornersTask(img.Image src, {required int radius}) {
  // Crea una copia editable en memoria a partir de la imagen recibida (para no modificar la original)
  img.Image dst = img.Image.from(src);
  // Obtiene el ancho total de la imagen en píxeles y lo almacena en la variable 'w'
  int w = dst.width;
  // Obtiene el alto total de la imagen en píxeles y lo almacena en la variable 'h'
  int h = dst.height;

  for (int y = 0; y < h; y++) {
    // Inicia un bucle interno que recorre la fila actual de izquierda a derecha (eje X)
    for (int x = 0; x < w; x++) {
      // Define una bandera en 'false' que indicará si el píxel actual cae dentro de una punta de las 4 esquinas
      bool isCorner = false;
      // Evalúa si el píxel actual está dentro de la zona delimitada para la ESQUINA SUPERIOR IZQUIERDA
      if (x < radius && y < radius) {
        // Usa la fórmula del círculo (dx² + dy² > r²); si el píxel está fuera del radio de la curva, marca 'isCorner' como true
        if ((x - radius) * (x - radius) + (y - radius) * (y - radius) > radius * radius) isCorner = true;
      // Si no fue la anterior, evalúa si el píxel está dentro de la zona de la ESQUINA SUPERIOR DERECHA
      } else if (x >= w - radius && y < radius) {
        // Calcula la distancia matemática desde el centro de la curva superior derecha; si queda fuera, marca 'isCorner' como true
        if ((x - (w - radius - 1)) * (x - (w - radius - 1)) + (y - radius) * (y - radius) > radius * radius) isCorner = true;
      // Si no fue la anterior, evalúa si el píxel está dentro de la zona de la ESQUINA INFERIOR IZQUIERDA
      } else if (x < radius && y >= h - radius) {
        // Calcula la distancia matemática desde el centro de la curva inferior izquierda; si queda fuera, marca 'isCorner' como true
        if ((x - radius) * (x - radius) + (y - (h - radius - 1)) * (y - (h - radius - 1)) > radius * radius) isCorner = true;
      // Si no fue ninguna de las anteriores, evalúa si el píxel está dentro de la zona de la ESQUINA INFERIOR DERECHA
      } else if (x >= w - radius && y >= h - radius) {
        // Calcula la distancia matemática desde el centro de la curva inferior derecha; si queda fuera, marca 'isCorner' como true
        if ((x - (w - radius - 1)) * (x - (w - radius - 1)) + (y - (h - radius - 1)) * (y - (h - radius - 1)) > radius * radius) isCorner = true;
      }

      // Si la evaluación anterior determinó que el píxel está en la zona sobrante de una esquina
      if (isCorner) {
        // Cambia el color del píxel a transparente asignando valores RGBA (Red=0, Green=0, Blue=0, Alpha=0)
        dst.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  // Retorna la nueva imagen modificada con sus 4 esquinas recortadas en forma curva
  return dst;
}