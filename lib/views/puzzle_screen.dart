import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/game_result.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../utils/refresh_bus.dart';
import 'game_play_screen.dart';

class _DashboardData {
  final int partidas;
  final int? mejorTiempo;
  final int streak;
  final Map<int, GameResult?> bestByLevel;
  final List<Map<String, dynamic>> weeklyTop;
  final int? weeklyRank;

  _DashboardData({
    required this.partidas,
    required this.mejorTiempo,
    required this.streak,
    required this.bestByLevel,
    required this.weeklyTop,
    required this.weeklyRank,
  });
}

class PuzzleScreen extends StatefulWidget {
  final User user;
  final RefreshBus refreshBus;

  const PuzzleScreen({super.key, required this.user, required this.refreshBus});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late Future<_DashboardData> _future;

  static const List<int> _grids = [2, 3, 4];
  static const Map<int, String> _labels = {2: 'Fácil', 3: 'Medio', 4: 'Difícil'};
  static const Map<int, Color> _levelColors = {
    2: Color(0xFF34D399),
    3: Color(0xFFFBBF24),
    4: Color(0xFFFB7185),
  };
  static const Map<int, IconData> _levelIcons = {
    2: Icons.grid_view_rounded,
    3: Icons.grid_3x3_rounded,
    4: Icons.grid_4x4_rounded,
  };

  int get _userId => widget.user.id ?? -1;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
    widget.refreshBus.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.refreshBus.removeListener(_refresh);
    super.dispose();
  }

  Future<_DashboardData> _loadDashboard() async {
    final stats = await DBHelper.getUserStats(_userId);
    final streak = await DBHelper.getStreakDays(_userId);
    final weeklyTop = await DBHelper.getWeeklyTop(limit: 3);
    final weeklyRank = await DBHelper.getUserWeeklyRank(_userId);

    final Map<int, GameResult?> bestByLevel = {};
    for (final grid in _grids) {
      bestByLevel[grid] = await DBHelper.getBestResultForLevel(_userId, '${grid}x$grid');
    }

    return _DashboardData(
      partidas: stats.partidas,
      mejorTiempo: stats.mejorTiempo,
      streak: streak,
      bestByLevel: bestByLevel,
      weeklyTop: weeklyTop,
      weeklyRank: weeklyRank,
    );
  }

  void _refresh() => setState(() => _future = _loadDashboard());

  String _formatTime(int? seconds) {
    if (seconds == null) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _openGame(int gridSize) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePlayScreen(gridSize: gridSize, user: widget.user),
      ),
    ).then((_) {
      // ping() dispara el listener de esta misma pantalla (_refresh) y
      // también el de Ranking/Perfil, que viven en segundo plano dentro del
      // IndexedStack de MainShell y no se recargan solas.
      widget.refreshBus.ping();
    });
  }

  String get _displayName {
    final name = widget.user.username;
    if (name.isNotEmpty) return name;
    return widget.user.email.split('@').first;
  }

  int get _dailyChallengeGrid {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _grids[dayOfYear % _grids.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.3,
            colors: [AppColors.primaryLight, AppColors.primaryDark, AppColors.darkBackground],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<_DashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentAmber),
                );
              }
              final data = snapshot.data!;
              return RefreshIndicator(
                color: AppColors.accentAmber,
                backgroundColor: AppColors.primaryDark,
                onRefresh: () async => _refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    _buildHeader(data),
                    const SizedBox(height: 16),
                    _buildStatsRow(data),
                    const SizedBox(height: 14),
                    _buildDailyChallenge(),
                    const SizedBox(height: 18),
                    const Text('Niveles',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._grids.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _levelCard(g, data.bestByLevel[g]),
                        )),
                    const SizedBox(height: 8),
                    _buildWeeklyHeader(),
                    const SizedBox(height: 10),
                    ..._buildWeeklyRows(data),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_DashboardData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, $_displayName! 👋',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
              if (data.streak > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentAmber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.accentAmber.withOpacity(0.3)),
                  ),
                  child: Text('🔥 ${data.streak} día${data.streak == 1 ? '' : 's'} seguidos',
                      style: const TextStyle(
                          color: AppColors.accentAmberLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        _avatar(),
      ],
    );
  }

  Widget _avatar() {
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [AppColors.accentAmberLight, AppColors.accentAmber]),
      ),
      child: Text(initial,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildStatsRow(_DashboardData data) {
    return Row(
      children: [
        Expanded(child: _statTile('${data.partidas}', 'Partidas')),
        const SizedBox(width: 10),
        Expanded(child: _statTile(_formatTime(data.mejorTiempo), 'Mejor tiempo')),
        const SizedBox(width: 10),
        Expanded(
            child: _statTile(
                data.weeklyRank != null ? '#${data.weeklyRank}' : '—', 'Esta semana')),
      ],
    );
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildDailyChallenge() {
    final grid = _dailyChallengeGrid;
    final label = _labels[grid]!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openGame(grid),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.primary],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('✦ Reto del día',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Text('Hoy toca $label · $grid×$grid',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Elegido especialmente para hoy. ¡Animate a intentarlo!',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                      colors: [AppColors.accentAmberLight, AppColors.accentAmber]),
                ),
                child: const Text('Jugar ahora',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelCard(int gridSize, GameResult? best) {
    final color = _levelColors[gridSize]!;
    return Material(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openGame(gridSize),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_levelIcons[gridSize], color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_labels[gridSize]} · $gridSize×$gridSize',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${gridSize * gridSize} piezas',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.5)),
                    const SizedBox(height: 4),
                    Text(
                      best != null
                          ? 'Tu mejor: ${_formatTime(best.timeInSeconds)} · ${best.moves} mov.'
                          : 'Todavía no lo intentaste',
                      style: TextStyle(
                        color: best != null
                            ? AppColors.accentAmberLight
                            : Colors.white.withOpacity(0.38),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyHeader() {
    return const Text('Top de la semana',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
  }

  List<Widget> _buildWeeklyRows(_DashboardData data) {
    if (data.weeklyTop.isEmpty) {
      return [
        Text('Todavía nadie completó un rompecabezas esta semana. ¡Sé el primero!',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5)),
      ];
    }

    return List.generate(data.weeklyTop.length, (i) {
      final row = data.weeklyTop[i];
      final isMe = row['userId'] == _userId;
      final name = (row['username'] as String?)?.isNotEmpty == true
          ? row['username'] as String
          : (row['email'] as String? ?? '').split('@').first;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accentAmber.withOpacity(0.09) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe ? AppColors.accentAmber.withOpacity(0.4) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('${i + 1}°',
                  style: const TextStyle(
                      color: AppColors.accentAmberLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5)),
            ),
            Expanded(
              child: Text(isMe ? '$name · Vos' : name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
            ),
            Text(_formatTime(row['timeInSeconds'] as int?),
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.5)),
          ],
        ),
      );
    });
  }
}
