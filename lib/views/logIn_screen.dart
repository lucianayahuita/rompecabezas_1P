import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'puzzle_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    _showMessage('Por favor completa todos los campos');
    return;
  }

  final User? user = await DBHelper.loginUser(email, password);

  if (user != null && mounted) {
    // Navegar a la pantalla de selección de niveles pasando el objeto de usuario
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PuzzleScreen(user: user),
      ),
    );
  } else if (mounted) {
    _showMessage('Credenciales incorrectas');
  }
}

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Ilustración / Banner Superior
              Center(
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.pets, size: 100, color: AppColors.primary),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Títulos
              const Text(
                'Iniciar Sesion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aqui ira una descripcion',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              
              const SizedBox(height: 30),

              // Campo Correo
              const Text(
                'Correo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'acbd@gmail.com',
                ),
              ),

              const SizedBox(height: 16),

              // Campo Contraseña
              const Text(
                'Contrasena',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '***************',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón Log In
              ElevatedButton(
                onPressed: _login,
                child: const Text('Log In'),
              ),

              const SizedBox(height: 30),

              // Divisor inferior con mensaje
              const Divider(color: AppColors.primary, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'Juega y diviertete',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}