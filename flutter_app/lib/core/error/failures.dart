import 'package:equatable/equatable.dart';

/// Base failure class.
/// All failures extend this — BLoC states carry Failure, not raw exceptions.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// ── Network Failures ──────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// ── Ingest Failures ───────────────────────────────────────────────────

class FilePickFailure extends Failure {
  const FilePickFailure(super.message);
}

class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure(super.message);
}

class UnsupportedFileFailure extends Failure {
  const UnsupportedFileFailure(super.message);
}

class IngestFailure extends Failure {
  const IngestFailure(super.message);
}

// ── Query Failures ────────────────────────────────────────────────────

class EmptyQuestionFailure extends Failure {
  const EmptyQuestionFailure(super.message);
}

class QueryFailure extends Failure {
  const QueryFailure(super.message);
}

class EmptyIndexFailure extends Failure {
  const EmptyIndexFailure(super.message);
}

// ── Document Failures ─────────────────────────────────────────────────

class DocumentListFailure extends Failure {
  const DocumentListFailure(super.message);
}

class DocumentDeleteFailure extends Failure {
  const DocumentDeleteFailure(super.message);
}