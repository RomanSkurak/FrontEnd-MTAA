import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:mime/mime.dart';

class ApiService {
  final String baseUrl =
      'https://backend-mtaa.onrender.com'; // Android emulator -> localhost, http://192.168.0.98:3000
  //http://10.0.2.2:3000 , https://backend-mtaa.onrender.com

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
      final userRole = data['userRole'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', userRole);

      return true;
    } else {
      return false;
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
    await prefs.remove('role');
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('local_username');
    await prefs.remove('local_password_hash');
    await prefs.remove('local_name');
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

  // GET public sets
  Future<List<dynamic>> getPublicSets() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/public-sets'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // POST public set
  Future<bool> createPublicSet(String name) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/public-sets'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );
    return response.statusCode == 201;
  }

  //GUEST login
  Future<bool> guestLogin() async {
    final response = await http.post(Uri.parse('$baseUrl/guest-login'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final role = data['userRole'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role);
      return true;
    }
    return false;
  }

  //VYTVORENIE KARTY
  Future<bool> addFlashcard({
    required int setId,
    required String name,
    required String front,
    required String back,
    Uint8List? frontImage,
    Uint8List? backImage,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/flashcards');

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['set_id'] = setId.toString()
          ..fields['name'] = name
          ..fields['front_side'] = front
          ..fields['back_side'] = back
          ..fields['data_type'] =
              (frontImage != null || backImage != null) ? 'picture' : 'text';

    if (frontImage != null) {
      final mimeType = lookupMimeType('front.jpg', headerBytes: frontImage);
      final mediaType = mimeType?.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_front',
          frontImage,
          filename: 'front.${mediaType?[1] ?? 'jpg'}',
          contentType: MediaType(
            mediaType?[0] ?? 'image',
            mediaType?[1] ?? 'jpg',
          ),
        ),
      );
    }

    if (backImage != null) {
      final mimeType = lookupMimeType('back.jpg', headerBytes: backImage);
      final mediaType = mimeType?.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_back',
          backImage,
          filename: 'back.${mediaType?[1] ?? 'jpg'}',
          contentType: MediaType(
            mediaType?[0] ?? 'image',
            mediaType?[1] ?? 'jpg',
          ),
        ),
      );
    }

    final streamed = await request.send();
    return streamed.statusCode == 201;
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
      body: jsonEncode({'name': newName, 'is_public_FYN': false}),
    );
  }

  //DELETE SET
  Future<bool> deleteSet(int setId) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/flashcard-sets/$setId'),
      headers: {'Authorization': 'Bearer $token'},
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

    String baseName =
        frontText.trim().isNotEmpty
            ? (frontText.length > 15
                ? '${frontText.substring(0, 15)}...'
                : frontText)
            : '[image]';

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['set_id'] = setId.toString()
          ..fields['name'] = baseName
          ..fields['data_type'] =
              (frontImage != null || backImage != null) ? 'picture' : 'text'
          ..fields['front_side'] = frontText
          ..fields['back_side'] = backText;

    if (frontImage != null) {
      final mimeType = lookupMimeType('front.jpg', headerBytes: frontImage);
      final mediaType = mimeType?.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_front',
          frontImage,
          filename: 'front.${mediaType?[1] ?? 'jpg'}',
          contentType: MediaType(
            mediaType?[0] ?? 'image',
            mediaType?[1] ?? 'jpg',
          ),
        ),
      );
    }

    if (backImage != null) {
      final mimeType = lookupMimeType('back.jpg', headerBytes: backImage);
      final mediaType = mimeType?.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_back',
          backImage,
          filename: 'back.${mediaType?[1] ?? 'jpg'}',
          contentType: MediaType(
            mediaType?[0] ?? 'image',
            mediaType?[1] ?? 'jpg',
          ),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      try {
        final json = jsonDecode(response.body);
        final cardId = json['flashcard']?['flashcard_id'];

        return cardId;
      } catch (e) {
        print('Error parsing response, but card was saved. Returning null');
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

      return {'set': setData, 'cards': cardsData};
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

    final request =
        http.MultipartRequest('PUT', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['name'] = name
          ..fields['front_side'] = frontText
          ..fields['back_side'] = backText
          ..fields['data_type'] =
              (frontImage != null || backImage != null) ? 'picture' : 'text';

    if (frontImage != null) {
      final mimeType = lookupMimeType('front.jpg', headerBytes: frontImage);
      final mediaType = mimeType?.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_front',
          frontImage,
          filename: 'front.${mediaType?[1] ?? 'jpg'}',
          contentType: MediaType(
            mediaType?[0] ?? 'image',
            mediaType?[1] ?? 'jpg',
          ),
        ),
      );
    } else {
      request.fields['remove_image_front'] = 'true';
    }

    if (backImage != null) {
      final mimeType = lookupMimeType('back.jpg', headerBytes: backImage);
      final mediaType = mimeType?.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_back',
          backImage,
          filename: 'back.${mediaType?[1] ?? 'jpg'}',
          contentType: MediaType(
            mediaType?[0] ?? 'image',
            mediaType?[1] ?? 'jpg',
          ),
        ),
      );
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
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // GET CURRENT USER INFO
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);

        // ✅ Ulož "name" pre offline režim (lebo backend vracia "name")
        if (user['name'] != null) {
          await prefs.setString('local_name', user['name']);
        }

        return user;
      } else {
        print(
          '❌ Error loading user data: ${response.statusCode} → ${response.body}',
        );
      }
    } catch (e) {
      print('📴 Offline or request failed: $e');
    }

    // ✅ Offline fallback s rovnakým kľúčom "name"
    final localName = prefs.getString('local_name');
    if (localName != null) {
      return {'name': localName};
    }

    return null;
  }

  //Odoslanie FCM tokenu
  Future<void> sendTokenToBackend(String fcmToken, String jwtToken) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/notification-token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: '{"fcm_token": "$fcmToken"}',
    );

    if (response.statusCode == 200) {
      print('FCM token úspešne uložený!');
    } else {
      print('Chyba pri odosielaní tokenu: ${response.body}');
    }
  }

  /// Odošle jednu learning session a vráti aktualizované štatistiky.
  Future<Map<String, dynamic>> submitLearningSession({
    required DateTime startTime,
    required DateTime endTime,
    required int correct,
    required int total,
  }) async {
    final uri = Uri.parse('$baseUrl/learning-sessions');
    final token = await getToken();
    final body = {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'correct_answers': correct,
      'total_answers': total,
    };
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      // podľa nášho BE vraciame { session: {...}, statistics: {...} }
      return decoded['statistics'] as Map<String, dynamic>;
    } else {
      throw Exception('Chyba pri odosielaní session: ${res.statusCode}');
    }
  }

  /// Načíta aktuálne štatistiky používateľa.
  Future<Map<String, dynamic>> getStatistics() async {
    final uri = Uri.parse('$baseUrl/statistics');
    final token = await getToken();

    try {
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } else {
        throw Exception('Chyba pri načítaní štatistík: ${res.statusCode}');
      }
    } catch (e) {
      print('📴 Offline alebo chyba siete pri načítaní štatistík: $e');
      // 💥 Toto zabráni otvoreniu StatisticsScreen:
      throw Exception('Offline režim – štatistiky nie sú dostupné');
    }
  }
}
