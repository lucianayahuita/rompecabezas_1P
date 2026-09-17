import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

class PuzzleScreen extends StatelessWidget {
  final User user;

  const PuzzleScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Nombre a mostrar (usa username o extrae el nombre del correo)
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
                '¡Hola, $displayName! ',
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

              // Lista de Niveles
              Expanded(
                child: ListView(
                  children: [
                    _buildLevelCard(
                      context,
                      title: 'Fácil (2x2)',
                      description: '4 piezas • Ideal para principiantes',
                      icon: Icons.grid_3x3,
                      color: Colors.greenAccent,
                      levelKey: '2x2',
                    ),
                    _buildLevelCard(
                      context,
                      title: 'Medio (3x3)',
                      description: '9 piezas • Desafío moderado',
                      icon: Icons.grid_3x3,
                      color: Colors.orangeAccent,
                      levelKey: '4x4',
                    ),
                    _buildLevelCard(
                      context,
                      title: 'Difícil (5x5)',
                      description: '25 piezas • Para expertos',
                      icon: Icons.grid_on,
                      color: Colors.redAccent,
                      levelKey: '5x5',
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
    required String levelKey,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Seleccionaste el nivel $title')),
          );
          // TODO: Navegar al tablero de juego del rompecabezas pasando 'levelKey'
        },
      ),
    );
  }
}