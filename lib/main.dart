import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
//import 'package:pfe/screens/auth/login.dart';
import 'package:pfe/screens/splash/logo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
    
   debugShowCheckedModeBanner: false,
      home: SplashPage(),
    );
  }
}

