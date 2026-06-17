import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/room.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _usernameKey = 'username';
  static const _fullNameKey = 'full_name';

  static bool _refreshing = false;

  static Future<void> _saveTokens({
    required String access,
    required String refresh,
    required String username,
    required String fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_fullNameKey, fullName);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullNameKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_fullNameKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _refreshAccessToken() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, data['access'] as String);
      if (data.containsKey('refresh')) {
        await prefs.setString(_refreshKey, data['refresh'] as String);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  static Future<http.Response> _authGet(Uri url) async {
    var headers = await _authHeaders();
    var response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        headers = await _authHeaders();
        response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      }
    }
    return response;
  }

  static Future<http.Response> _authPost(Uri url, {Object? body}) async {
    var headers = await _authHeaders();
    var response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        headers = await _authHeaders();
        response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
      }
    }
    return response;
  }

  static Future<http.Response> _authDelete(Uri url) async {
    var headers = await _authHeaders();
    var response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        headers = await _authHeaders();
        response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
      }
    }
    return response;
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  static Future<void> login(String username, String password) async {
    final response = await http
        .post(
          Uri.parse('${Config.baseUrl}/api/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw ApiException(
        data['error'] as String? ?? 'Ошибка входа',
        statusCode: response.statusCode,
      );
    }

    await _saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
      username: data['username'] as String,
      fullName: data['full_name'] as String,
    );
  }

  // ── Rooms ─────────────────────────────────────────────────────────────

  static Future<List<Room>> getRooms() async {
    final response = await _authGet(Uri.parse('${Config.baseUrl}/api/rooms/'));

    if (response.statusCode == 401) {
      throw ApiException('Необходима авторизация', statusCode: 401);
    }
    if (response.statusCode != 200) {
      throw ApiException('Ошибка загрузки комнат', statusCode: response.statusCode);
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Room> createRoom(String name) async {
    final response = await _authPost(
      Uri.parse('${Config.baseUrl}/api/rooms/'),
      body: jsonEncode({'name': name}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw ApiException(
        data['error'] as String? ?? 'Ошибка создания комнаты',
        statusCode: response.statusCode,
      );
    }

    return Room.fromJson(data);
  }

  static Future<RoomToken> getRoomToken(String roomId) async {
    final response = await _authGet(
      Uri.parse('${Config.baseUrl}/api/rooms/$roomId/token/'),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw ApiException(
        data['error'] as String? ?? 'Ошибка получения токена',
        statusCode: response.statusCode,
      );
    }

    return RoomToken.fromJson(data);
  }

  static Future<void> deleteRoom(String roomId) async {
    final response = await _authDelete(
      Uri.parse('${Config.baseUrl}/api/rooms/$roomId/'),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        data['error'] as String? ?? 'Ошибка удаления комнаты',
        statusCode: response.statusCode,
      );
    }
  }
}
