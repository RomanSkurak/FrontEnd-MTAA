import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart'; 

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<List<FlashcardSet>> fetchSets(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sets?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FlashcardSet.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load flashcard sets');
    }
  }

  Future<FlashcardSet> createSet({ 
    required int userId,
    required String name,
    required bool isPublic,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sets'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userId': userId,
        'name': name,
        'isPublic': isPublic,
      }),
    );

    if (response.statusCode == 201) {
      return FlashcardSet.fromJson(json.decode(response.body));
    } else if (response.statusCode == 409) {
      throw Exception('Set with this name already exists');
    } else {
      throw Exception('Failed to create flashcard set');
    }
  }
}