import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  List<String> _errors = [];

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  List<String> _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final List<String> errors = [];

    if (email.isEmpty) {
      errors.add('Le champ email est obligatoire.');
    } else if (!_isValidEmail(email)) {
      errors.add('Adresse email invalide.');
    }

    if (password.isEmpty) {
      errors.add('Le champ mot de passe est obligatoire.');
    } else if (password.length < 8) {
      errors.add('Le mot de passe doit contenir au moins 8 caracteres.');
    }

    return errors;
  }

  Future<void> _login() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _isLoading = true;
      _errors = [];
    });

    try {
      final User user = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
      );
    } catch (e) {
      setState(() {
        _errors = [e.toString().replaceAll('Exception: ', '')];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.movie_filter, color: Colors.black, size: 52),
                ),
                const SizedBox(height: 20),
                const Text(
                  'CINEART',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connexion',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 15,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 56),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                ),
                const SizedBox(height: 16),
                if (_errors.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B0D0D),
                      border: Border.all(color: const Color(0xFF7D2E2E)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _errors
                          .map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '- ',
                                style: TextStyle(
                                  color: Color(0xFFFF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Color(0xFFFF4444),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : ElevatedButton(
                  onPressed: _login,
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text(
                    "Pas de compte ? Créer un compte",
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF888888),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}