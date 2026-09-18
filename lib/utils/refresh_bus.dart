import 'package:flutter/foundation.dart';

/// Pequeño bus de eventos para avisarle a las pestañas del [MainShell]
/// (Niveles, Ranking, Perfil) que deben recargar sus datos, por ejemplo
/// después de terminar una partida. Las pestañas viven todas al mismo
/// tiempo dentro de un `IndexedStack`, así que no se reconstruyen solas al
/// cambiar de pestaña: necesitan este aviso explícito.
class RefreshBus extends ChangeNotifier {
  void ping() => notifyListeners();
}
