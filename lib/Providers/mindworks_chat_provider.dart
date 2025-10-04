import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:reins/Models/mindworks_message.dart';
import 'package:reins/Providers/agent_provider.dart';
import 'package:reins/Services/mindworks_service.dart';

class MindWorksChatProvider extends ChangeNotifier {
  MindWorksChatProvider({
    required MindWorksService service,
    required AgentProvider agentProvider,
  })  : _service = service,
        _agentProvider = agentProvider {
    _sessionTag = Hive.box('settings').get('sessionTag', defaultValue: '') as String;
  }

  final MindWorksService _service;
  final AgentProvider _agentProvider;

  final List<MindWorksMessage> _messages = <MindWorksMessage>[];
  List<MindWorksMessage> get messages => List.unmodifiable(_messages);

  final List<MindWorksDebugEntry> _debugEntries = <MindWorksDebugEntry>[];
  List<MindWorksDebugEntry> get debugEntries => List.unmodifiable(_debugEntries);

  MindWorksDebugEntry? _lastStatus;
  MindWorksDebugEntry? get lastStatus => _lastStatus;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _sessionTag = '';
  String get sessionTag => _sessionTag;

  Timer? _statusResetTimer;
  Timer? _sessionTagDebounce;

  final List<String> personas = const <String>['Reflective', 'Teacher', 'Analyst'];

  Future<void> sendPrompt(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty || _isSending) {
      return;
    }

    _setError(null);
    _isSending = true;
    notifyListeners();

    final userMessage = MindWorksMessage(role: 'user', content: trimmedPrompt);
    _messages.add(userMessage);
    notifyListeners();

    try {
      final result = await _service.sendPrompt(
        agent: _agentProvider.selectedAgent,
        prompt: trimmedPrompt,
        persona: _agentProvider.persona,
        logToMemory: _agentProvider.logToMemory,
        sessionTag: _sessionTag.isEmpty ? null : _sessionTag,
      );

      final responseText = _extractResponseText(result.body, result.rawBody);
      final assistantMessage = MindWorksMessage(role: 'assistant', content: responseText);
      _messages.add(assistantMessage);

      _registerDebugEntry(
        prompt: trimmedPrompt,
        response: responseText,
        rawResponse: result.rawBody,
        statusCode: result.statusCode,
        duration: result.duration,
      );
    } on MindWorksApiException catch (error) {
      _registerDebugEntry(
        prompt: trimmedPrompt,
        response: error.result.body.toString(),
        rawResponse: error.result.rawBody,
        statusCode: error.result.statusCode,
        duration: error.result.duration,
        errorMessage: error.message,
      );
      _setError(error.message ?? 'MindWorks request failed.');
    } catch (error) {
      _registerDebugEntry(
        prompt: trimmedPrompt,
        response: error.toString(),
        rawResponse: error.toString(),
        statusCode: -1,
        duration: Duration.zero,
        errorMessage: error.toString(),
      );
      _setError('Unexpected error: $error');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearConversation() {
    _messages.clear();
    _errorMessage = null;
    _lastStatus = null;
    _statusResetTimer?.cancel();
    _statusResetTimer = null;
    notifyListeners();
  }

  void updateSessionTag(String value) {
    _sessionTag = value;
    _sessionTagDebounce?.cancel();
    _sessionTagDebounce = Timer(const Duration(milliseconds: 400), () {
      Hive.box('settings').put('sessionTag', value);
    });
    notifyListeners();
  }

  void setPersona(String? persona) {
    _agentProvider.selectPersona(persona);
  }

  void toggleLogToMemory(bool value) {
    _agentProvider.toggleLogToMemory(value);
  }

  void _registerDebugEntry({
    required String prompt,
    required String response,
    required String rawResponse,
    required int statusCode,
    required Duration duration,
    String? errorMessage,
  }) {
    final entry = MindWorksDebugEntry(
      prompt: prompt,
      response: response,
      rawResponse: rawResponse,
      statusCode: statusCode,
      duration: duration,
      errorMessage: errorMessage,
    );

    _debugEntries.insert(0, entry);
    if (_debugEntries.length > 10) {
      _debugEntries.removeLast();
    }

    _lastStatus = entry;
    notifyListeners();

    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(const Duration(seconds: 10), () {
      _lastStatus = null;
      notifyListeners();
    });
  }

  String _extractResponseText(Map<String, dynamic> body, String rawBody) {
    final possibleKeys = ['response', 'text', 'output', 'message', 'content'];
    for (final key in possibleKeys) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      if (value is Map<String, dynamic>) {
        final nested = value['text'] ?? value['content'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested;
        }
      }
    }
    return rawBody;
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusResetTimer?.cancel();
    _sessionTagDebounce?.cancel();
    super.dispose();
  }
}
