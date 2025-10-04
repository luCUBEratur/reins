import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reins/Providers/agent_provider.dart';

/// Dropdown widget allowing users to select the active MindWorks agent.
class AgentSelector extends StatelessWidget {
  const AgentSelector({super.key, required this.agents});

  final List<String> agents;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AgentProvider>();
    final options = <String>{...agents, provider.selectedAgent}.toList();
    options.remove(provider.selectedAgent);
    options.insert(0, provider.selectedAgent);
    return DropdownButton<String>(
      value: provider.selectedAgent,
      items: [
        for (final agent in options)
          DropdownMenuItem(value: agent, child: Text(agent)),
      ],
      onChanged: (value) {
        if (value != null) {
          context.read<AgentProvider>().selectAgent(value);
        }
      },
    );
  }
}
