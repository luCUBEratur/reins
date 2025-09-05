import 'dart:convert';

import 'package:http/http.dart' as http;

/// Basic REST client for communicating with MindWorks agents.
///
/// The [baseUrl] should point to the MindWorks API gateway or agent
/// host. Individual agents are addressed via the `agent` field in the
/// request body, allowing different backends to be selected at runtime.
class MindWorksService {
  MindWorksService({http.Client? client, this.baseUrl = 'http://192.168.1.150:8000/api'})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Base URL for all requests. Can be changed via user settings.
  String baseUrl;

  /// Sends a prompt to the MindWorks backend and returns the decoded JSON.
  Future<Map<String, dynamic>> sendPrompt({
    required String agent,
    required String prompt,
    String? persona,
    bool logToMemory = false,
  }) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'agent': agent,
        'persona': persona,
        'prompt': prompt,
        'log_to_memory': logToMemory,
      }),
    );

    if (response.statusCode != 200) {
      throw http.ClientException('Request failed: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
