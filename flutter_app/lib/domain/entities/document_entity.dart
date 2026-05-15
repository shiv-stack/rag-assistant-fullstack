import 'package:equatable/equatable.dart';

class DocumentListEntity extends Equatable {
  final List<String> documents;
  final int totalDocuments;
  final int totalChunks;

  const DocumentListEntity({
    required this.documents,
    required this.totalDocuments,
    required this.totalChunks,
  });

  @override
  List<Object?> get props => [documents, totalDocuments, totalChunks];
}


class IngestResultEntity extends Equatable {
  final String message;
  final String filename;
  final int chunksCreated;
  final String documentId;

  const IngestResultEntity({
    required this.message,
    required this.filename,
    required this.chunksCreated,
    required this.documentId,
  });

  @override
  List<Object?> get props => [message, filename, chunksCreated, documentId];
}