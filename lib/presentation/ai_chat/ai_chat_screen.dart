import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/first_aid_llm_service.dart';
import '../../domain/services/llm_inference_service.dart';
import '../../domain/services/hardware_profiler_service.dart';
import '../../providers/llm_provider.dart';
import '../../core/theme/app_theme.dart';
import 'llm_settings_screen.dart';

// ─────────────────────────────────────────────
// Data
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
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirstAidLlmService _kbService = FirstAidLlmService();

  bool _useLlm = false; // Toggle: Knowledge Base vs. LLM

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
    // Instant ~0ms response — no async needed
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final reply = _kbService.query(query);
      setState(() {
        _messages.add(ChatMessage(
          text: reply,
          source: MessageSource.knowledgeBase,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  Future<void> _runLlmInference(String query) async {
    final inference = ref.read(llmInferenceServiceProvider);

    if (!inference.isLoaded) {
      // Try to load the best available model on demand
      await ref.read(modelLoaderProvider.notifier).loadModel(
            ref.read(activeTierProvider),
          );

      if (!inference.isLoaded) {
        // Still not loaded — fall back to KB silently and warn user
        _runKnowledgeBase(query);
        if (mounted) {
          _addSystemMessage(
            '⚠️ No model loaded. Showing Knowledge Base result.\n'
            'Go to **Settings ⚙** to download a model.',
          );
        }
        return;
      }
    }

    // Add a streaming placeholder bubble
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

    await inference.infer(
      userInput: query,
      onToken: (token, done) {
        if (!mounted) return;
        buffer.write(token);
        setState(() {
          _messages[placeholderIndex] = _messages[placeholderIndex].copyWith(
            text: buffer.toString(),
            isStreaming: !done,
          );
        });
        if (done) _scrollToBottom();
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

    final suggestions = [
      'Tear Gas / Eyes',
      'Severe Bleeding',
      'Rubber Bullet',
      'Arrest Rights',
      'Heat Stroke',
      'Improvised Kit',
      'Crowd Crush',
      'CPR Steps',
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Status bar ──────────────────────────────
          _buildStatusBar(theme, activeTier, inferState),

          // ── Mode toggle + settings ───────────────────
          _buildModeToggleBar(theme),

          // ── Quick-action chips ───────────────────────
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    suggestions[i],
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.secondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onPressed: () => _handleSubmitted(suggestions[i]),
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Message list ────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i]),
            ),
          ),

          const Divider(height: 1),

          // ── Input row ───────────────────────────────
          _buildInputRow(theme, inferState),
        ],
      ),
    );
  }

  Widget _buildStatusBar(
    ThemeData theme,
    ModelTier activeTier,
    AsyncValue<InferenceState> inferState,
  ) {
    final tierLabel = HardwareProfilerService.tierLabel(activeTier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off, size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '100% OFFLINE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          // Model tier badge
          inferState.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (s) => _ModelTierBadge(
              tier: activeTier,
              tierLabel: tierLabel,
              status: s.status,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          // Toggle
          GestureDetector(
            onTap: () => setState(() => _useLlm = !_useLlm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _useLlm
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.12),
                border: Border.all(
                  color:
                      _useLlm ? const Color(0xFF00E5FF) : Colors.orange,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _useLlm ? Icons.memory : Icons.library_books,
                    size: 14,
                    color: _useLlm ? const Color(0xFF00E5FF) : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _useLlm ? 'Local LLM Mode' : 'Knowledge Base Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _useLlm
                          ? const Color(0xFF00E5FF)
                          : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.swap_horiz,
                    size: 14,
                    color: _useLlm
                        ? const Color(0xFF00E5FF)
                        : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Settings button
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
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(width: 8),
            isInferring
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    color: theme.colorScheme.primary,
                    onPressed: () => _handleSubmitted(_controller.text),
                  ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Message bubble
  // ─────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage message) {
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

    return Container(
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
                  : _buildRichTextContent(message.text),
            ),
          ),
        ],
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
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Thinking...',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Markdown renderer (preserved from original)
  // ─────────────────────────────────────────────

  Widget _buildRichTextContent(String text) {
    final theme = Theme.of(context);
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.replaceFirst('### ', ''),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('*Category:') ||
          line.startsWith('*') && line.endsWith('*')) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.replaceAll('*', ''),
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('**⚠️') ||
          line.startsWith('**🚑') ||
          line.startsWith('**📋')) {
        final cleaned = line.replaceAll('**', '');
        final Color headerColor = line.contains('⚠️')
            ? AppTheme.criticalColor
            : line.contains('🚑')
                ? Colors.orange
                : theme.colorScheme.onSurface;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            cleaned,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: headerColor,
            ),
          ),
        ));
      } else if (line.startsWith('**')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.replaceAll('**', ''),
            style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold),
          ),
        ));
      } else if (line.startsWith('* Do NOT') || line.startsWith('* Do')) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(
                      color: AppTheme.criticalColor,
                      fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  line.replaceFirst('* ', '').replaceAll('**', ''),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.criticalColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('* ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  line.replaceFirst('* ', '').replaceAll('**', ''),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+\. )(.*)').firstMatch(line);
        final numPrefix = match?.group(1) ?? '';
        final restText = match?.group(2) ?? '';
        children.add(Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(numPrefix,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  restText.replaceAll('**', ''),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            line.replaceAll('**', '').replaceAll('*', ''),
            style: theme.textTheme.bodyLarge,
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
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
    final color = _color();
    final isActive = status != InferenceStatus.unloaded;

    if (!isActive) {
      return const Text(
        'KB MODE',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == InferenceStatus.inferring)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: color),
              ),
            ),
          Text(
            'QWEN2.5 · $tierLabel',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Color _color() {
    switch (tier) {
      case ModelTier.base:
        return Colors.orange;
      case ModelTier.enhancement1:
        return const Color(0xFF00E5FF);
      case ModelTier.enhancement2:
        return const Color(0xFF69FF47);
    }
  }
}
