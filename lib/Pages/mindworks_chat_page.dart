import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:reins/Constants/app_constants.dart';
import 'package:reins/Models/mindworks_message.dart';
import 'package:reins/Providers/agent_provider.dart';
import 'package:reins/Providers/mindworks_chat_provider.dart';
import 'package:reins/Widgets/agent_selector.dart';

class MindWorksChatPage extends StatefulWidget {
  const MindWorksChatPage({super.key});

  @override
  State<MindWorksChatPage> createState() => _MindWorksChatPageState();
}

class _MindWorksChatPageState extends State<MindWorksChatPage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _sessionTagController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  static const List<String> _defaultAgents = <String>['MIRA', 'Keeper', 'Analytica', 'AURA'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MindWorksChatProvider>();
      _sessionTagController.text = provider.sessionTag;
    });
    _sessionTagController.addListener(() {
      context.read<MindWorksChatProvider>().updateSessionTag(_sessionTagController.text);
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _sessionTagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentProvider = context.watch<AgentProvider>();
    final chatProvider = context.watch<MindWorksChatProvider>();
    final lastStatus = chatProvider.lastStatus;
    final errorMessage = chatProvider.errorMessage;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Clear conversation',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => context.read<MindWorksChatProvider>().clearConversation(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AgentSelector(agents: _defaultAgents),
                      _PersonaDropdown(personas: chatProvider.personas),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: agentProvider.logToMemory,
                            onChanged: (value) => context.read<MindWorksChatProvider>().toggleLogToMemory(value),
                          ),
                          const SizedBox(width: 8),
                          const Text('Log to memory'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sessionTagController,
                    decoration: const InputDecoration(
                      labelText: 'Session tag',
                      hintText: 'e.g. onboarding-session-01',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (lastStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _ApiStatusChip(entry: lastStatus),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Consumer<MindWorksChatProvider>(
                builder: (context, provider, _) {
                  if (_lastMessageCount != provider.messages.length) {
                    _lastMessageCount = provider.messages.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  }
                  if (provider.messages.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      return _MessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            _PromptComposer(
              controller: _promptController,
              onSend: _handleSend,
            ),
            const Divider(height: 1),
            const _DebugPanel(),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;
    final chatProvider = context.read<MindWorksChatProvider>();
    await chatProvider.sendPrompt(text);
    if (mounted) {
      _promptController.clear();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _PersonaDropdown extends StatelessWidget {
  const _PersonaDropdown({required this.personas});

  final List<String> personas;

  @override
  Widget build(BuildContext context) {
    final agentProvider = context.watch<AgentProvider>();
    return DropdownButton<String?>(
      value: agentProvider.persona,
      hint: const Text('Persona'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Default persona')),
        ...personas.map(
          (persona) => DropdownMenuItem<String?>(
            value: persona,
            child: Text(persona),
          ),
        ),
      ],
      onChanged: (value) => context.read<MindWorksChatProvider>().setPersona(value),
    );
  }
}

class _PromptComposer extends StatelessWidget {
  const _PromptComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<MindWorksChatProvider>().isSending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Ask MindWorks…',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isSending ? null : () => onSend(),
            icon: isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(isSending ? 'Sending…' : 'Send'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final MindWorksMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceVariant;
    final textColor = isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              isUser ? 'You' : 'MindWorks',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 4),
            if (isUser)
              Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
              )
            else
              MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                  code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontFamily: 'monospace',
                      ),
                  h1: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  h2: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  h3: Theme.of(context).textTheme.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  listBullet: TextStyle(color: textColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.psychology_alt_outlined, size: 48),
          SizedBox(height: 12),
          Text('Start a conversation with your MindWorks agents'),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<MindWorksChatProvider>(
      builder: (context, provider, _) {
        return ExpansionTile(
          title: const Text('Debug panel'),
          subtitle: Text(
            provider.debugEntries.isEmpty
                ? 'No logs yet'
                : 'Showing ${provider.debugEntries.length} recent interactions',
          ),
          children: [
            if (provider.debugEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Interact with MindWorks to see request logs here.'),
              )
            else
              SizedBox(
                height: 240,
                child: ListView.builder(
                  itemCount: provider.debugEntries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.debugEntries[index];
                    return ListTile(
                      title: Text(entry.prompt),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${entry.statusCode} • ${entry.duration.inMilliseconds} ms'),
                          if (entry.isError && entry.errorMessage != null)
                            Text(
                              entry.errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          const SizedBox(height: 4),
                          SelectableText('Response: ${entry.response}'),
                          const SizedBox(height: 4),
                          SelectableText('Raw: ${entry.rawResponse}'),
                        ],
                      ),
                      trailing: Text(
                        TimeOfDay.fromDateTime(entry.timestamp).format(context),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ApiStatusChip extends StatelessWidget {
  const _ApiStatusChip({required this.entry});

  final MindWorksDebugEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = entry.isError;
    final color = isError ? colorScheme.errorContainer : colorScheme.secondaryContainer;
    final textColor = isError ? colorScheme.onErrorContainer : colorScheme.onSecondaryContainer;

    return Chip(
      backgroundColor: color,
      label: Text(
        isError
            ? 'API error ${entry.statusCode}'
            : 'API ${entry.statusCode} • ${entry.duration.inMilliseconds} ms',
        style: TextStyle(color: textColor),
      ),
    );
  }
}
