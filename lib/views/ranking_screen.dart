import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../utils/refresh_bus.dart';

class RankingScreen extends StatefulWidget {
  final User user;
  final RefreshBus refreshBus;

  const RankingScreen({super.key, required this.user, required this.refreshBus});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  static const List<String> _levels = ['2x2', '3x3', '4x4'];
  int _selected = 0;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DBHelper.getTopRankingByLevel(_levels[_selected]);
    widget.refreshBus.addListener(_reload);
  }

  @override
  void dispose() {
    widget.refreshBus.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(() => _future = DBHelper.getTopRankingByLevel(_levels[_selected]));

  void _select(int index) {
    setState(() {
      _selected = index;
      _future = DBHelper.getTopRankingByLevel(_levels[_selected]);
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ranking',
                    style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Los mejores tiempos de PuzleUCB',
                    style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12.5)),
                const SizedBox(height: 16),
                _segmented(),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.accentAmber),
                        );
                      }
                      final rows = snapshot.data!;
                      if (rows.isEmpty) {
                        return Center(
                          child: Text(
                            'Todavía nadie completó este nivel.\n¡Sé el primero en aparecer acá!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13.5),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _rankRow(index, rows[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: List.generate(_levels.length, (i) {
          final selected = _selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _select(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.accentAmberLight, AppColors.accentAmber])
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _levels[i],
                  style: TextStyle(
                    color: selected ? AppColors.textPrimary : Colors.white.withOpacity(0.65),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _rankRow(int index, Map<String, dynamic> row) {
    final bool isMe = row['userId'] == widget.user.id;
    final String name = (row['username'] as String?)?.isNotEmpty == true
        ? row['username'] as String
        : (row['email'] as String? ?? '').split('@').first;

    final medalColors = [
      const [Color(0xFFFFE7A3), Color(0xFFFFC72C)],
      const [Color(0xFFE8E8F0), Color(0xFFC7C9D9)],
      const [Color(0xFFE7B98E), Color(0xFFC9834A)],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.accentAmber.withOpacity(0.09) : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.accentAmber.withOpacity(0.45) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: index < 3
                  ? LinearGradient(colors: medalColors[index])
                  : null,
              color: index >= 3 ? Colors.white.withOpacity(0.08) : null,
            ),
            child: Text(
              '${index + 1}°',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: index < 3 ? AppColors.textPrimary : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Vos',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                      ),
                    ],
                  ],
                ),
                Text(row['date'] as String? ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${row['moves']} mov.',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
              Text(_formatTime(row['timeInSeconds'] as int),
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
