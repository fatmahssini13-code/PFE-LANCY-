import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pfe/config/api_config.dart';
import 'package:pfe/controllers/auth_controller.dart';
import 'package:pfe/screens/home.dart';
import 'package:pfe/service/auth_service.dart';
import 'package:pfe/screens/splash/logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
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
    // 1. Nthabtou el User mazal mawjoud f'el DB walla (Khater faskhtou enti)
    final bool isUserStillValid = await AuthService.checkUserExists();

    if (!isUserStillValid) {
      // Ken el user mouch mawjoud (faskhtou), nfasskhou el token w narj3ou lel Splash
      await AuthService.removeToken();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
      return;
    }

    // 2. Ken el User valid, njibou el data mte3na mrigla
    final email = await AuthService.getUserEmail();
    final role = await AuthService.getUserRole();
    final name = await AuthService.getUserName();

    if (!mounted) return;

    // 3. Navigation lel HomeScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          email: email ?? '',
          role: role ?? 'client',
          name: name,
        ),
      ),
    );
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
            Text("Vérification de la session...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}