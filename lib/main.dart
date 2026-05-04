import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pfe/config/api_config.dart';
import 'package:pfe/controllers/auth_controller.dart';
import 'package:pfe/screens/home.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/screens/splash/logo.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await ApiConfig.ensureInitialized();
  Stripe.publishableKey ="pk_test_51TRggT239ygk1HexDY1jGLqUy5pp6acHEUbG9B1dcABYBNNDspbCsIGx2rO0Eo8p8Je9Ij2f0eFpGvmGMmGZTcg200UBdrRPS3";
Stripe.publishableKey = ApiConfig.stripePublishableKey;
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
      // Ken famma session, n'addiweh lel Launcher bch nthabtou el validity
      home: hasSession ? const _SessionLauncher() : const SplashPage(),
    );
  }
}


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
    try {
      // 1. On ajoute un timeout de 5 secondes max
      // Si le serveur ne répond pas après 5s, on considère que le check a échoué
      final bool isUserStillValid = await AuthService.checkUserExists().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!isUserStillValid) {
        await AuthService.removeToken();
        if (!mounted) return;
        Get.offAll(
          () => const SplashPage(),
        ); // On utilise Get pour nettoyer la pile
        return;
      }

      // 2. Récupération des infos locales (stockées dans SharedPreferences/SecureStorage)
      final email = await AuthService.getUserEmail();
      final role = await AuthService.getUserRole();
      final name = await AuthService.getUserName();
  
      if (!mounted) return;

      // 3. Navigation vers HomeScreen
      Get.offAll(
        () =>
            HomeScreen(email: email ?? '', role: role ?? 'client', name: name),
      );
    } catch (e) {
      debugPrint("Erreur réseau ou session : $e");
      // En cas d'erreur (serveur éteint), on redirige vers le Splash/Login
      if (!mounted) return;
      Get.offAll(() => const SplashPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pinkAccent),
            SizedBox(height: 20),
            Text(
              "Vérification de la session...",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
