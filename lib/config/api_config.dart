import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;

/// URLs du backend selon l’environnement d’exécution.
///
/// - **Émulateur Android** → `10.0.2.2` (loopback de la machine hôte).
/// - **Téléphone Android réel** → [LAN_DEV_HOST] (IP LAN du PC, même Wi‑Fi).
/// - **Simulateur iOS** → `127.0.0.1`.
/// - **iPhone / iPad réel** → [LAN_DEV_HOST].
///
/// Surcharges :
/// - `API_HOST` : impose l’hôte dans tous les cas (ex. prod ou test manuel).
/// - `LAN_DEV_HOST` : IP du PC pour appareils **physiques** uniquement (défaut `192.168.100.13`).
///
/// Appeler [ensureInitialized] au démarrage (`main`) avant tout appel API.
class ApiConfig {
  /// Doit correspondre au `PORT` du backend (défaut 5001 ; évite le conflit AirPlay/macOS sur 5000).
  static const int apiPort = int.fromEnvironment('API_PORT', defaultValue: 5001);

  static const String _hostOverride = String.fromEnvironment('API_HOST');

  /// IP du PC où tourne Node (Wi‑Fi). À ajuster : `--dart-define=LAN_DEV_HOST=192.168.x.x`
  static const String _lanDevHost = String.fromEnvironment(
    'LAN_DEV_HOST',
    defaultValue: '192.168.100.13',
  );

  static String _host = '127.0.0.1';
  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;

    if (_hostOverride.isNotEmpty) {
      _host = _hostOverride;
      _ready = true;
      _debugLogHost();
      return;
    }

    if (kIsWeb) {
      _host = 'localhost';
      _ready = true;
      _debugLogHost();
      return;
    }

    final plugin = DeviceInfoPlugin();
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          _host = info.isPhysicalDevice ? _lanDevHost : '10.0.2.2';
          break;
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          _host = info.isPhysicalDevice ? _lanDevHost : '127.0.0.1';
          break;
        default:
          _host = '127.0.0.1';
      }
    } catch (_) {
      _host = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : '127.0.0.1';
    }

    _ready = true;
    _debugLogHost();
  }

  static void _debugLogHost() {
    if (kDebugMode) {
      debugPrint('--- API host résolu : $_host (baseURL = http://$_host:$apiPort/api) ---');
    }
  }

  static String get baseURL => 'http://$_host:$apiPort/api';

  /// `http://host:<apiPort>` sans le suffixe `/api`.
  static String get origin {
    final b = baseURL;
    if (b.endsWith('/api')) {
      return b.substring(0, b.length - 4);
    }
    return b;
  }
}
