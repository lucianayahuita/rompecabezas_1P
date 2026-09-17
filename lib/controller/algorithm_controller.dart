import 'dart:async';
import 'package:flutter/material.dart';
import 'puzzle_controller.dart';

/// 1. TABLERO & 2. ESTADO
/// Representa el estado actual del tablero de juego.
class PuzzleState {
  final List<int> board; // Lista 1D que representa el tablero (ej: [0, 1, 2, ...])
  final int emptyIndex;  // Índice donde está el hueco/pieza vacía
  final int gridSize;    // Tamaño de la matriz (N x N)
  
  final PuzzleState? parent;    // Referencia al estado padre para reconstruir el camino
  final int? clickedTileIndex;  // Índice físico que la UI debe presionar para llegar a este estado
  final String? moveMade;       // Nombre de la dirección realizada
  
  final int g; // 6. Costo acumulado (pasos desde el inicio)
  final int h; // 5. Heurística (distancia estimada al objetivo)

  PuzzleState({
    required this.board,
    required this.emptyIndex,
    required this.gridSize,
    this.parent,
    this.clickedTileIndex,
    this.moveMade,
    this.g = 0,
    this.h = 0,
  });

  /// 7. f = g + h (Costo total estimado)
  int get f => g + h;

  /// Clave única para guardar el estado en la lista CLOSED y evitar ciclos
  String get id => board.join(',');

  /// Verifica si el tablero actual es el estado objetivo (resuelto)
  bool isSolved() {
    for (int i = 0; i < board.length; i++) {
      if (board[i] != i) return false;
    }
    return true;
  }
}

class AlgorithmController extends ChangeNotifier {
  bool _isSolving = false;
  bool get isSolving => _isSolving;

  /// Método principal ejecutado desde la pantalla
  Future<void> solveWithAStar(PuzzleController puzzleController) async {
    if (_isSolving || puzzleController.isCompleted) return;

    _isSolving = true;
    notifyListeners();

    // 1 & 2. TABLERO Y ESTADO INICIAL
    final int gridSize = puzzleController.gridSize;
    final List<int> initialBoard = puzzleController.tiles
        .map((tile) => tile.correctIndex)
        .toList();

    // CORRECCIÓN 1: Buscar el índice del espacio vacío directamente desde las propiedades del tile
    final int emptyIndexInController = puzzleController.tiles
        .indexWhere((tile) => tile.isEmpty || tile.imageBytes.isEmpty);

    // Si no se detectó por propiedad, usar el índice por defecto
    final int emptyIndex = (emptyIndexInController != -1)
        ? emptyIndexInController
        : initialBoard.indexOf(puzzleController.tiles.length - 1);

    PuzzleState initialState = PuzzleState(
      board: initialBoard,
      emptyIndex: emptyIndex,
      gridSize: gridSize,
      g: 0,
      h: _calculateManhattanDistance(initialBoard, gridSize),
    );

    // 9. EJECUTAR A*
    List<int> solutionMoves = _runAStar(initialState);

    // 11 & 12. LISTA DE MOVIMIENTOS Y ANIMAR EN FLUTTER
    if (solutionMoves.isNotEmpty) {
      await _animateSolution(puzzleController, solutionMoves);
    }

    _isSolving = false;
    notifyListeners();
  }

  // ==========================================
  // 5. HEURÍSTICA h (Distancia de Manhattan)
  // ==========================================
  int _calculateManhattanDistance(List<int> board, int gridSize) {
    int totalDistance = 0;

    for (int currentIndex = 0; currentIndex < board.length; currentIndex++) {
      int value = board[currentIndex];
      
      // Ignoramos la pieza vacía para la heurística
      if (value == board.length - 1) continue;

      // Fila y Columna actual
      int currentTileRow = currentIndex ~/ gridSize;
      int currentTileCol = currentIndex % gridSize;

      // Fila y Columna donde DEBERÍA estar
      int targetRow = value ~/ gridSize;
      int targetCol = value % gridSize;

      // Suma de distancias verticales y horizontales
      totalDistance += (currentTileRow - targetRow).abs() +
                       (currentTileCol - targetCol).abs();
    }

    return totalDistance;
  }

