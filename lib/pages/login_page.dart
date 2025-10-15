import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    await auth.signIn(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;
    if (auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@')
                    ? 'Email invalide'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6
                    ? null
                    : 'Au moins 6 caractères',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isBusy ? null : _submit,
                  child: auth.isBusy
                      ? const CircularProgressIndicator.adaptive()
                      : const Text('Se connecter'),
                ),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/signup'),
                  child: const Text("Créer un compte"))
            ],
          ),
        ),
      ),
    );
  }
}
