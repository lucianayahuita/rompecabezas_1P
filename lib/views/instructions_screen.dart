import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  static const _steps = [
    (
      'Elegí una dificultad',
      '2×2 para arrancar, 3×3 para un desafío parejo, 4×4 si ya sos experto.',
      Icons.tune_rounded,
    ),
    (
      'Sacá o elegí una foto',
      'Usá la cámara o tu galería. La recortamos y la partimos en piezas automáticamente.',
      Icons.photo_camera_outlined,
    ),
    (
      'Deslizá las piezas',
      'Tocá la pieza junto al espacio vacío para moverla. Solo se mueven las piezas adyacentes.',
      Icons.swap_horiz_rounded,
    ),
    (
      'Completá la imagen',
      'Cuando cada pieza vuelva a su lugar, ¡ganaste! Tu tiempo entra al ranking.',
      Icons.emoji_events_outlined,
    ),
  ];

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
              const Text('Cómo jugar',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('Cuatro pasos y a armar',
                  style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12.5)),
              const SizedBox(height: 18),
              ..._steps.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _stepCard(entry.key + 1, entry.value),
                  )),
              _tipCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(int number, (String, String, IconData) step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppColors.accentAmberLight, AppColors.accentAmber]),
            ),
            child: Text('$number',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.$1,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                const SizedBox(height: 4),
                Text(step.$2,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.62), fontSize: 12.5, height: 1.4)),
              ],
            ),
          ),
          Icon(step.$3, color: Colors.white.withOpacity(0.35), size: 20),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentAmber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.accentAmberLight, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '¿Trabado? Tocá el botón ✨ durante la partida y el algoritmo A* resuelve el resto por vos.',
              style: TextStyle(
                  color: AppColors.accentAmberLight.withOpacity(0.95), fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
