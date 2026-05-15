import 'package:equatable/equatable.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/entities/document_entity.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

/// Initial — nothing selected yet
class UploadInitial extends UploadState {
  const UploadInitial();
}

/// File picked — showing preview before upload
class UploadFilePicked extends UploadState {
  final String filename;
  final double fileSizeMb;
  final List<int> fileBytes;   // ← add this

  const UploadFilePicked({
    required this.filename,
    required this.fileSizeMb,
    required this.fileBytes,   // ← add this
  });

  @override
  List<Object?> get props => [filename, fileSizeMb];
}

/// Uploading in progress
class UploadInProgress extends UploadState {
  final String filename;

  const UploadInProgress({required this.filename});

  @override
  List<Object?> get props => [filename];
}

/// Upload successful
class UploadSuccess extends UploadState {
  final IngestResultEntity result;

  const UploadSuccess({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Upload failed
class UploadError extends UploadState {
  final Failure failure;

  const UploadError({required this.failure});

  @override
  List<Object?> get props => [failure];
}