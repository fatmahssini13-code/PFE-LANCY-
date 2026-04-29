import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/Model/User.dart';
import 'package:pfe/config/api_config.dart';
import 'package:http_parser/http_parser.dart';

class UserService {

  Future<UserModel> fetchProfile(String email) async {
    final safe = Uri.encodeComponent(email.trim());
    final response = await http.get(
      // ✅ baseURL = http://IP:5001/api → donc /users/profile/$safe
      Uri.parse('${ApiConfig.baseURL}/users/profile/$safe'),
    );

    print("📡 fetchProfile status: ${response.statusCode}");
    print("📡 fetchProfile body: ${response.body}");

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors du chargement du profil');
    }
  }

  Future<bool> updateProfile({
    required String email,
    required String name,
    required String bio,
  }) async {
    try {
      final safe = Uri.encodeComponent(email.trim());
      final response = await http.put(
        // ✅ baseURL = http://IP:5001/api → donc /users/update/$safe
        Uri.parse("${ApiConfig.baseURL}/users/update/$safe"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "bio": bio}),
      );

      print("📡 updateProfile status: ${response.statusCode}");
      print("📡 updateProfile body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Update error: $e");
      return false;
    }
  }
  

Future<String?> uploadAvatar({
  required String email,
  required String filePath,
}) async {
  try {
    final safe = Uri.encodeComponent(email.trim());
    final uri = Uri.parse("${ApiConfig.baseURL}/users/upload-avatar/$safe");

    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath(
      "avatar",
      filePath,
      contentType: MediaType("image", "jpeg"),
    ));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    print("📡 Upload status: ${response.statusCode}");
    print("📡 Avatar URL: ${data['avatarUrl']}");

    if (response.statusCode == 200) {
      return data['avatarUrl'];
    }
    return null;
  } catch (e) {
    print("❌ Upload error: $e");
    return null;
  }
}
}