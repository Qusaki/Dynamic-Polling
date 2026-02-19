import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import '../models/poll_models.dart';

/// A private class to hold all API endpoint paths as constants.
class _ApiEndpoints {
  static const String register = '/auth/register';
  static const String token = '/auth/token';
  static const String polls = '/polls';
  static const String createPoll = '/polls/create';
  static String pollById(int id) => '/polls/$id';
  static String pollStatus(int id) => '/polls/$id/active';
  static String addQuestion(int pollId) => '/polls/$pollId/question';
  static String questionById(int pollId, int questionId) => '/polls/$pollId/question/$questionId';
}

class ApiService {
  // STRICT LOCALHOST MODE
  static const String _hostIp = '127.0.0.1'; 
  
  static final String _baseUrl = 'https://dynamic-polling.onrender.com';
  
  // Student App URL (for sharing). Needs /#/ for Flutter Web default hashing.
  static final String studentAppBaseUrl = 'https://dynamic-polling-student-web.onrender.com/#';

  static final String websocketBaseUrl = 'wss://dynamic-polling.onrender.com';



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

    print('Making ${method.toUpperCase()} request to: $url');
    print('Headers: $defaultHeaders');
    if (body != null) print('Body: $body');

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: defaultHeaders).timeout(const Duration(seconds: 30));
        break;
      case 'POST':
        response = await http.post(url, headers: defaultHeaders, body: body).timeout(const Duration(seconds: 30));
        break;
      case 'PUT':
        response = await http.put(url, headers: defaultHeaders, body: body).timeout(const Duration(seconds: 30));
        break;
      case 'PATCH':
        response = await http.patch(url, headers: defaultHeaders, body: body).timeout(const Duration(seconds: 30));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: defaultHeaders).timeout(const Duration(seconds: 30));
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Handle token refresh
    final refreshedToken = response.headers['x-refreshed-token'];
    if (refreshedToken != null) {
      await _storage.write(key: 'access_token', value: refreshedToken);
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
      Uri.parse('$_baseUrl${_ApiEndpoints.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return response.statusCode == 201;
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl${_ApiEndpoints.token}');
    print('Making POST request to: $url');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    print('Login Response status: ${response.statusCode}');
    print('Login Response body: ${response.body}');

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

  Future<void> _cachePolls(List<Poll> polls) async {
    final prefs = await SharedPreferences.getInstance();
    final pollsJson = jsonEncode(polls.map((p) => p.toJson()).toList());
    await prefs.setString('cached_polls', pollsJson);
    print('Cached ${polls.length} polls');
  }

  Future<List<Poll>> _getCachedPolls() async {
    final prefs = await SharedPreferences.getInstance();
    final pollsString = prefs.getString('cached_polls');
    if (pollsString != null) {
      final List<dynamic> data = jsonDecode(pollsString);
      print('Loaded ${data.length} polls from cache');
      return data.map((json) => Poll.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Poll>> fetchMyPolls({bool forceRefresh = false}) async {
    // Return cached data immediately if not forcing a refresh
    if (!forceRefresh) {
      // This part is tricky because we want to return cache AND fetch new data.
      // But standard Future<List> can only return once.
      // So here we'll just FETCH from network and Cache it.
      // The Provider will handle the "Cache THEN Network" logic.
      // However, to support that, we should expose both methods.
    }
    
    final response = await _makeAuthenticatedRequest('GET', _ApiEndpoints.polls);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final polls = data.map((json) => Poll.fromJson(json)).toList();
      _cachePolls(polls); // Cache the new data
      return polls;
    } else {
      throw Exception('Failed to fetch polls: ${response.body}');
    }
  }

  // Expose cache getter for the provider
  Future<List<Poll>> getCachedPolls() => _getCachedPolls();

  Future<Poll> getPoll(int pollId) async {
    final response = await _makeAuthenticatedRequest('GET', _ApiEndpoints.pollById(pollId));
    if (response.statusCode == 200) {
      return Poll.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch poll: Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createPoll(String title, String? description, List<Question> questions) async {
    final body = jsonEncode({
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    });

    final response = await _makeAuthenticatedRequest('POST', _ApiEndpoints.createPoll, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create poll. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> updatePollStatus(int pollId, bool isActive) async {
    final response = await _makeAuthenticatedRequest(
      'PATCH',
      _ApiEndpoints.pollStatus(pollId),
      body: jsonEncode({'is_active': isActive}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update poll status. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Poll> updatePollDetails(int pollId, String title, String? description) async {
    final response = await _makeAuthenticatedRequest(
      'PUT',
      _ApiEndpoints.pollById(pollId),
      body: jsonEncode({'title': title, 'description': description}),
    );

    if (response.statusCode == 200) {
      return Poll.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update poll details. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deletePoll(int pollId) async {
    final response = await _makeAuthenticatedRequest('DELETE', _ApiEndpoints.pollById(pollId));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete poll. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Question> updateQuestion(int pollId, int questionId, Question question) async {
    final body = jsonEncode(question.toJson());
    final response = await _makeAuthenticatedRequest(
      'PUT',
      _ApiEndpoints.questionById(pollId, questionId),
      body: body,
    );

    if (response.statusCode == 200) {
      return Question.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deleteQuestion(int pollId, int questionId) async {
    final response = await _makeAuthenticatedRequest('DELETE', _ApiEndpoints.questionById(pollId, questionId));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Question> addQuestionToPoll(int pollId, Question question) async {
    final body = jsonEncode(question.toJson());
    final response = await _makeAuthenticatedRequest(
      'POST',
      _ApiEndpoints.addQuestion(pollId),
      body: body,
    );

    if (response.statusCode == 200) {
      return Question.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add question. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPollResults(int pollId) async {
    final response = await _makeAuthenticatedRequest('GET', '/polls/$pollId/results');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch results. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}