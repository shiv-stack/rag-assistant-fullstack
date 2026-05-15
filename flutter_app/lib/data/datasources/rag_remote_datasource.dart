import 'package:dio/dio.dart';
import 'package:rag_knowledge_assistant/core/constants/api_constants.dart';
import 'package:rag_knowledge_assistant/core/error/exceptions.dart';
import 'package:rag_knowledge_assistant/core/network/api_client.dart';
import 'package:rag_knowledge_assistant/data/models/chat_model.dart';
import 'package:rag_knowledge_assistant/data/models/document_model.dart';

abstract class RagRemoteDataSource {
  Future<IngestResponseModel> ingestDocument({
    required String filePath,
    required String filename,
    required List<int> fileBytes,
  });

  Future<QueryResponseModel> queryKnowledgeBase({
    required String question,
    String? documentFilter,
    int topK = ApiConstants.defaultTopK,
  });

  Future<DocumentListResponseModel> listDocuments();

  Future<void> deleteDocument(String filename);
}


class RagRemoteDataSourceImpl implements RagRemoteDataSource {
  final Dio _dio;

  RagRemoteDataSourceImpl({Dio? dio})
      : _dio = dio ?? ApiClient.instance.dio;

  // ── Ingest ────────────────────────────────────────────────────────
  @override
  Future<IngestResponseModel> ingestDocument({
    required String filePath,
    required String filename,
    required List<int> fileBytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
        ),
      });

      final response = await _dio.post(
        ApiConstants.ingest,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return IngestResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw IngestException(e.message ?? 'Ingest request failed.');
    } catch (e) {
      throw IngestException('Unexpected error during ingest: $e');
    }
  }

  // ── Query ─────────────────────────────────────────────────────────
  @override
  Future<QueryResponseModel> queryKnowledgeBase({
    required String question,
    String? documentFilter,
    int topK = ApiConstants.defaultTopK,
  }) async {
    try {
      final requestModel = QueryRequestModel(
        question: question,
        documentFilter: documentFilter,
        topK: topK,
      );

      final response = await _dio.post(
        ApiConstants.query,
        data: requestModel.toJson(),
        options: Options(
          contentType: 'application/json',
        ),
      );

      return QueryResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw QueryException(e.message ?? 'Query request failed.');
    } catch (e) {
      throw QueryException('Unexpected error during query: $e');
    }
  }

  // ── List documents ────────────────────────────────────────────────
  @override
  Future<DocumentListResponseModel> listDocuments() async {
    try {
      final response = await _dio.get(ApiConstants.documents);

      return DocumentListResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'Failed to fetch documents.');
    } catch (e) {
      throw NetworkException('Unexpected error fetching documents: $e');
    }
  }

  // ── Delete document ───────────────────────────────────────────────
  @override
  Future<void> deleteDocument(String filename) async {
    try {
      await _dio.delete('${ApiConstants.documents}/$filename');
    } on DioException catch (e) {
      throw NetworkException(e.message ?? 'Failed to delete document.');
    } catch (e) {
      throw NetworkException('Unexpected error deleting document: $e');
    }
  }
}