import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/first_aid_llm_service.dart';
import '../../domain/services/hardware_profiler_service.dart';
import '../../domain/services/llm_inference_service.dart';
import '../../providers/llm_provider.dart';
import 'llm_settings_screen.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

enum MessageSource { user, knowledgeBase, llm }

class ChatMessage {
  final String text;
  final MessageSource source;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.source,
    required this.timestamp,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      text: text ?? this.text,
      source: source,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirstAidLlmService _kbService = FirstAidLlmService();

  bool _useLlm = false; // Toggle: Knowledge Base vs. LLM

  List<String> get _suggestions => _kbService.topicTitles;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: '### 🧠 OFFLINE FIRST-AID AI\n\n'
            'I run **completely offline** with no internet connection required.\n\n'
            '**Mode A** 🟡 — Knowledge Base: instant answers, always available.\n'
            '**Mode B** 🔵 — Local LLM: deeper context, requires a downloaded model.\n\n'
            'Select a topic below or type your question.',
        source: MessageSource.knowledgeBase,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Message handling
  // ─────────────────────────────────────────────

  Future<void> _handleSubmitted(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: query,
        source: MessageSource.user,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    if (_useLlm) {
      await _runLlmInference(query);
    } else {
      _runKnowledgeBase(query);
    }
  }

  void _runKnowledgeBase(String query) {
    final answer = _kbService.query(query);
    setState(() {
      _messages.add(ChatMessage(
        text: answer,
        source: MessageSource.knowledgeBase,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _runLlmInference(String query) async {
    final inference = ref.read(llmInferenceServiceProvider);

    if (!inference.isModelReady) {
      _addSystemMessage(
        '⚠️ **No LLM model loaded.** Go to **Settings** (⚙️ top-right) '
        'to download or select a model, or switch to **Knowledge Base Mode**.',
      );
      return;
    }

    final placeholderIndex = _messages.length;
    setState(() {
      _messages.add(ChatMessage(
        text: '',
        source: MessageSource.llm,
        timestamp: DateTime.now(),
        isStreaming: true,
      ));
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    DateTime lastTokenUpdate = DateTime.now();

    await inference.infer(
      userInput: query,
      onToken: (token, done) {
        if (!mounted) return;
        buffer.write(token);

        final now = DateTime.now();
        if (done || now.difference(lastTokenUpdate).inMilliseconds > 80) {
          lastTokenUpdate = now;
          setState(() {
            _messages[placeholderIndex] = _messages[placeholderIndex].copyWith(
              text: buffer.toString(),
              isStreaming: !done,
            );
          });
          if (done) _scrollToBottom();
        }
      },
    );
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        source: MessageSource.knowledgeBase,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inferState = ref.watch(inferenceStateProvider);
    final activeTier = ref.watch(activeTierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety AI Triage'),
        actions: [
          _buildHardwareBadge(activeTier, inferState),
        ],
      ),
      body: Column(
        children: [
          _buildModeToggleHeader(theme),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatMessageBubble(
                  key: ValueKey(message.timestamp.millisecondsSinceEpoch),
                  message: message,
                );
              },
            ),
          ),
          _buildSuggestionsRow(theme),
          _buildInputRow(theme, inferState),
        ],
      ),
    );
  }

  Widget _buildHardwareBadge(
    ModelTier tier,
    AsyncValue<InferenceState> inferState,
  ) {
    final status = inferState.maybeWhen(
      data: (s) => s.status,
      orElse: () => InferenceStatus.unloaded,
    );
    final String label = tier.name.toUpperCase();


    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _ModelTierBadge(
        tier: tier,
        tierLabel: label,
        status: status,
      ),
    );
  }

  Widget _buildModeToggleHeader(ThemeData theme) {
    final color = _useLlm ? const Color(0xFF00E5FF) : Colors.amber;

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _useLlm = !_useLlm;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: _useLlm ? 0.15 : 0.12),
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _useLlm ? Icons.memory : Icons.library_books,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _useLlm ? 'Local LLM Mode' : 'Knowledge Base Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.swap_horiz, size: 14, color: color),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'LLM Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const LlmSettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow(ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final title = _suggestions[index];
          return ActionChip(
            label: Text(title, style: const TextStyle(fontSize: 12)),
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(color: theme.colorScheme.secondary),
            onPressed: () => _handleSubmitted(title),
          );
        },
      ),
    );
  }

  Widget _buildInputRow(ThemeData theme, AsyncValue<InferenceState> inferState) {
    final isInferring = inferState.maybeWhen(
      data: (s) => s.status == InferenceStatus.inferring,
      orElse: () => false,
    );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: _handleSubmitted,
                enabled: !isInferring,
                decoration: InputDecoration(
                  hintText: isInferring
                      ? 'LLM is thinking...'
                      : _useLlm
                          ? 'Ask the local LLM...'
                          : 'Search first-aid KB...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  fillColor: theme.scaffoldBackgroundColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: isInferring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: isInferring
                  ? null
                  : () => _handleSubmitted(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Independent StatelessWidget for Chat Bubbles ensuring isolated rebuilds.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.source == MessageSource.user;
    final isLlm = message.source == MessageSource.llm;

    final Color bubbleColor = isUser
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : isLlm
            ? const Color(0xFF00E5FF).withValues(alpha: 0.07)
            : theme.colorScheme.surface;

    final Color borderColor = isUser
        ? theme.colorScheme.primary.withValues(alpha: 0.3)
        : isLlm
            ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
            : theme.colorScheme.secondary;

    return Semantics(
      label: '${isUser ? "User" : "AI"} message: ${message.text}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: isLlm
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                      : AppTheme.criticalColor,
                  radius: 16,
                  child: Icon(
                    isLlm ? Icons.memory : Icons.psychology,
                    size: 18,
                    color: isLlm ? const Color(0xFF00E5FF) : Colors.white,
                  ),
                ),
              ),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: Radius.circular(isUser ? 8 : 2),
                    bottomRight: Radius.circular(isUser ? 2 : 8),
                  ),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: message.isStreaming && message.text.isEmpty
                    ? _buildThinkingIndicator()
                    : isUser
                        ? Text(message.text, style: theme.textTheme.bodyLarge)
                        : MarkdownBody(
                            data: message.text,
                            styleSheet: _markdownStyleSheet(theme),
                            softLineBreak: true,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(
          'Thinking...',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  MarkdownStyleSheet _markdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      p: theme.textTheme.bodyMedium,
      listBullet: theme.textTheme.bodyMedium,
      blockquoteDecoration: BoxDecoration(
        color: AppTheme.criticalColor.withValues(alpha: 0.1),
        border: const Border(
          left: BorderSide(color: AppTheme.criticalColor, width: 3),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Model tier badge widget
// ─────────────────────────────────────────────

class _ModelTierBadge extends StatelessWidget {
  final ModelTier tier;
  final String tierLabel;
  final InferenceStatus status;

  const _ModelTierBadge({
    required this.tier,
    required this.tierLabel,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForTier(tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == InferenceStatus.inferring
                  ? Colors.greenAccent
                  : status == InferenceStatus.ready
                      ? Colors.blue
                      : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            tierLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForTier(ModelTier tier) {
    switch (tier) {
      case ModelTier.base:
        return Colors.green;
      case ModelTier.enhancement1:
        return Colors.blue;
      case ModelTier.enhancement2:
        return Colors.purple;
    }
  }
}
