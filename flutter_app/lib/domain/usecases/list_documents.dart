import 'package:dartz/dartz.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/entities/document_entity.dart';
import 'package:rag_knowledge_assistant/domain/repositories/rag_repository.dart';

class ListDocuments {
  final RagRepository repository;

  const ListDocuments(this.repository);

  Future<Either<Failure, DocumentListEntity>> call() {
    return repository.listDocuments();
  }
}