import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  List<String> _errors = [];
  bool _success = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  List<String> _validate() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final List<String> errors = [];

    if (firstName.isEmpty) {
      errors.add('Le champ prénom est obligatoire.');
    }

    if (lastName.isEmpty) {
      errors.add('Le champ nom est obligatoire.');
    }

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

  Future<void> _register() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _isLoading = true;
      _errors = [];
      _success = false;
    });

    try {
      await AuthService().register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() => _success = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.movie_filter, color: Colors.black, size: 40),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'CINEART',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Créer un compte',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rejoignez CineArt',
                style: TextStyle(color: Color(0xFF888888), fontSize: 15),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
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
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  helperText: 'Minimum 8 caracteres',
                  helperStyle: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              if (_success)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2B0D),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Compte créé avec succès.',
                    style: TextStyle(
                      color: Color(0xFF66BB6A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : ElevatedButton(
                onPressed: _success ? null : _register,
                child: const Text(
                  "Créer le compte",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}