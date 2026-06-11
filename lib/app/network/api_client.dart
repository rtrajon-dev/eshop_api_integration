import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';

/// Creates pre-configured [Dio] instances — trimmed-down version of the
/// reference project's `ApiClient`. Shares timeout/logging defaults and maps
/// every [DioException] to a typed [ApiException] via an interceptor.
///
/// Usage:
/// ```dart
/// final dio = ApiClient.create(baseUrl: 'https://api.pixora.one');
/// ```
abstract final class ApiClient {
  static Dio create({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 15),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    // Map low-level Dio errors to typed ApiException.
    dio.interceptors.add(_ErrorMappingInterceptor());

    // Logging in debug mode only.
    if (kDebugMode) {
      dio.interceptors.add(_DebugLogInterceptor());
    }

    return dio;
  }
}

/// Maps [DioException] to a typed [ApiException] at the interceptor level so
/// callers see a consistent `e.error` regardless of the failure mode.
class _ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = mapDioException(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }
}

/// Lightweight debug logger — prints method, URL, status and timing.
class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[API] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[API] ← ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[API] ✗ ${err.response?.statusCode ?? 'NETWORK'} '
      '${err.requestOptions.uri}',
    );
    handler.next(err);
  }
}
