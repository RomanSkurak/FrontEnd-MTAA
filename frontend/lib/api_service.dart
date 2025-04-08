import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';

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
    return data
        .map((json) => FlashcardSet.fromJson(json))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); 
  } else {
    throw Exception('Failed to load flashcard sets');
  }
}

  //VYTVORENIE SETU
  Future<int?> createSet({required String name, required bool isPublic}) async {
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
      final data = jsonDecode(response.body);
      return data['set']['set_id']; 
    } else {
      return null;
    }
  }

  //VYTVORENIE KARTY
  Future<bool> addFlashcard({
    required int setId,
    required String name,
    required String front,
    required String back,
    required String dataType,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/flashcards'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'set_id': setId,
        'name': name,
        'front_side': front,
        'back_side': back,
        'data_type': dataType, 
      }),
    );

    return response.statusCode == 201;
  }

  //UPDATE NAZVU SETU
  Future<void> updateSetName(int setId, String newName) async {
    final token = await getToken();

    await http.put(
      Uri.parse('$baseUrl/flashcard-sets/$setId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': newName,
        'is_public_FYN': false, 
        
      }),
    );
  }

  //DELETE SET
  Future<bool> deleteSet(int setId) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/flashcard-sets/$setId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // ULOZENIE KARTY S NAZVOM
  Future<int?> saveCardToSet({
    required int setId,
    required String frontText,
    required String backText,
    Uint8List? frontImage,
    Uint8List? backImage,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/flashcards');

    String baseName = frontText.trim().isNotEmpty
        ? (frontText.length > 15 ? '${frontText.substring(0, 15)}...' : frontText)
        : '[image]';

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['set_id'] = setId.toString()
      ..fields['name'] = baseName
      ..fields['data_type'] =
          (frontImage != null || backImage != null) ? 'picture' : 'text'
      ..fields['front_side'] = frontText
      ..fields['back_side'] = backText;

    if (frontImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image_front',
        frontImage,
        filename: 'front.png',
        contentType: MediaType('image', 'png'),
      ));
    }

    if (backImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image_back',
        backImage,
        filename: 'back.png',
        contentType: MediaType('image', 'png'),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      try {
        final json = jsonDecode(response.body);
        final cardId = json['flashcard']?['flashcard_id'];

        return cardId;
      } catch (e) {
        print('Error parsing the response, but the card was saved. Returning null');
        return null;
      }
    } else {
      print('Error saving card: ${response.body}');
      return null;
    }
  }


  // LOAD konkretneho setu aj s flashcards
  Future<Map<String, dynamic>> loadSetWithFlashcards(int setId) async {
    final token = await getToken();

    final setResponse = await http.get(
      Uri.parse('$baseUrl/flashcard-sets/$setId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final cardsResponse = await http.get(
      Uri.parse('$baseUrl/flashcards/$setId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (setResponse.statusCode == 200 && cardsResponse.statusCode == 200) {
      final setData = jsonDecode(setResponse.body);
      final cardsData = jsonDecode(cardsResponse.body);

      return {
        'set': setData,
        'cards': cardsData,
      };
    } else {
      throw Exception('Failed to load set or flashcards');
    }
  }

   //Flashcard by ID
  Future<Map<String, dynamic>> getFlashcardById(int flashcardId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/flashcard/$flashcardId'), 
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load flashcard');
    }
  }

  //Update flashcard
  Future<bool> updateFlashcard({
    required int flashcardId,
    required String frontText,
    required String backText,
    required String name,
    Uint8List? frontImage,
    Uint8List? backImage,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/flashcards/$flashcardId');

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['front_side'] = frontText
      ..fields['back_side'] = backText
      ..fields['data_type'] =
          (frontImage != null || backImage != null) ? 'picture' : 'text';

    if (frontImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image_front',
        frontImage,
        filename: 'front.png',
        contentType: MediaType('image', 'png'),
      ));
    } else {
      request.fields['remove_image_front'] = 'true'; 
    }

    if (backImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image_back',
        backImage,
        filename: 'back.png',
        contentType: MediaType('image', 'png'),
      ));
    } else {
      request.fields['remove_image_back'] = 'true'; 
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      print('Error updating flashcard: ${response.body}');
    }

    return response.statusCode == 200;
  }

  // DELETE FLASHCARD
  Future<bool> deleteFlashcard(int flashcardId) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/flashcards/$flashcardId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // GET CURRENT USER INFO
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error loading user data: ${response.body}');
      return null;
    }
  }
}

