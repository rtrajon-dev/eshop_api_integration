import 'package:dio/dio.dart';

/// Base exception for all API errors in the app.
///
/// Mirrors the typed-exception pattern from the reference project — Dio's
/// low-level [DioException] is mapped to one of these so the UI can reason
/// about failures without depending on `dio`.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 400 / 422 — bad request or validation error.
class BadRequestException extends ApiException {
  const BadRequestException(super.message, {super.statusCode = 400});
}

/// 404 — resource not found.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found'])
      : super(statusCode: 404);
}

/// 5xx — server-side failure.
class ServerException extends ApiException {
  const ServerException([super.message = 'Server error', int? code])
      : super(statusCode: code);
}

/// No internet, DNS failure, timeout.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network error']);
}

/// Request was cancelled (e.g. the user navigated away).
class CancelledException extends ApiException {
  const CancelledException() : super('Request cancelled');
}

/// The response was 200 but its shape/payload couldn't be parsed.
class ParseException extends ApiException {
  const ParseException([super.message = 'Unexpected response format']);
}

/// Maps a [DioException] to a typed [ApiException].
ApiException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException('Connection timed out');
    case DioExceptionType.cancel:
      return const CancelledException();
    case DioExceptionType.badResponse:
      return _mapStatusCode(e.response);
    case DioExceptionType.badCertificate:
      return const NetworkException('Certificate error');
    case DioExceptionType.unknown:
      return NetworkException(e.message ?? 'Unknown network error');
  }
}

ApiException _mapStatusCode(Response? response) {
  final status = response?.statusCode;
  final body = response?.data;
  final message = body is Map<String, dynamic>
      ? (body['message'] as String? ?? body['error'] as String? ?? 'Error')
      : 'HTTP $status';

  if (status == null) return ServerException(message);

  return switch (status) {
    400 || 422 => BadRequestException(message, statusCode: status),
    404 => NotFoundException(message),
    >= 500 => ServerException(message, status),
    _ => ServerException(message, status),
  };
}
