import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/repositories/rag_repository.dart';

class DeleteDocument {
  final RagRepository repository;

  const DeleteDocument(this.repository);

  Future<Either<Failure, void>> call(DeleteDocumentParams params) {
    return repository.deleteDocument(params.filename);
  }
}

class DeleteDocumentParams extends Equatable {
  final String filename;

  const DeleteDocumentParams({required this.filename});

  @override
  List<Object?> get props => [filename];
}