import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'game_play_screen.dart'; // Importar la pantalla de juego

class PuzzleScreen extends StatelessWidget {
  final User user;

  const PuzzleScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = (user.username != null && user.username!.isNotEmpty)
        ? user.username
        : user.email.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('PuzleUCB'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $displayName! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona la dificultad del rompecabezas:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),

              // Lista de Niveles según la Rúbrica (2x2, 3x3, 4x4)
              Expanded(
                child: ListView(
                  children: [
                    _buildLevelCard(
                      context,
                      title: 'Fácil (2x2)',
                      description: '4 piezas • Ideal para principiantes',
                      icon: Icons.grid_view,
                      color: Colors.greenAccent,
                      gridSize: 2,
                    ),
                    _buildLevelCard(
                      context,
                      title: 'Medio (3x3)',
                      description: '9 piezas • Desafío moderado',
                      icon: Icons.grid_3x3,
                      color: Colors.orangeAccent,
                      gridSize: 3,
                    ),
                    _buildLevelCard(
                      context,
                      title: 'Difícil (4x4)',
                      description: '16 piezas • Para expertos',
                      icon: Icons.grid_4x4,
                      color: Colors.redAccent,
                      gridSize: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int gridSize,
  }) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
        onTap: () {
          // Navega a la pantalla de juego enviando el tamaño de la cuadrícula
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GamePlayScreen(gridSize: gridSize),
            ),
          );
        },
      ),
    );
  }
}