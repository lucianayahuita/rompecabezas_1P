class GameResult {
  final int? id;
  final int userId;        // ID del usuario que jugó la partida
  final String level;     // "2x2", "3x3", "4x4"
  final int moves;        // Cantidad de movimientos realizados
  final int timeInSeconds;// Tiempo total en segundos
  final String date;      // Fecha de la partida (ej: "2026-09-11 12:30")

  GameResult({
    this.id,
    required this.userId,
    required this.level,
    required this.moves,
    required this.timeInSeconds,
    required this.date,
  });

  // Convierte el objeto a un Map para insertarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'level': level,
      'moves': moves,
      'timeInSeconds': timeInSeconds,
      'date': date,
    };
  }

  // Crea un objeto GameResult a partir de un Map devuelto por SQLite
  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'],
      userId: map['userId'],
      level: map['level'],
      moves: map['moves'],
      timeInSeconds: map['timeInSeconds'],
      date: map['date'],
    );
  }
}