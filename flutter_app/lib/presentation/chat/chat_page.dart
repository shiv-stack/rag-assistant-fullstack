import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rag_knowledge_assistant/core/constants/app_constants.dart';
import 'package:rag_knowledge_assistant/presentation/chat/bloc/chat_bloc.dart';
import 'package:rag_knowledge_assistant/presentation/chat/bloc/chat_event.dart';
import 'package:rag_knowledge_assistant/presentation/chat/bloc/chat_state.dart';
import 'package:rag_knowledge_assistant/presentation/widgets/source_card.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendQuestion(BuildContext context) {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    context.read<ChatBloc>().add(
          AskQuestionEvent(question: question),
        );

    _controller.clear();
    _focusNode.unfocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RAG Assistant'),
        centerTitle: true,
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.messages.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Clear chat',
                onPressed: () => context
                    .read<ChatBloc>()
                    .add(const ClearChatEvent()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages list ──────────────────────────────────────────
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatAnswered || state is ChatThinking) {
                  _scrollToBottom();
                }
                if (state is ChatError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ ${state.failure.message}'),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () => context
                            .read<ChatBloc>()
                            .add(const RetryLastQuestionEvent()),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatInitial) {
                  return _EmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length +
                      (state is ChatThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator at end
                    if (state is ChatThinking &&
                        index == state.messages.length) {
                      return _TypingIndicator();
                    }

                    final message = state.messages[index];
                    return message.role == MessageRole.user
                        ? _UserBubble(message: message)
                        : _AssistantBubble(message: message);
                  },
                );
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            onSend: () => _sendQuestion(context),
          ),
        ],
      ),
    );
  }
}

// ── Empty chat ────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.emptyChat,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── User bubble ───────────────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final ChatMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── Assistant bubble ──────────────────────────────────────────────────
class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;

  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + answer ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),

                // Answer bubble
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15, height: 1.5),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade200,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Source cards ─────────────────────────────────────────
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sources',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.sources
                          .map((s) => SourceCard(source: s))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceVariant
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(),
              const SizedBox(width: 4),
              _Dot(),
              const SizedBox(width: 4),
              _Dot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isThinking = state is ChatThinking;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isThinking,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: isThinking ? null : (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: AppConstants.queryHint,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isThinking
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton.filled(
                        onPressed: onSend,
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}