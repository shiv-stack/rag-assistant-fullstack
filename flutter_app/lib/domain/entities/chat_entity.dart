import 'package:equatable/equatable.dart';

class SourceEntity extends Equatable {
  final String document;
  final int? page;
  final String chunkId;

  const SourceEntity({
    required this.document,
    required this.chunkId,
    this.page,
  });

  @override
  List<Object?> get props => [document, page, chunkId];
}


class QueryResponseEntity extends Equatable {
  final String answer;
  final List<SourceEntity> sources;
  final int retrievedChunks;

  const QueryResponseEntity({
    required this.answer,
    required this.sources,
    required this.retrievedChunks,
  });

  @override
  List<Object?> get props => [answer, sources, retrievedChunks];
}