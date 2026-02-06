
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poll_models.dart';

class ApiService {
  // Use localhost for web dev; ensure this matches your backend URL
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<PollPublic> getPollByAccessCode(String accessCode) async {
    final response = await http.get(Uri.parse('$baseUrl/polls/access/$accessCode'));

    if (response.statusCode == 200) {
      return PollPublic.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Poll not found');
    } else if (response.statusCode == 400) {
      throw Exception('Poll is not active');
    } else {
      throw Exception('Failed to load poll: ${response.statusCode}');
    }
  }

  Future<void> submitVote(String accessCode, int questionId, String value) async {
    final response = await http.post(
      Uri.parse('$baseUrl/polls/$accessCode/vote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': questionId,
        'response_value': value,
      }),
    );

    if (response.statusCode != 200) {
       throw Exception('Failed to submit vote: ${response.body}');
    }
  }

  Future<void> submitBatchVotes(String accessCode, List<Map<String, dynamic>> votes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/polls/$accessCode/vote/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'votes': votes,
      }),
    );

    if (response.statusCode != 200) {
       throw Exception('Failed to submit batch votes: ${response.body}');
    }
  }
}
