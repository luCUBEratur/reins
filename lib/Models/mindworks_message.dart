class MindWorksMessage {
  MindWorksMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String role;
  final String content;
  final DateTime timestamp;
}

class MindWorksDebugEntry {
  MindWorksDebugEntry({
    required this.prompt,
    required this.response,
    required this.rawResponse,
    required this.statusCode,
    required this.duration,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String prompt;
  final String response;
  final String rawResponse;
  final int statusCode;
  final Duration duration;
  final String? errorMessage;
  final DateTime timestamp;

  bool get isError => errorMessage != null || statusCode < 200 || statusCode >= 300;
}
