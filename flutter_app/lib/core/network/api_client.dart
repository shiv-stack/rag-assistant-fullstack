import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rag_knowledge_assistant/core/constants/api_constants.dart';

class ApiClient {
  ApiClient._() {
    _dio = _createDio();
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeoutMs,
        ),
        sendTimeout: const Duration(
          milliseconds: ApiConstants.sendTimeoutMs,
        ),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // ── Interceptors ──────────────────────────────────────────────
    dio.interceptors.addAll([
      _ErrorInterceptor(),
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);

    return dio;
  }
}

// ── Error Interceptor ─────────────────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _parseError(err);
    final enriched = err.copyWith(
      message: message,
    );
    handler.next(enriched);
  }

  String _parseError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Is the backend running?';
      case DioExceptionType.receiveTimeout:
        return 'Response timed out. The server took too long.';
      case DioExceptionType.sendTimeout:
        return 'Upload timed out. File may be too large.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to backend. Check if server is running on localhost:8000';
      case DioExceptionType.badResponse:
        return _parseBadResponse(err.response);
      default:
        return 'Unexpected network error occurred.';
    }
  }

  String _parseBadResponse(Response? response) {
    if (response == null) return 'No response from server.';

    final status = response.statusCode;
    final data = response.data;

    // FastAPI returns {"detail": "..."} for errors
    if (data is Map && data.containsKey('detail')) {
      return data['detail'].toString();
    }

    switch (status) {
      case 400:
        return 'Bad request. Check file type or input.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Check your input.';
      case 500:
        return 'Internal server error. Check backend logs.';
      default:
        return 'Server returned error $status.';
    }
  }
}