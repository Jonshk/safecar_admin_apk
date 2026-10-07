import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import 'main_nav_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ApiService.session,
      builder: (_, token, __) => token == null
          ? const _LoginScreen()
          : const MainNavScreen(),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen();
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await ApiService.login(_username.text.trim(), _password.text);
      if (mounted) _password.clear();
      // Register push only after the backend has authenticated this admin.
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await ApiService.registerFcmToken(token);
      } catch (_) {
        // A notification failure must not prevent access to the console.
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'No se pudo iniciar sesión. Comprueba tus datos y la conexión.'; });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Car Admin')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _username, enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                  autocorrect: false, textInputAction: TextInputAction.next),
                const SizedBox(height: 16),
                TextField(controller: _password, enabled: !_busy,
                  obscureText: true, enableSuggestions: false, autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  onSubmitted: (_) => _login()),
                const SizedBox(height: 24),
                if (_error != null) Text(_error!),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _busy ? null : _login,
                  child: Text(_busy ? 'Iniciando sesión…' : 'Iniciar sesión')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
