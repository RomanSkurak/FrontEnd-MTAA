import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  final String baseUrl =
      'http://10.0.2.2:3000'; // Android emulator -> localhost, http://192.168.0.98:3000
  //http://10.0.2.2:3000

  //REGISTER
  Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    return response.statusCode == 201;
  }

  //LOGIN
  Future<bool> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      return true;
    } else {
      return false;
    }
  }

  //STATISTICS
  Future<Map<String, dynamic>?> getStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/statistics'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  //ZISKANIE TOKENU
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  //GETFLASHCARDS
  Future<http.Response> getFlashcards() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/flashcards'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  //VERIFYTOKEN
  Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-token'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying token: $e');
      return false;
    }
  }

  //ODHLASENIE
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  //ZISKANIE SETOV
  Future<List<FlashcardSet>> fetchSets() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/flashcard-sets'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FlashcardSet.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load flashcard sets');
    }
  }

  //VYTVORENIE SETU
  Future<bool> createSet({required String name, required bool isPublic}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/flashcard-sets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'is_public_FYN': isPublic}),
    );

    if (response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 409) {
      throw Exception('Flashcard set with this name already exists.');
    } else {
      throw Exception('Failed to create flashcard set.');
    }
  }
}
