import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/config/api_config.dart';
import 'package:pfe/service/auth_service.dart';
 // <--- VÉRIFIE BIEN LE "S" ICI
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<String?> login(String email, String password) async {
    try {
      _isLoading.value = true;
      
      // On appelle le service. Le service s'occupe déjà de SharedPreferences !
      final dynamic response = await AuthService.login(
        email: email.trim(), 
        password: password
      );
      
      _isLoading.value = false;
      return null; 
    } catch (e) {
      _isLoading.value = false;
      // On nettoie le message d'erreur pour l'utilisateur
      return e.toString().replaceAll("Exception:", "").trim();
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? skills,
    String? bio,
  }) async {
    try {
      _isLoading.value = true;
      await AuthService.register(
        name: name,
        email: email.trim(),
        password: password,
        role: role,
        skills: skills,
        bio: bio,
      );
      _isLoading.value = false;
      return null;
    } catch (e) {
      _isLoading.value = false;
      return e.toString().replaceAll("Exception:", "").trim();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading.value = true;
      await AuthService.logout(); // On utilise la méthode du service
      Get.offAllNamed('/login'); 
      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      print("Erreur logout: $e");
    }
  }
  Future<bool> checkUserValidity() async {
  try {
    // نبعثو requête بسيطة للبروفيل
    // لو الـ Backend رجع 401 أو 404، يعني الـ User ممسوح
    final response = await http.get(
      Uri.parse("${ApiConfig.baseURL}/auth/profile"),
      headers: {"Authorization": "Bearer ${await AuthService.getToken()}"},
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
}