  // ==========================================
  // 3. MOVIMIENTOS VÁLIDOS Y 4. VECINOS
  // ==========================================
  List<PuzzleState> _getNeighbors(PuzzleState currentState) {
    List<PuzzleState> neighbors = [];
    int emptyIdx = currentState.emptyIndex;
    int size = currentState.gridSize;

    int row = emptyIdx ~/ size;
    int col = emptyIdx % size;

    // Mapa de posiciones contiguas que pueden moverse hacia el espacio vacío
    final Map<String, int?> possibleMoves = {
      'ARRIBA': (row > 0) ? emptyIdx - size : null,
      'ABAJO': (row < size - 1) ? emptyIdx + size : null,
      'IZQUIERDA': (col > 0) ? emptyIdx - 1 : null,
      'DERECHA': (col < size - 1) ? emptyIdx + 1 : null,
    };

    possibleMoves.forEach((direction, targetIdx) {
      // 3. Verificar que el movimiento esté dentro de los límites del tablero
      if (targetIdx != null) {
        List<int> newBoard = List.from(currentState.board);
        int tileToMove = newBoard[targetIdx];

        // Intercambiar pieza vacía con la pieza que se desliza
        newBoard[emptyIdx] = tileToMove;
        newBoard[targetIdx] = currentState.board[emptyIdx];

        // 6 & 7. Calcular g y h para el vecino
        int newG = currentState.g + 1;
        int newH = _calculateManhattanDistance(newBoard, size);

        // 4. CORRECCIÓN 2: Guardamos `clickedTileIndex: targetIdx`
        // Esto indica qué casilla debe presionar la UI para realizar este movimiento.
        neighbors.add(
          PuzzleState(
            board: newBoard,
            emptyIndex: targetIdx,
            gridSize: size,
            parent: currentState,
            clickedTileIndex: targetIdx,
            moveMade: direction,
            g: newG,
            h: newH,
          ),
        );
      }
    });

    return neighbors;
  }

  // ==========================================
  // 8. OPEN / CLOSED & 9. A*
  // ==========================================
  List<int> _runAStar(PuzzleState startState) {
    // 8. OPEN (Estados pendientes por explorar)
    List<PuzzleState> openList = [startState];

    // 8. CLOSED (Estados ya explorados para evitar bucles)
    Set<String> closedSet = {};

    while (openList.isNotEmpty) {
      // Ordenar por el menor costo 'f = g + h'
      openList.sort((a, b) => a.f.compareTo(b.f));
      
      // Obtener el nodo con menor 'f'
      PuzzleState currentState = openList.removeAt(0);

      // Si ya está resuelto, reconstruimos la ruta
      if (currentState.isSolved()) {
        // 10. RECONSTRUIR CAMINO
        return _reconstructPath(currentState);
      }

      closedSet.add(currentState.id);

      // Evaluar vecinos
      for (PuzzleState neighbor in _getNeighbors(currentState)) {
        if (closedSet.contains(neighbor.id)) continue;

        // Si el vecino ya está en la lista OPEN con un costo 'f' menor o igual, omitimos
        bool existsInOpenWithBetterF = openList.any(
          (node) => node.id == neighbor.id && node.f <= neighbor.f,
        );

        if (!existsInOpenWithBetterF) {
          openList.add(neighbor);
        }
      }
    }

    return []; // No se encontró solución
  }

  // ==========================================
  // 10. RECONSTRUIR CAMINO & 11. LISTA DE MOVIMIENTOS
  // ==========================================
  List<int> _reconstructPath(PuzzleState targetState) {
    List<int> tileMovesToExecute = [];
    PuzzleState? curr = targetState;

    // Recorremos hacia atrás desde el estado resuelto hasta el estado inicial
    while (curr?.parent != null) {
      if (curr!.clickedTileIndex != null) {
        // CORRECCIÓN 3: Guardar la posición de la ficha tocada, no del espacio vacío
        tileMovesToExecute.add(curr.clickedTileIndex!);
      }
      curr = curr.parent;
    }

    // 11. Devolvemos la lista en el orden correcto (del inicio a la solución)
    return tileMovesToExecute.reversed.toList();
  }

  // ==========================================
  // 12. ANIMAR EN FLUTTER
  // ==========================================
  Future<void> _animateSolution(
    PuzzleController puzzleController,
    List<int> moves,
  ) async {
    for (int targetIndex in moves) {
      // Ejecutar movimiento real simulando el clic sobre la pieza correspondiente
      puzzleController.moveTile(targetIndex);

      // Pausa entre movimientos para lograr una animación fluida
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }
}