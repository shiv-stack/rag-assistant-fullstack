import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rag_knowledge_assistant/domain/usecases/delete_document.dart';
import 'package:rag_knowledge_assistant/domain/usecases/list_documents.dart';
import 'package:rag_knowledge_assistant/core/error/failures.dart';
import 'package:rag_knowledge_assistant/core/constants/app_constants.dart';

// ── Events ────────────────────────────────────────────────────────────
abstract class DocumentsEvent {}
class LoadDocumentsEvent extends DocumentsEvent {}
class DeleteDocumentEvent extends DocumentsEvent {
  final String filename;
  DeleteDocumentEvent(this.filename);
}

// ── States ────────────────────────────────────────────────────────────
abstract class DocumentsState {}
class DocumentsInitial extends DocumentsState {}
class DocumentsLoading extends DocumentsState {}
class DocumentsLoaded extends DocumentsState {
  final List<String> documents;
  final int totalChunks;
  DocumentsLoaded({required this.documents, required this.totalChunks});
}
class DocumentsError extends DocumentsState {
  final Failure failure;
  DocumentsError(this.failure);
}

// ── BLoC ──────────────────────────────────────────────────────────────
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final ListDocuments listDocuments;
  final DeleteDocument deleteDocument;

  DocumentsBloc({
    required this.listDocuments,
    required this.deleteDocument,
  }) : super(DocumentsInitial()) {
    on<LoadDocumentsEvent>(_onLoad);
    on<DeleteDocumentEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadDocumentsEvent event,
    Emitter<DocumentsState> emit,
  ) async {
    emit(DocumentsLoading());
    final result = await listDocuments();
    result.fold(
      (failure) => emit(DocumentsError(failure)),
      (entity) => emit(DocumentsLoaded(
        documents: entity.documents,
        totalChunks: entity.totalChunks,
      )),
    );
  }

  Future<void> _onDelete(
    DeleteDocumentEvent event,
    Emitter<DocumentsState> emit,
  ) async {
    final result = await deleteDocument(
      DeleteDocumentParams(filename: event.filename),
    );
    result.fold(
      (failure) => emit(DocumentsError(failure)),
      (_) => add(LoadDocumentsEvent()), // reload after delete
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indexed Documents'),
        centerTitle: true,
      ),
      body: BlocConsumer<DocumentsBloc, DocumentsState>(
        listener: (context, state) {
          if (state is DocumentsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentsInitial) {
            context.read<DocumentsBloc>().add(LoadDocumentsEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentsError) {
            return _ErrorView(
              message: state.failure.message,
              onRetry: () =>
                  context.read<DocumentsBloc>().add(LoadDocumentsEvent()),
            );
          }

          if (state is DocumentsLoaded) {
            if (state.documents.isEmpty) {
              return _EmptyView();
            }
            return _DocumentsList(state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Documents list ────────────────────────────────────────────────────
class _DocumentsList extends StatelessWidget {
  final DocumentsLoaded state;

  const _DocumentsList({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Text(
            '${state.documents.length} document${state.documents.length == 1 ? '' : 's'}  •  '
            '${state.totalChunks} chunks indexed',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final filename = state.documents[index];
              return _DocumentTile(filename: filename);
            },
          ),
        ),
      ],
    );
  }
}

// ── Document tile ─────────────────────────────────────────────────────
class _DocumentTile extends StatelessWidget {
  final String filename;

  const _DocumentTile({required this.filename});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _fileIcon(filename),
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          filename,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          filename.split('.').last.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade400,
          ),
          tooltip: 'Delete document',
          onPressed: () => _confirmDelete(context, filename),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String filename) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Remove "$filename" and all its chunks from the index?\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<DocumentsBloc>()
                  .add(DeleteDocumentEvent(filename));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'md':
        return Icons.code_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}

// ── Empty view ────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            AppConstants.emptyDocuments,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}