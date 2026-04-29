import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 1. Ton IP fixe (PC) et le port de ton serveur Node.js
  // static const String _lanDevHost = '192.168.100.13';
  //static const String _lanDevHost = '192.168.1.100';
  static const String _lanDevHost = '10.152.12.126';
  static const int apiPort = 5001; 

  static String _host = '127.0.0.1';
  static bool _ready = false;

  /// Initialise l'adresse IP selon l'appareil (Émulateur vs Réel)
  static Future<void> ensureInitialized() async {
    if (_ready) return;

    if (kIsWeb) {
      _host = 'localhost';
    } else {
      final plugin = DeviceInfoPlugin();
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final info = await plugin.androidInfo;
          // Si c'est un vrai téléphone Android, on utilise ton IP LAN
          // Si c'est l'émulateur, on utilise l'adresse spéciale 10.0.2.2
          _host = info.isPhysicalDevice ? _lanDevHost : '10.0.2.2';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final info = await plugin.iosInfo;
          _host = info.isPhysicalDevice ? _lanDevHost : '127.0.0.1';
        }
      } catch (_) {
        _host = _lanDevHost; // En cas d'erreur, on prend ton IP par défaut
      }
    }
    _ready = true;
    if (kDebugMode) {
      print('🚀 Lancy API Host résolu : $_host');
      print('🔗 Base URL : http://$_host:$apiPort/api');
    }
  }

  /// URL pour les requêtes HTTP classiques (Auth, Projets, etc.)
  static String get baseURL => 'http://$_host:$apiPort/api';

  /// URL pour le Messenger (Socket.io) - Sans le suffixe /api
  static String get socketUrl => 'http://$_host:$apiPort';

  /// L'origine (utile pour certains packages de chat ou de fichiers)
  static String get origin => 'http://$_host:$apiPort';
}