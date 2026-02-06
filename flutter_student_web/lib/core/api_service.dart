
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poll_models.dart';

import 'dart:math';

class ApiService {
  // STRICT LOCALHOST MODE
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Simple in-memory ID for the session.
  String? _voterId;

  String get voterId {
    if (_voterId == null) {
      final random = Random();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rand = random.nextInt(1000000);
      _voterId = 'student_${timestamp}_$rand';
    }
    return _voterId!;
  }

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
        'voter_id': voterId,
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
        'voter_id': voterId,
      }),
    );

    if (response.statusCode != 200) {
       throw Exception('Failed to submit batch votes: ${response.body}');
    }
  }
}
