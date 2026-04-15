import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfe/controllers/auth_controller.dart';
import 'package:pfe/service/auth_service.dart';
 // Vérifie bien le chemin (service ou services ?)
import 'package:pfe/screens/splash/logo.dart';

void main() async {
  // 1. Initialisation vitale des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Injection du contrôleur GetX
  Get.put(AuthController()); 

  // 3. Optionnel mais recommandé : Vérification du token avant le démarrage
  // Cela permet d'éviter les erreurs "null" si une page appelle getToken trop vite
  final String? token = await AuthService.getToken();
  print("--- DÉMARRAGE APP : Token trouvé = $token ---");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lancy PFE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Tu peux garder SplashPage ou décider d'envoyer vers Login selon le token
      home: const SplashPage(), 
    );
  }
}