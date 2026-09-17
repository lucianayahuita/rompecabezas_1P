import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controla la entrada del logo, el texto y la barra de progreso.
  late final AnimationController _entryController;
  // Pulso continuo del resplandor y las chispas de fondo.
  late final AnimationController _glowController;

  late final Animation<double> _fillScale;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // El fondo se "llena" desde el centro, como una transición de relleno.
    _fillScale = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInOutCubic),
    );

    // El logo recién aparece cuando el relleno ya casi cubrió la pantalla.
    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.32, 0.5, curve: Curves.easeIn),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.12)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.32, 0.75, curve: Curves.linear),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.32, 0.68, curve: Curves.easeOutBack),
      ),
    );

    _textFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.55, 0.8, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _progress = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
    );

    _entryController.forward();

    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, animation, __) => const AuthScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Diámetro suficiente para que el círculo cubra toda la pantalla al crecer.
    final fillDiameter =
        math.sqrt(size.width * size.width + size.height * size.height) * 1.05;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0620),
      body: Stack(
        children: [
          // Telón de fondo oscuro fijo, sobre el que se "derrama" el color.
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF0D0620),
          ),

          // Relleno circular que se expande desde el centro, como una transición de llenado.
          // OverflowBox permite que el círculo crezca más allá de las restricciones
          // del Stack para que, ya escalado, llegue realmente hasta las esquinas.
          Center(
            child: OverflowBox(
              maxWidth: fillDiameter,
              maxHeight: fillDiameter,
              child: AnimatedBuilder(
                animation: _fillScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fillScale.value,
                    child: child,
                  );
                },
                child: Container(
                width: fillDiameter,
                height: fillDiameter,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.2,
                    colors: [
                      Color(0xFF3B0EA0),
                      Color(0xFF200A57),
                      Color(0xFF0D0620),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              ),
            ),
          ),

          // Piezas de rompecabezas flotando de fondo, muy sutiles.

          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Stack(
                children: [
                  _floatingPiece(size, top: 0.10, left: 0.12, icon: Icons.extension_rounded,
                      color: Colors.amber, baseAngle: -0.2),
                  _floatingPiece(size, top: 0.78, left: 0.80, icon: Icons.extension_rounded,
                      color: Colors.deepPurpleAccent, baseAngle: 0.5),
                  _floatingPiece(size, top: 0.68, left: 0.08, icon: Icons.extension_rounded,
                      color: Colors.blueAccent, baseAngle: 0.15),
                  _floatingPiece(size, top: 0.14, left: 0.78, icon: Icons.extension_rounded,
                      color: Colors.amberAccent, baseAngle: -0.4),
                ],
              );
            },
          ),

          // Chispas / destellos titilando.
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              final t = _glowController.value;
              return Stack(
                children: [
                  _sparkle(size, top: 0.22, left: 0.24, t: t, phase: 0.0),
                  _sparkle(size, top: 0.30, left: 0.72, t: t, phase: 0.3),
                  _sparkle(size, top: 0.62, left: 0.20, t: t, phase: 0.6),
                  _sparkle(size, top: 0.60, left: 0.76, t: t, phase: 0.9),
                ],
              );
            },
          ),

          // Contenido central.
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Resplandor pulsante detrás del logo + logo con entrada elástica.
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          final glow = 0.55 + (_glowController.value * 0.45);
                          return Container(
                            width: 260 * glow,
                            height: 260 * glow,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.35 * glow),
                                  Colors.deepPurple.withOpacity(0.0),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      FadeTransition(
                        opacity: _logoFade,
                        child: AnimatedBuilder(
                          animation: _entryController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _logoRotation.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 240,
                            height: 240,
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              'assets/logo_rompecabezas_ucb.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Text(
                      'Arma. Compite. Gana.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barra de progreso inferior.
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 160,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFC72C), Color(0xFF7E22CE)],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'Cargando...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingPiece(
    Size size, {
    required double top,
    required double left,
    required IconData icon,
    required Color color,
    required double baseAngle,
  }) {
    final wobble = math.sin(_glowController.value * math.pi * 2) * 0.08;
    return Positioned(
      top: size.height * top,
      left: size.width * left,
      child: FadeTransition(
        opacity: _logoFade,
        child: Transform.rotate(
          angle: baseAngle + wobble,
          child: Icon(icon, size: 34, color: color.withOpacity(0.18)),
        ),
      ),
    );
  }

  Widget _sparkle(Size size, {required double top, required double left, required double t, required double phase}) {
    final local = ((t + phase) % 1.0);
    final opacity = (math.sin(local * math.pi)).clamp(0.0, 1.0);
    return Positioned(
      top: size.height * top,
      left: size.width * left,
      child: Opacity(
        opacity: opacity * 0.9,
        child: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFFC72C)),
      ),
    );
  }
}
