import 'package:dartz/dartz.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/entities/chat_entity.dart';
import 'package:rag_knowledge_assistant/domain/entities/document_entity.dart';

abstract class RagRepository {
  /// Upload and index a document.
  /// Returns [IngestResultEntity] on success, [Failure] on error.
  Future<Either<Failure, IngestResultEntity>> ingestDocument({
    required String filePath,
    required String filename,
    required List<int> fileBytes,
  });

  /// Ask a question against indexed documents.
  /// Returns [QueryResponseEntity] with answer + sources on success.
  Future<Either<Failure, QueryResponseEntity>> queryKnowledgeBase({
    required String question,
    String? documentFilter,
    int topK = 5,
  });

  /// List all currently indexed documents.
  /// Returns [DocumentListEntity] on success.
  Future<Either<Failure, DocumentListEntity>> listDocuments();

  /// Delete a document and all its chunks from the index.
  /// Returns void on success.
  Future<Either<Failure, void>> deleteDocument(String filename);
}