import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/entities/document_entity.dart';
import 'package:rag_knowledge_assistant/domain/repositories/rag_repository.dart';

class UploadDocument {
  final RagRepository repository;

  const UploadDocument(this.repository);

  Future<Either<Failure, IngestResultEntity>> call(UploadDocumentParams params) {
    return repository.ingestDocument(
      filePath: params.filePath,
      filename: params.filename,
      fileBytes: params.fileBytes,
    );
  }
}

class UploadDocumentParams extends Equatable {
  final String filePath;
  final String filename;
  final List<int> fileBytes;

  const UploadDocumentParams({
    required this.filePath,
    required this.filename,
    required this.fileBytes,
  });

  @override
  List<Object?> get props => [filePath, filename];
}