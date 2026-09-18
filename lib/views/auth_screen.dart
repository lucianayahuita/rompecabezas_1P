import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';

/// Pantalla única de acceso: alterna entre Iniciar sesión y Crear cuenta
/// mediante un interruptor, en vez de usar dos pantallas separadas.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setMode(bool register) {
    if (_isRegister == register) return;
    setState(() => _isRegister = register);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isRegister) {
      final username = _usernameController.text.trim();
      final confirm = _confirmController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
        _showMessage('Todos los campos son obligatorios');
        return;
      }
      if (password != confirm) {
        _showMessage('Las contraseñas no coinciden');
        return;
      }

      setState(() => _loading = true);
      final result = await DBHelper.registerUser(
        User(email: email, password: password, username: username),
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (result != -1) {
        _showMessage('¡Cuenta creada! Ya podés iniciar sesión.');
        _confirmController.clear();
        setState(() => _isRegister = false);
      } else {
        _showMessage('El correo ya se encuentra registrado');
      }
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Por favor completa todos los campos');
      return;
    }

    setState(() => _loading = true);
    final User? user = await DBHelper.loginUser(email, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainShell(user: user)),
      );
    } else {
      _showMessage('Credenciales incorrectas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.55),
                radius: 1.3,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryDark,
                  AppColors.darkBackground,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              return Stack(
                children: [
                  _floatingPiece(size, top: 0.06, left: 0.08, baseAngle: -0.15),
                  _floatingPiece(size, top: 0.05, left: 0.82, baseAngle: 0.2),
                  _sparkle(size, top: 0.14, left: 0.28),
                  _sparkle(size, top: 0.12, left: 0.68),
                ],
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical - 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 22),
                    _buildSwitcher(),
                    const SizedBox(height: 18),
                    _buildPanel(),
                    const SizedBox(height: 20),
                    Text(
                      'PuzleUCB · Rompecabezas UCB',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  final glow = 0.6 + (_ambientController.value * 0.4);
                  return Container(
                    width: 110 * glow,
                    height: 110 * glow,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentAmber.withOpacity(0.45 * glow),
                          AppColors.accentAmber.withOpacity(0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Image.asset(
                'assets/logo_rompecabezas_ucb.png',
                width: 108,
                height: 108,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ARMA · COMPITE · GANA',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 2;
        return Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                alignment: _isRegister ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: segmentWidth - 4,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [AppColors.accentAmberLight, AppColors.accentAmber],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentAmber.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _switchLabel('Iniciar sesión', selected: !_isRegister, onTap: () => _setMode(false)),
                  _switchLabel('Crear cuenta', selected: _isRegister, onTap: () => _setMode(true)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _switchLabel(String text, {required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: selected ? AppColors.textPrimary : Colors.white.withOpacity(0.65),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _isRegister ? 'Crea tu cuenta' : 'Bienvenido de nuevo',
                  key: ValueKey(_isRegister),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _isRegister
                      ? 'Sumate a PuzleUCB y empezá a armar, competir y ganar.'
                      : 'Ingresa tus datos para seguir armando rompecabezas.',
                  key: ValueKey('sub-$_isRegister'),
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.65)),
                ),
              ),
              const SizedBox(height: 20),

              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isRegister
                    ? Column(
                        children: [
                          _buildField(
                            label: 'Nombre de usuario',
                            controller: _usernameController,
                            hint: 'Ej. juanp_ucb',
                          ),
                          const SizedBox(height: 14),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              _buildField(
                label: 'Correo electrónico',
                controller: _emailController,
                hint: 'tu.correo@ucb.edu.bo',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              _buildPasswordField(
                label: 'Contraseña',
                controller: _passwordController,
                hint: 'Mínimo 6 caracteres',
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isRegister
                    ? Column(
                        children: [
                          const SizedBox(height: 14),
                          _buildPasswordField(
                            label: 'Confirmar contraseña',
                            controller: _confirmController,
                            hint: 'Repite tu contraseña',
                            obscure: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentAmber,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.textPrimary),
                        )
                      : Text(
                          _isRegister ? 'Crear cuenta' : 'Ingresar',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration(hint).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.65),
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentAmber, width: 1.5),
      ),
    );
  }

  Widget _floatingPiece(Size size, {required double top, required double left, required double baseAngle}) {
    final wobble = math.sin(_ambientController.value * math.pi * 2) * 0.08;
    return Positioned(
      top: size.height * top,
      left: size.width * left,
      child: Transform.rotate(
        angle: baseAngle + wobble,
        child: Icon(Icons.extension_rounded, size: 30, color: Colors.white.withOpacity(0.08)),
      ),
    );
  }

  Widget _sparkle(Size size, {required double top, required double left}) {
    final opacity = (0.2 + (_ambientController.value * 0.4)).clamp(0.0, 0.6);
    return Positioned(
      top: size.height * top,
      left: size.width * left,
      child: Opacity(
        opacity: opacity,
        child: const Icon(Icons.auto_awesome, size: 12, color: AppColors.accentAmber),
      ),
    );
  }
}
