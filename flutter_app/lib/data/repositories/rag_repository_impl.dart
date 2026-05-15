import 'package:dartz/dartz.dart';
import 'package:rag_knowledge_assistant/core/error/exceptions.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/data/datasources/rag_remote_datasource.dart';
import 'package:rag_knowledge_assistant/domain/entities/chat_entity.dart';
import 'package:rag_knowledge_assistant/domain/entities/document_entity.dart';
import 'package:rag_knowledge_assistant/domain/repositories/rag_repository.dart';

class RagRepositoryImpl implements RagRepository {
  final RagRemoteDataSource remoteDataSource;

  const RagRepositoryImpl({required this.remoteDataSource});

  // ── Ingest ────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, IngestResultEntity>> ingestDocument({
    required String filePath,
    required String filename,
    required List<int> fileBytes,
  }) async {
    try {
      final model = await remoteDataSource.ingestDocument(
        filePath: filePath,
        filename: filename,
        fileBytes: fileBytes,
      );
      return Right(model.toEntity());
    } on IngestException catch (e) {
      return Left(IngestFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(IngestFailure('Unexpected ingest error: $e'));
    }
  }

  // ── Query ─────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, QueryResponseEntity>> queryKnowledgeBase({
    required String question,
    String? documentFilter,
    int topK = 5,
  }) async {
    // Guard: empty question
    if (question.trim().isEmpty) {
      return Left(EmptyQuestionFailure('Please enter a question first.'));
    }

    try {
      final model = await remoteDataSource.queryKnowledgeBase(
        question: question,
        documentFilter: documentFilter,
        topK: topK,
      );
      return Right(model.toEntity());
    } on QueryException catch (e) {
      return Left(QueryFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(QueryFailure('Unexpected query error: $e'));
    }
  }

  // ── List documents ────────────────────────────────────────────────
  @override
  Future<Either<Failure, DocumentListEntity>> listDocuments() async {
    try {
      final model = await remoteDataSource.listDocuments();
      return Right(model.toEntity());
    } on NetworkException catch (e) {
      return Left(DocumentListFailure(e.message));
    } catch (e) {
      return Left(DocumentListFailure('Failed to fetch documents: $e'));
    }
  }

  // ── Delete document ───────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> deleteDocument(String filename) async {
    try {
      await remoteDataSource.deleteDocument(filename);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(DocumentDeleteFailure(e.message));
    } catch (e) {
      return Left(DocumentDeleteFailure('Failed to delete document: $e'));
    }
  }
}