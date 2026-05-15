import 'package:equatable/equatable.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/entities/chat_entity.dart';

// ── Chat message model ────────────────────────────────────────────────
enum MessageRole { user, assistant }

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final MessageRole role;
  final List<SourceEntity> sources;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.timestamp,
    this.sources = const [],
  });

  @override
  List<Object?> get props => [id, text, role, sources, timestamp];
}

// ── States ────────────────────────────────────────────────────────────
abstract class ChatState extends Equatable {
  final List<ChatMessage> messages;

  const ChatState({this.messages = const []});

  @override
  List<Object?> get props => [messages];
}

/// Initial — no messages yet
class ChatInitial extends ChatState {
  const ChatInitial() : super(messages: const []);
}

/// Thinking — question sent, waiting for answer
class ChatThinking extends ChatState {
  const ChatThinking({required super.messages});
}

/// Answer received — messages updated
class ChatAnswered extends ChatState {
  const ChatAnswered({required super.messages});
}

/// Error — keeps existing messages visible
class ChatError extends ChatState {
  final Failure failure;

  const ChatError({
    required this.failure,
    required super.messages,
  });

  @override
  List<Object?> get props => [failure, messages];
}