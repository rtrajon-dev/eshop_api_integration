import 'api_exceptions.dart';

/// A lightweight Result type for API calls — same pattern as the reference
/// project. Lets services return either data or a typed [ApiException]
/// without throwing across layers.
///
/// Usage:
/// ```dart
/// final result = await productApiService.fetchAll();
/// switch (result) {
///   case Success(:final data): // use data
///   case Failure(:final error): // show error.message
/// }
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  /// True when the call succeeded.
  bool get isSuccess => this is Success<T>;

  /// Returns the data or throws the underlying [ApiException].
  T get dataOrThrow => switch (this) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      };

  /// Returns the data or null.
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Maps the success value, preserving any failure.
  ApiResult<R> map<R>(R Function(T data) transform) => switch (this) {
        Success(:final data) => Success(transform(data)),
        Failure(:final error) => Failure(error),
      };
}

class Success<T> extends ApiResult<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends ApiResult<T> {
  const Failure(this.error);
  final ApiException error;
}
