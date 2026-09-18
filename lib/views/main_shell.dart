import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../utils/refresh_bus.dart';
import 'config_screen.dart';
import 'instructions_screen.dart';
import 'puzzle_screen.dart';
import 'ranking_screen.dart';

/// Aloja las 4 pantallas principales de la app (Niveles, Ranking, Ayuda,
/// Perfil) detrás de una barra de navegación inferior persistente.
class MainShell extends StatefulWidget {
  final User user;

  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final RefreshBus _refreshBus = RefreshBus();

  late final List<Widget> _screens = [
    PuzzleScreen(user: widget.user, refreshBus: _refreshBus),
    RankingScreen(user: widget.user, refreshBus: _refreshBus),
    const InstructionsScreen(),
    ConfigScreen(user: widget.user, refreshBus: _refreshBus),
  ];

  @override
  void dispose() {
    _refreshBus.dispose();
    super.dispose();
  }

  static const _tabs = [
    (Icons.grid_view_rounded, 'Niveles'),
    (Icons.emoji_events_outlined, 'Ranking'),
    (Icons.help_outline_rounded, 'Ayuda'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildTabBar(),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.darkBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = _index == i;
              final tab = _tabs[i];
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _index = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.accentAmber.withOpacity(0.14) : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            tab.$1,
                            size: 20,
                            color: selected ? AppColors.accentAmber : Colors.white.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: selected ? AppColors.accentAmber : Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
