import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:eshop_api_integration/app/network/api_exceptions.dart';
import 'package:eshop_api_integration/app/network/api_result.dart';
import 'package:eshop_api_integration/features/products/domain/models/product.dart';

/// Talks to the DummyJSON products endpoint.
///
/// Mirrors the reference project's `*_api_service.dart` convention: a thin
/// wrapper over a [Dio] instance that returns a typed [ApiResult] and never
/// throws across the layer boundary.
///
/// DummyJSON supports server-side pagination via `?limit=&skip=` and returns:
/// ```json
/// { "products": [ { "id": 1, "title": "...", ... } ],
///   "total": 194, "skip": 0, "limit": 8 }
/// ```
class ProductApiService {
  const ProductApiService(this._dio);

  final Dio _dio;

  /// Path on the base URL (`https://dummyjson.com`).
  static const String _productsPath = '/products';

  /// Only request the fields the UI actually uses — keeps the payload small.
  static const String _selectFields = 'title,price,rating,thumbnail';

  /// Fetches one page: up to [limit] products starting at offset [skip].
  Future<ApiResult<List<Product>>> fetchPage({
    required int limit,
    required int skip,
  }) async {
    try {
      final response = await _dio.get(
        _productsPath,
        queryParameters: {
          'limit': '$limit',
          'skip': '$skip',
          'select': _selectFields,
        },
      );

      final body = response.data;
      // Dio decodes JSON when the server sends a JSON content-type; decode
      // defensively in case it arrives as a raw string.
      final Map<String, dynamic> map = switch (body) {
        Map<String, dynamic> m => m,
        String s => _decode(s),
        _ => throw const ParseException(),
      };

      final data = map['products'] as List<dynamic>? ?? const [];
      final products = data
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList();

      return Success(products);
    } on DioException catch (e) {
      return Failure(
        e.error is ApiException ? e.error! as ApiException : mapDioException(e),
      );
    } catch (e) {
      debugPrint('[Products] Parse error: $e');
      return const Failure(ParseException());
    }
  }

  Map<String, dynamic> _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ParseException();
  }
}
