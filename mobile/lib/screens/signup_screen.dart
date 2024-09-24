import 'package:flutter/material.dart';
import 'package:mobile/screens/login_screen.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        await authService.signup(firstName, lastName, email, password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur d'inscription : ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 128,
                    height: 128,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (value) =>
                        value!.isEmpty ? 'Entrez un nom prénom' : null,
                    onChanged: (value) => firstName = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) =>
                        value!.isEmpty ? 'Entrez un nom Nom' : null,
                    onChanged: (value) => lastName = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) =>
                        value!.isEmpty ? 'Entrez un email' : null,
                    onChanged: (value) => email = value,
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                    validator: (value) =>
                        value!.isEmpty ? 'Entrez un mot de passe' : null,
                    onChanged: (value) => password = value,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: _signup, child: const Text('S\'inscrire')),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text("Déjà inscrit ? Se connecter"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
