import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/Model/User.dart';

class UserService {
  final String baseUrl = "http://192.168.100.13:5000/api/users";

  Future<UserModel> fetchProfile(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/profile/$email'));

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du profil');
    }
  }
}