import '../../domain/entities/document_entity.dart';

class DocumentListResponseModel {
  final List<String> documents;
  final int totalDocuments;
  final int totalChunks;

  const DocumentListResponseModel({
    required this.documents,
    required this.totalDocuments,
    required this.totalChunks,
  });

  factory DocumentListResponseModel.fromJson(Map<String, dynamic> json) {
    return DocumentListResponseModel(
      documents: List<String>.from(json['documents'] as List),
      totalDocuments: json['total_documents'] as int,
      totalChunks: json['total_chunks'] as int,
    );
  }

  // Convert to domain entity
  DocumentListEntity toEntity() => DocumentListEntity(
        documents: documents,
        totalDocuments: totalDocuments,
        totalChunks: totalChunks,
      );
}


class IngestResponseModel {
  final String message;
  final String filename;
  final int chunksCreated;
  final String documentId;

  const IngestResponseModel({
    required this.message,
    required this.filename,
    required this.chunksCreated,
    required this.documentId,
  });

  factory IngestResponseModel.fromJson(Map<String, dynamic> json) {
    return IngestResponseModel(
      message: json['message'] as String,
      filename: json['filename'] as String,
      chunksCreated: json['chunks_created'] as int,
      documentId: json['document_id'] as String,
    );
  }

  // Convert to domain entity
  IngestResultEntity toEntity() => IngestResultEntity(
        message: message,
        filename: filename,
        chunksCreated: chunksCreated,
        documentId: documentId,
      );
}