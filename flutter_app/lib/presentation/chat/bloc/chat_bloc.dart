import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:rag_knowledge_assistant/domain/usecases/ask_question.dart';
import 'package:rag_knowledge_assistant/presentation/chat/bloc/chat_event.dart';
import 'package:rag_knowledge_assistant/presentation/chat/bloc/chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final AskQuestion askQuestion;
  final _uuid = const Uuid();

  // Store last question for retry
  AskQuestionEvent? _lastEvent;

  ChatBloc({required this.askQuestion}) : super(const ChatInitial()) {
    on<AskQuestionEvent>(_onAskQuestion);
    on<ClearChatEvent>(_onClearChat);
    on<RetryLastQuestionEvent>(_onRetry);
  }

  // ── Ask question ──────────────────────────────────────────────────
  Future<void> _onAskQuestion(
    AskQuestionEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Guard: empty question
    if (event.question.trim().isEmpty) return;

    _lastEvent = event;

    // Add user message immediately
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: event.question,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];

    emit(ChatThinking(messages: updatedMessages));

    // Call usecase
    final result = await askQuestion(
      AskQuestionParams(
        question: event.question,
        documentFilter: event.documentFilter,
        topK: event.topK,
      ),
    );

    result.fold(
      // ── Error ──────────────────────────────────────────────────
      (failure) => emit(
        ChatError(
          failure: failure,
          messages: updatedMessages,
        ),
      ),

      // ── Success ────────────────────────────────────────────────
      (entity) {
        final assistantMessage = ChatMessage(
          id: _uuid.v4(),
          text: entity.answer,
          role: MessageRole.assistant,
          sources: entity.sources,
          timestamp: DateTime.now(),
        );

        emit(
          ChatAnswered(
            messages: [...updatedMessages, assistantMessage],
          ),
        );
      },
    );
  }

  // ── Clear chat ────────────────────────────────────────────────────
  void _onClearChat(
    ClearChatEvent event,
    Emitter<ChatState> emit,
  ) {
    _lastEvent = null;
    emit(const ChatInitial());
  }

  // ── Retry last question ───────────────────────────────────────────
  Future<void> _onRetry(
    RetryLastQuestionEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (_lastEvent == null) return;
    await _onAskQuestion(_lastEvent!, emit);
  }
}