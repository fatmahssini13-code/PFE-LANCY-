import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfe/config/api_config.dart';
import 'package:pfe/controllers/auth_controller.dart';
import 'package:pfe/screens/home.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/screens/splash/logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiConfig.ensureInitialized();

  Get.put(AuthController());

  final String? token = await AuthService.getToken();
  if (kDebugMode) {
    debugPrint("--- DÉMARRAGE APP : Token trouvé = $token ---");
  }

  runApp(MyApp(hasSession: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool hasSession;

  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lancy PFE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: hasSession ? const _SessionLauncher() : const SplashPage(),
    );
  }
}

/// Charge email + rôle depuis les préférences puis ouvre l’accueil (évite un flash sur l’écran marketing).
class _SessionLauncher extends StatefulWidget {
  const _SessionLauncher();

  @override
  State<_SessionLauncher> createState() => _SessionLauncherState();
}

class _SessionLauncherState extends State<_SessionLauncher> {
  @override
  void initState() {
    super.initState();
    _openHome();
  }

  Future<void> _openHome() async {
    final email = await AuthService.getUserEmail();
    final role = await AuthService.getUserRole();
    final name = await AuthService.getUserName();
    if (!mounted) return;

    if (email == null || email.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          email: email,
          role: role ?? 'client',
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}