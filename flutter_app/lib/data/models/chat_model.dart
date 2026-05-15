import '../../domain/entities/chat_entity.dart';

class SourceModel {
  final String document;
  final int? page;
  final String chunkId;

  const SourceModel({
    required this.document,
    required this.chunkId,
    this.page,
  });

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      document: json['document'] as String,
      page: json['page'] as int?,
      chunkId: json['chunk_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'document': document,
        'page': page,
        'chunk_id': chunkId,
      };

  // Convert to domain entity
  SourceEntity toEntity() => SourceEntity(
        document: document,
        page: page,
        chunkId: chunkId,
      );
}


class QueryRequestModel {
  final String question;
  final String? documentFilter;
  final int topK;

  const QueryRequestModel({
    required this.question,
    this.documentFilter,
    this.topK = 5,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'document_filter': documentFilter,
        'top_k': topK,
      };
}


class QueryResponseModel {
  final String answer;
  final List<SourceModel> sources;
  final int retrievedChunks;

  const QueryResponseModel({
    required this.answer,
    required this.sources,
    required this.retrievedChunks,
  });

  factory QueryResponseModel.fromJson(Map<String, dynamic> json) {
    return QueryResponseModel(
      answer: json['answer'] as String,
      sources: (json['sources'] as List)
          .map((s) => SourceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      retrievedChunks: json['retrieved_chunks'] as int,
    );
  }

  // Convert to domain entity
  QueryResponseEntity toEntity() => QueryResponseEntity(
        answer: answer,
        sources: sources.map((s) => s.toEntity()).toList(),
        retrievedChunks: retrievedChunks,
      );
}