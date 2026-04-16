import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/Model/User.dart';
import 'package:pfe/config/api_config.dart';

class UserService {
  Future<UserModel> fetchProfile(String email) async {
    final safe = Uri.encodeComponent(email.trim());
    final response = await http.get(
      Uri.parse('${ApiConfig.baseURL}/users/profile/$safe'),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du profil');
    }
  }
}