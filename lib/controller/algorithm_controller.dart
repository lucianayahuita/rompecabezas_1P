import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'puzzle_controller.dart';

/// Representa un estado del tablero durante la búsqueda A*.
class PuzzleState {
  final List<int> board;
  final int emptyIndex;
  final int gridSize;

  final PuzzleState? parent;
  final int? clickedTileIndex;

  final int g;
  final int h;

  PuzzleState({
    required this.board,
    required this.emptyIndex,
    required this.gridSize,
    this.parent,
    this.clickedTileIndex,
    this.g = 0,
    this.h = 0,
  });

  int get f => g + h;

  /// Clave única para identificar este arreglo de piezas en los mapas de A*.
  String get id => board.join(',');

  bool isSolved() {
    for (int i = 0; i < board.length; i++) {
      if (board[i] != i) return false;
    }
    return true;
  }
}

/// Parámetros que se pasan al isolate de `compute()`.
class _AStarParams {
  final List<int> board;
  final int emptyIndex;
  final int gridSize;
  final int blankValue;

  _AStarParams({
    required this.board,
    required this.emptyIndex,
    required this.gridSize,
    required this.blankValue,
  });
}

class AlgorithmController extends ChangeNotifier {
  bool _isSolving = false;
  bool get isSolving => _isSolving;

  /// Máximo de estados a explorar antes de rendirse. Con Manhattan + conflicto
  /// lineal, un 4x4 barajado razonablemente se resuelve muy por debajo de esto;
  /// el límite solo evita que un caso patológico cuelgue la app para siempre.
  static const int _maxNodesExplored = 300000;

  /// Verifica si un rompecabezas es teóricamente solucionable usando el
  /// teorema clásico de paridad de inversiones para el "N-puzzle".
  ///
  /// [board] es la lista de valores correctos (correctIndex) en el orden
  /// actual de las piezas, y [blankValue] es el valor que identifica al
  /// espacio vacío dentro de esa lista.
  static bool isSolvable(List<int> board, int gridSize, int blankValue) {
    final List<int> sequence = board.where((v) => v != blankValue).toList();

    int inversions = 0;
    for (int i = 0; i < sequence.length; i++) {
      for (int j = i + 1; j < sequence.length; j++) {
        if (sequence[i] > sequence[j]) inversions++;
      }
    }

    if (gridSize.isOdd) {
      // Tablero de lado impar (ej. 3x3): solucionable si las inversiones son pares.
      return inversions.isEven;
    }

    // Tablero de lado par (ej. 4x4): depende también de la fila del vacío
    // contada desde abajo (1-indexed).
    final int blankIndex = board.indexOf(blankValue);
    final int blankRowFromBottom = gridSize - (blankIndex ~/ gridSize);

    if (blankRowFromBottom.isEven) {
      return inversions.isOdd;
    } else {
      return inversions.isEven;
    }
  }

  /// Método principal ejecutado desde la pantalla de juego. Devuelve mensajes
  /// de diagnóstico (vacío si resolvió y animó todo con éxito).
  Future<List<String>> solveWithAStar(PuzzleController puzzleController) async {
    if (_isSolving || puzzleController.isCompleted) return const [];

    _isSolving = true;
    notifyListeners();

    final List<String> messages = [];

    try {
      final int gridSize = puzzleController.gridSize;
      final List<int> initialBoard =
          puzzleController.tiles.map((tile) => tile.correctIndex).toList();

      final int emptyIndex = puzzleController.tiles.indexWhere((t) => t.isEmpty);
      final int blankValue = puzzleController.tiles[emptyIndex].correctIndex;

      if (!isSolvable(initialBoard, gridSize, blankValue)) {
        // Por construcción (el mezclado solo usa movimientos válidos) esto no
        // debería pasar nunca, pero lo verificamos explícitamente antes de
        // gastar tiempo de cómputo en una búsqueda imposible.
        messages.add('Este tablero no es solucionable (verificación de paridad).');
        return messages;
      }

      final List<int> solutionMoves = await compute(
        _runAStarIsolate,
        _AStarParams(
          board: initialBoard,
          emptyIndex: emptyIndex,
          gridSize: gridSize,
          blankValue: blankValue,
        ),
      );

      if (solutionMoves.isEmpty) {
        messages.add('No se encontró solución dentro del límite de búsqueda.');
      } else {
        await _animateSolution(puzzleController, solutionMoves);
      }
    } finally {
      _isSolving = false;
      notifyListeners();
    }

    return messages;
  }

  Future<void> _animateSolution(
    PuzzleController puzzleController,
    List<int> moves,
  ) async {
    for (final int targetIndex in moves) {
      puzzleController.moveTile(targetIndex);
      await Future.delayed(const Duration(milliseconds: 220));
    }
  }
}

// ==========================================
// FUNCIONES DE NIVEL SUPERIOR (corren en un isolate vía compute())
// ==========================================

