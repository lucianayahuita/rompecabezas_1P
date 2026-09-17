import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import '../utils/refresh_bus.dart';
import 'auth_screen.dart';

class ConfigScreen extends StatefulWidget {
  final User user;
  final RefreshBus refreshBus;

  const ConfigScreen({super.key, required this.user, required this.refreshBus});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  bool _sonido = true;
  bool _notificaciones = false;

  late Future<({int partidas, int? mejorTiempo, String? nivelFavorito})> _future;

  @override
  void initState() {
    super.initState();
    _future = DBHelper.getUserStats(widget.user.id ?? -1);
    widget.refreshBus.addListener(_reload);
  }

  @override
  void dispose() {
    widget.refreshBus.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(() => _future = DBHelper.getUserStats(widget.user.id ?? -1));

  String _formatTime(int? seconds) {
    if (seconds == null) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _displayName {
    final name = widget.user.username;
    if (name.isNotEmpty) return name;
    return widget.user.email.split('@').first;
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              const Text('Mi perfil',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Tu cuenta y preferencias',
                  style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12.5)),
              const SizedBox(height: 18),
              _profileHeader(),
              const SizedBox(height: 18),
              FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  return Row(
                    children: [
                      Expanded(child: _statTile('${stats?.partidas ?? 0}', 'Partidas')),
                      const SizedBox(width: 10),
                      Expanded(child: _statTile(_formatTime(stats?.mejorTiempo), 'Mejor tiempo')),
                      const SizedBox(width: 10),
                      Expanded(child: _statTile(stats?.nivelFavorito ?? '—', 'Nivel favorito')),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text('Preferencias',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _settingsRow(
                icon: Icons.volume_up_outlined,
                title: 'Sonido',
                subtitle: 'Efectos al mover piezas',
                value: _sonido,
                onChanged: (v) => setState(() => _sonido = v),
              ),
              const SizedBox(height: 10),
              _settingsRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notificaciones',
                subtitle: 'Avisos de nuevos rankings',
                value: _notificaciones,
                onChanged: (v) => setState(() => _notificaciones = v),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD9DE),
                    side: BorderSide(color: const Color(0xFFFB7185).withOpacity(0.45)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.accentAmberLight, AppColors.accentAmber]),
          ),
          child: Text(initial,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        Text(_displayName,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        Text(widget.user.email,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12.5)),
      ],
    );
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(value,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.textPrimary,
            activeTrackColor: AppColors.accentAmber,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
