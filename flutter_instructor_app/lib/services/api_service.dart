import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // Import everything to include debugPrint
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

  // Centralized request handler
  Future<http.Response> _makeAuthenticatedRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    final defaultHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: defaultHeaders);
        break;
      case 'POST':
        response = await http.post(url, headers: defaultHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(url, headers: defaultHeaders, body: body);
        break;
      case 'PATCH':
        response = await http.patch(url, headers: defaultHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: defaultHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // Handle token refresh
    final refreshedToken = response.headers['x-refreshed-token'];
    if (refreshedToken != null) {
      await _storage.write(key: 'access_token', value: refreshedToken);
      debugPrint('--- Access token refreshed ---');
    }

    // Handle auth errors
    if (response.statusCode == 401) {
      await _storage.delete(key: 'access_token');
      throw Exception('Token expired or invalid. Please login again.');
    }

    return response;
  }

  Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return response.statusCode == 201;
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'access_token', value: data['access_token']);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<List<Poll>> fetchMyPolls() async {
    final response = await _makeAuthenticatedRequest('GET', '/polls');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Poll.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch polls: ${response.body}');
    }
  }

  Future<Poll> getPoll(int pollId) async {
    final response = await _makeAuthenticatedRequest('GET', '/polls/$pollId');
    if (response.statusCode == 200) {
      return Poll.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch poll: Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createPoll(String title, String? description, List<Question> questions) async {
    final body = {
      'title': title,
      'description': description,
      'questions': questions.map((q) => {
        'text': q.text,
        'type': describeEnum(q.type).toUpperCase(),
        'options': q.options.map((opt) => opt.text).toList(),
      }).toList(),
    };

    final response = await _makeAuthenticatedRequest('POST', '/polls/create', body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create poll. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> updatePollStatus(int pollId, bool isActive) async {
    final response = await _makeAuthenticatedRequest(
      'PATCH',
      '/polls/$pollId/active',
      body: jsonEncode({'is_active': isActive}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update poll status. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Poll> updatePollDetails(int pollId, String title, String? description) async {
    final response = await _makeAuthenticatedRequest(
      'PUT',
      '/polls/$pollId',
      body: jsonEncode({'title': title, 'description': description}),
    );

    if (response.statusCode == 200) {
      return Poll.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update poll details. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deletePoll(int pollId) async {
    final response = await _makeAuthenticatedRequest('DELETE', '/polls/$pollId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete poll. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Question> updateQuestion(int pollId, int questionId, Question question) async {
    final body = {
      'text': question.text,
      'type': describeEnum(question.type).toUpperCase(),
      'options': question.options.map((opt) => opt.text).toList(),
    };

    final response = await _makeAuthenticatedRequest(
      'PUT',
      '/polls/$pollId/question/$questionId',
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Question.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deleteQuestion(int pollId, int questionId) async {
    final response = await _makeAuthenticatedRequest('DELETE', '/polls/$pollId/question/$questionId');
    if (response.statusCode != 204) {
      throw Exception('Failed to delete question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Question> addQuestionToPoll(int pollId, Question question) async {
    final body = {
      'text': question.text,
      'type': describeEnum(question.type).toUpperCase(),
      'options': question.options.map((opt) => opt.text).toList(),
    };

    final response = await _makeAuthenticatedRequest(
      'POST',
      '/polls/$pollId/question',
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return Question.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}