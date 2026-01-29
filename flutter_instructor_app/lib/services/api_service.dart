import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, describeEnum;
import 'package:universal_io/io.dart';
import '../models/poll_models.dart';

class ApiService {
  static final String _baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000'
      : Platform.isAndroid
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';

  static final String websocketBaseUrl = kIsWeb
      ? 'ws://127.0.0.1:8000'
      : Platform.isAndroid
      ? 'ws://10.0.2.2:8000'
      : 'ws://127.0.0.1:8000';

  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        return true;
      } else {
        print('Login failed with status: ${response.statusCode}, body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error during HTTP call: $e');
      return false;
    }
  }

  Future<void> logout() async {
    // Delete the token from secure storage
    await _storage.delete(key: 'access_token');
  }

  Future<Map<String, dynamic>> createPoll(String title, String? description, List<Question> questions) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Manually construct the body to match the backend's PollCreate schema
    final body = {
      'title': title,
      'description': description,
      'questions': questions.map((q) {
        return {
          'text': q.text,
          'type': describeEnum(q.type).toUpperCase(),
          // The backend expects a list of strings for options on creation
          'options': q.options.map((opt) => opt.text).toList(),
        };
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/polls/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await _storage.delete(key: 'access_token');
      throw Exception('Token expired or invalid. Please login again.');
    } else {
      // Provide more detail in the exception for debugging 422 errors
      throw Exception('Failed to create poll. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> updatePollStatus(int pollId, bool isActive) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.patch(
      Uri.parse('$_baseUrl/polls/$pollId/active'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'is_active': isActive}),
    );

    if (response.statusCode != 200) {
      // Handle 401 specifically for token expiration logic
      if (response.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        throw Exception('Token expired or invalid. Please login again.');
      }
      throw Exception('Failed to update poll status. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Question> updateQuestion(int pollId, int questionId, Question question) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final body = {
      'text': question.text,
      'type': describeEnum(question.type).toUpperCase(),
      'options': question.options.map((opt) => opt.text).toList(),
    };

    final response = await http.put(
      Uri.parse('$_baseUrl/polls/$pollId/question/$questionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Question.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      await _storage.delete(key: 'access_token');
      throw Exception('Token expired or invalid. Please login again.');
    } else {
      throw Exception('Failed to update question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deleteQuestion(int pollId, int questionId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/polls/$pollId/question/$questionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) { // 204 No Content for successful deletion
      if (response.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        throw Exception('Token expired or invalid. Please login again.');
      }
      throw Exception('Failed to delete question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Question> addQuestionToPoll(int pollId, Question question) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final body = {
      'text': question.text,
      'type': describeEnum(question.type).toUpperCase(),
      'options': question.options.map((opt) => opt.text).toList(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/polls/$pollId/question'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Question.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      await _storage.delete(key: 'access_token');
      throw Exception('Token expired or invalid. Please login again.');
    } else {
      throw Exception('Failed to add question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<List<Poll>> fetchMyPolls() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/polls'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Poll.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      await _storage.delete(key: 'access_token');
      throw Exception('Token expired or invalid. Please login again.');
    } else {
      throw Exception('Failed to fetch polls: ${response.body}');
    }
  }
}