/// Punto de entrada para `compute()`. Debe ser una función de nivel superior
/// (no un método de instancia) para poder ejecutarse en otro isolate.
List<int> _runAStarIsolate(_AStarParams params) {
  final PuzzleState startState = PuzzleState(
    board: params.board,
    emptyIndex: params.emptyIndex,
    gridSize: params.gridSize,
    g: 0,
    h: _heuristic(params.board, params.gridSize, params.blankValue),
  );

  // Cola de prioridad por f = g + h: O(log n) para insertar y extraer el
  // mínimo, en vez de ordenar una lista completa en cada iteración.
  final PriorityQueue<PuzzleState> openQueue = PriorityQueue<PuzzleState>(
    (a, b) => a.f != b.f ? a.f.compareTo(b.f) : a.h.compareTo(b.h),
  );
  openQueue.add(startState);

  // Mejor costo `g` conocido para cada tablero visto, en O(1). Reemplaza el
  // `Set` + `List.any()` (búsquedas lineales) de la versión anterior.
  final Map<String, int> bestG = {startState.id: 0};

  int nodesExplored = 0;

  while (openQueue.isNotEmpty) {
    final PuzzleState current = openQueue.removeFirst();
    nodesExplored++;

    if (current.isSolved()) {
      return _reconstructPath(current);
    }

    if (nodesExplored > AlgorithmController._maxNodesExplored) {
      return const [];
    }

    // Si ya encontramos un camino mejor (o igual) hacia este mismo tablero
    // después de encolar este nodo, lo saltamos.
    if (current.g > (bestG[current.id] ?? 1 << 30)) continue;

    for (final PuzzleState neighbor in _getNeighbors(current, params.blankValue)) {
      final int? knownG = bestG[neighbor.id];
      if (knownG == null || neighbor.g < knownG) {
        bestG[neighbor.id] = neighbor.g;
        openQueue.add(neighbor);
      }
    }
  }

  return const [];
}

List<PuzzleState> _getNeighbors(PuzzleState state, int blankValue) {
  final List<PuzzleState> neighbors = [];
  final int emptyIdx = state.emptyIndex;
  final int size = state.gridSize;

  final int row = emptyIdx ~/ size;
  final int col = emptyIdx % size;

  final List<int?> targets = [
    row > 0 ? emptyIdx - size : null, // arriba
    row < size - 1 ? emptyIdx + size : null, // abajo
    col > 0 ? emptyIdx - 1 : null, // izquierda
    col < size - 1 ? emptyIdx + 1 : null, // derecha
  ];

  for (final int? targetIdx in targets) {
    if (targetIdx == null) continue;

    final List<int> newBoard = List<int>.from(state.board);
    newBoard[emptyIdx] = state.board[targetIdx];
    newBoard[targetIdx] = state.board[emptyIdx];

    final int newG = state.g + 1;

    neighbors.add(
      PuzzleState(
        board: newBoard,
        emptyIndex: targetIdx,
        gridSize: size,
        parent: state,
        clickedTileIndex: targetIdx,
        g: newG,
        h: _heuristic(newBoard, size, blankValue),
      ),
    );
  }

  return neighbors;
}

/// Distancia de Manhattan + conflicto lineal: una heurística mucho más
/// ajustada que Manhattan sola, clave para que 4x4 (15-puzzle) sea resoluble
/// en un tiempo razonable con A* clásico.
int _heuristic(List<int> board, int gridSize, int blankValue) {
  int manhattan = 0;

  for (int index = 0; index < board.length; index++) {
    final int value = board[index];
    if (value == blankValue) continue;

    final int curRow = index ~/ gridSize;
    final int curCol = index % gridSize;
    final int targetRow = value ~/ gridSize;
    final int targetCol = value % gridSize;

    manhattan += (curRow - targetRow).abs() + (curCol - targetCol).abs();
  }

  return manhattan + 2 * _linearConflicts(board, gridSize, blankValue);
}

int _linearConflicts(List<int> board, int gridSize, int blankValue) {
  int conflicts = 0;

  // Conflictos por fila
  for (int row = 0; row < gridSize; row++) {
    final List<int> rowValues = [];
    for (int col = 0; col < gridSize; col++) {
      final int value = board[row * gridSize + col];
      if (value == blankValue) continue;
      if (value ~/ gridSize == row) rowValues.add(value);
    }
    conflicts += _countConflictsInLine(rowValues);
  }

  // Conflictos por columna
  for (int col = 0; col < gridSize; col++) {
    final List<int> colValues = [];
    for (int row = 0; row < gridSize; row++) {
      final int value = board[row * gridSize + col];
      if (value == blankValue) continue;
      if (value % gridSize == col) colValues.add(value);
    }
    conflicts += _countConflictsInLine(colValues);
  }

  return conflicts;
}

/// Cuenta pares de piezas fuera de orden dentro de una misma fila/columna
/// objetivo (conflicto lineal clásico de Hansson/Mayer/Yung).
int _countConflictsInLine(List<int> values) {
  int conflicts = 0;
  for (int i = 0; i < values.length; i++) {
    for (int j = i + 1; j < values.length; j++) {
      if (values[i] > values[j]) conflicts++;
    }
  }
  return conflicts;
}

List<int> _reconstructPath(PuzzleState targetState) {
  final List<int> moves = [];
  PuzzleState? current = targetState;

  while (current?.parent != null) {
    moves.add(current!.clickedTileIndex!);
    current = current.parent;
  }

  return moves.reversed.toList();
}
