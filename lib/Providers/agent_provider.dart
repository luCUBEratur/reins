import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Provides state for the currently selected MindWorks agent,
/// persona preset, and memory logging flag.
class AgentProvider with ChangeNotifier {
  AgentProvider() {
    final box = Hive.box('settings');
    _selectedAgent = box.get('agent', defaultValue: _selectedAgent);
    _persona = box.get('persona');
    _logToMemory = box.get('logToMemory', defaultValue: false);
  }

  String _selectedAgent = 'MIRA';
  String? _persona;
  bool _logToMemory = false;

  String get selectedAgent => _selectedAgent;
  String? get persona => _persona;
  bool get logToMemory => _logToMemory;

  void selectAgent(String agent) {
    _selectedAgent = agent;
    Hive.box('settings').put('agent', agent);
    notifyListeners();
  }

  void selectPersona(String? persona) {
    _persona = persona;
    Hive.box('settings').put('persona', persona);
    notifyListeners();
  }

  void toggleLogToMemory(bool value) {
    _logToMemory = value;
    Hive.box('settings').put('logToMemory', value);
    notifyListeners();
  }
}
