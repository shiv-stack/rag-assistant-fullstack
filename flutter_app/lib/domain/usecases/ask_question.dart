import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/entities/chat_entity.dart';
import 'package:rag_knowledge_assistant/domain/repositories/rag_repository.dart';

class AskQuestion {
  final RagRepository repository;

  const AskQuestion(this.repository);

  Future<Either<Failure, QueryResponseEntity>> call(AskQuestionParams params) {
    return repository.queryKnowledgeBase(
      question: params.question,
      documentFilter: params.documentFilter,
      topK: params.topK,
    );
  }
}

class AskQuestionParams extends Equatable {
  final String question;
  final String? documentFilter;
  final int topK;

  const AskQuestionParams({
    required this.question,
    this.documentFilter,
    this.topK = 5,
  });

  @override
  List<Object?> get props => [question, documentFilter, topK];
}