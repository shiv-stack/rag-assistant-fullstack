import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class AskQuestionEvent extends ChatEvent {
  final String question;
  final String? documentFilter;
  final int topK;

  const AskQuestionEvent({
    required this.question,
    this.documentFilter,
    this.topK = 5,
  });

  @override
  List<Object?> get props => [question, documentFilter, topK];
}

class ClearChatEvent extends ChatEvent {
  const ClearChatEvent();
}

class RetryLastQuestionEvent extends ChatEvent {
  const RetryLastQuestionEvent();
}