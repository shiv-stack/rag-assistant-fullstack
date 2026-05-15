import 'package:equatable/equatable.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class PickFileEvent extends UploadEvent {
  const PickFileEvent();
}

class UploadFileEvent extends UploadEvent {
  final String filePath;
  final String filename;
  final List<int> fileBytes;
  final double fileSizeMb;

  const UploadFileEvent({
    required this.filePath,
    required this.filename,
    required this.fileBytes,
    required this.fileSizeMb,
  });

  @override
  List<Object?> get props => [filename, fileSizeMb];
}

class ResetUploadEvent extends UploadEvent {
  const ResetUploadEvent();
}