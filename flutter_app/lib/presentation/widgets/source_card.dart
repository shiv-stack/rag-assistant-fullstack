import 'package:flutter/material.dart';
import 'package:rag_knowledge_assistant/domain/entities/chat_entity.dart';

class SourceCard extends StatelessWidget {
  final SourceEntity source;

  const SourceCard({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'chunk: ${source.chunkId}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _fileIcon(source.document),
              size: 13,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _shortName(source.document),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (source.page != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'p.${source.page}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
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

  String _shortName(String filename) {
    // Trim long filenames: "my_very_long_document.pdf" → "my_very_lon....pdf"
    const maxLen = 20;
    if (filename.length <= maxLen) return filename;
    final ext = filename.split('.').last;
    final name = filename.substring(0, filename.lastIndexOf('.'));
    final trimmed = name.substring(0, maxLen - ext.length - 4);
    return '$trimmed...$ext';
  }
}