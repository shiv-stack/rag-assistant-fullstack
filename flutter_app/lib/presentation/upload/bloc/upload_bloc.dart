import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rag_knowledge_assistant/core/constants/api_constants.dart';
import 'package:rag_knowledge_assistant/core/constants/app_constants.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/domain/usecases/upload_document.dart';
import 'package:rag_knowledge_assistant/presentation/upload/bloc/upload_event.dart';
import 'package:rag_knowledge_assistant/presentation/upload/bloc/upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadDocument uploadDocument;

  UploadBloc({required this.uploadDocument}) : super(const UploadInitial()) {
    on<PickFileEvent>(_onPickFile);
    on<UploadFileEvent>(_onUploadFile);
    on<ResetUploadEvent>(_onReset);
  }

  // ── Pick file ─────────────────────────────────────────────────────
  Future<void> _onPickFile(
    PickFileEvent event,
    Emitter<UploadState> emit,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.allowedExtensions,
        withData: true, // required for web — loads bytes
      );

      if (result == null || result.files.isEmpty) {
        // user cancelled — stay in current state
        return;
      }

      final file = result.files.first;

      // Validate bytes available
      if (file.bytes == null) {
        emit(const UploadError(
          failure: FilePickFailure('Could not read file. Please try again.'),
        ));
        return;
      }

      final sizeMb = file.bytes!.length / (1024 * 1024);

      // ── Client-side size validation ───────────────────────────────
      if (sizeMb > ApiConstants.maxFileSizeMb) {
        emit(UploadError(
          failure: FileTooLargeFailure(
            'File is ${sizeMb.toStringAsFixed(1)}MB. '
            'Max allowed is ${ApiConstants.maxFileSizeMb}MB.',
          ),
        ));
        return;
      }

      // ── Client-side extension validation ──────────────────────────
      final ext = file.extension?.toLowerCase() ?? '';
      if (!AppConstants.allowedExtensions.contains(ext)) {
        emit(UploadError(
          failure: UnsupportedFileFailure(
            'File type .$ext is not supported. '
            'Use: ${AppConstants.allowedExtensions.join(', ')}',
          ),
        ));
        return;
      }

      // Show file preview — user confirms before upload
      emit(UploadFilePicked(
        filename: file.name,
        fileSizeMb: sizeMb,
        fileBytes: file.bytes!, // ← add this
      ));
    } catch (e) {
      emit(UploadError(
        failure: FilePickFailure('Failed to pick file: $e'),
      ));
    }
  }

  // ── Upload file ───────────────────────────────────────────────────
  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<UploadState> emit,
  ) async {
    // Double-check size before upload
    if (event.fileSizeMb > ApiConstants.maxFileSizeMb) {
      emit(UploadError(
        failure: FileTooLargeFailure(
          'File too large: ${event.fileSizeMb.toStringAsFixed(1)}MB. '
          'Max is ${ApiConstants.maxFileSizeMb}MB.',
        ),
      ));
      return;
    }

    emit(UploadInProgress(filename: event.filename));

    final result = await uploadDocument(
      UploadDocumentParams(
        filePath: event.filePath,
        filename: event.filename,
        fileBytes: event.fileBytes,
      ),
    );

    result.fold(
      (failure) => emit(UploadError(failure: failure)),
      (entity) => emit(UploadSuccess(result: entity)),
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────
  void _onReset(
    ResetUploadEvent event,
    Emitter<UploadState> emit,
  ) {
    emit(const UploadInitial());
  }
}
