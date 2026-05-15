import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rag_knowledge_assistant/core/constants/app_constants.dart';
import 'package:rag_knowledge_assistant/core/constants/api_constants.dart';
import 'package:rag_knowledge_assistant/presentation/upload/bloc/upload_bloc.dart';
import 'package:rag_knowledge_assistant/presentation/upload/bloc/upload_event.dart';
import 'package:rag_knowledge_assistant/presentation/upload/bloc/upload_state.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        centerTitle: true,
      ),
      body: BlocConsumer<UploadBloc, UploadState>(
        listener: _listener,
        builder: _builder,
      ),
    );
  }

  // ── Listener — side effects ───────────────────────────────────────
  void _listener(BuildContext context, UploadState state) {
    if (state is UploadSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${state.result.filename} indexed! '
            '${state.result.chunksCreated} chunks created.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (state is UploadError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${state.failure.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ── Builder — UI ──────────────────────────────────────────────────
  Widget _builder(BuildContext context, UploadState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
            _Header(),
            const SizedBox(height: 32),
      
            // ── Drop zone / file picker ──────────────────────────────
            _DropZone(state: state),
            const SizedBox(height: 16),
      
            // ── File size hint ───────────────────────────────────────
            _SizeHint(),
            const SizedBox(height: 24),
      
            // ── File preview card (after picking) ────────────────────
            if (state is UploadFilePicked) ...[
              _FilePreviewCard(state: state),
              const SizedBox(height: 24),
            ],
      
            // ── Success card ─────────────────────────────────────────
            if (state is UploadSuccess) ...[
              _SuccessCard(state: state),
              const SizedBox(height: 24),
            ],
      
            const Spacer(),
      
            // ── Action buttons ───────────────────────────────────────
            _ActionButtons(state: state),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.upload_file_rounded,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Upload a Document',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.uploadHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Drop zone ─────────────────────────────────────────────────────────
class _DropZone extends StatelessWidget {
  final UploadState state;

  const _DropZone({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state is UploadInProgress;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () => context.read<UploadBloc>().add(const PickFileEvent()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state is UploadFilePicked
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: state is UploadFilePicked ? 2 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: isLoading
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Indexing document...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This may take a moment on first run',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select file',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Size hint ─────────────────────────────────────────────────────────
class _SizeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Supported: PDF, TXT, MD  •  Max size: ${ApiConstants.maxFileSizeMb}MB',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── File preview card ─────────────────────────────────────────────────
class _FilePreviewCard extends StatelessWidget {
  final UploadFilePicked state;

  const _FilePreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _fileIcon(state.filename),
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.filename,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.fileSizeMb.toStringAsFixed(2)} MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () =>
                context.read<UploadBloc>().add(const ResetUploadEvent()),
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

// ── Success card ──────────────────────────────────────────────────────
class _SuccessCard extends StatelessWidget {
  final UploadSuccess state;

  const _SuccessCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade600, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.result.filename,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.result.chunksCreated} chunks indexed successfully',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final UploadState state;

  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is UploadInProgress) {
      return const SizedBox.shrink();
    }

    if (state is UploadFilePicked) {
      final picked = state as UploadFilePicked;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.read<UploadBloc>().add(
                  UploadFileEvent(
                    filePath: '',
                    filename: picked.filename,
                    fileBytes: picked.fileBytes, // ← fixed
                    fileSizeMb: picked.fileSizeMb,
                  ),
                ),
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Upload & Index'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                context.read<UploadBloc>().add(const PickFileEvent()),
            child: const Text('Choose Different File'),
          ),
        ],
      );
    }

    if (state is UploadSuccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () =>
                context.read<UploadBloc>().add(const PickFileEvent()),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload Another Document'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      );
    }

    // Initial state
    return ElevatedButton.icon(
      onPressed: () => context.read<UploadBloc>().add(const PickFileEvent()),
      icon: const Icon(Icons.attach_file_rounded),
      label: const Text('Select File'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
