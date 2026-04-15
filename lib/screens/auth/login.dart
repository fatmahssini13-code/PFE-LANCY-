import 'package:flutter/material.dart';
import 'package:pfe/screens/home.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/screens/auth/forgot_password_screen.dart';
import 'package:pfe/screens/auth/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  String msg = "";
  bool loading = false;
  bool hidePassword = true;

  final Color lancyBlue = const Color(0xFF35B6F3);
  final Color lancyPurple = const Color(0xFF8339F4);
  final Color lancyDark = const Color(0xFF121E42);

  // --- LOGIQUE DE CONNEXION ---
  Future<void> doLogin() async {
    if (emailC.text.trim().isEmpty || passC.text.isEmpty) {
      setState(() => msg = "Veuillez remplir tous les champs");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      msg = "";
    });

    try {
      await AuthService.login(email: emailC.text.trim(), password: passC.text);

      if (context.mounted) {
        // NAVIGATION CORRIGÉE : On ne passe plus le token ici
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(email: emailC.text.trim(), role: 'client'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        msg = e.toString().contains("401")
            ? "Email ou mot de passe incorrect"
            : "Erreur de connexion au serveur";
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --- UI COMPONENTS ---
  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: lancyBlue),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                "Lancy Admin",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: lancyDark,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailC,
                decoration: _inputDecoration("Email", Icons.email),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passC,
                obscureText: hidePassword,
                decoration: _inputDecoration(
                  "Mot de passe",
                  Icons.lock,
                  suffix: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                  ),
                ),
              ),
              if (msg.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(msg, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 30),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [lancyBlue, lancyPurple]),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : doLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Se Connecter",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
