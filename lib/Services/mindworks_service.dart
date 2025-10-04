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
  Future<MindWorksApiResult> sendPrompt({
    required String agent,
    required String prompt,
    String? persona,
    bool logToMemory = false,
    String? sessionTag,
  }) async {
    final uri = Uri.parse(baseUrl);
    final payload = <String, dynamic>{
      'agent': agent,
      'prompt': prompt,
      'log_to_memory': logToMemory,
    };

    if (persona != null && persona.isNotEmpty) {
      payload['persona'] = persona;
    }

    if (sessionTag != null && sessionTag.isNotEmpty) {
      payload['session_tag'] = sessionTag;
    }

    final stopwatch = Stopwatch()..start();
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    stopwatch.stop();

    final rawBody = response.body;
    Map<String, dynamic> decodedBody;
    try {
      decodedBody = jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      decodedBody = <String, dynamic>{'raw': rawBody};
    }

    final result = MindWorksApiResult(
      body: decodedBody,
      rawBody: rawBody,
      statusCode: response.statusCode,
      duration: stopwatch.elapsed,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw MindWorksApiException(
      message: 'Request failed with status ${response.statusCode}',
      result: result,
    );
  }
}

class MindWorksApiResult {
  MindWorksApiResult({
    required this.body,
    required this.rawBody,
    required this.statusCode,
    required this.duration,
  });

  final Map<String, dynamic> body;
  final String rawBody;
  final int statusCode;
  final Duration duration;
}

class MindWorksApiException implements Exception {
  MindWorksApiException({this.message, required this.result});

  final String? message;
  final MindWorksApiResult result;

  @override
  String toString() => message ?? 'MindWorksApiException(${result.statusCode})';
}
