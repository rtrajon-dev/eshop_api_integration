import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eshop_api_integration/app/network/api_client.dart';
import 'package:eshop_api_integration/features/products/data/services/product_api_service.dart';
import 'package:eshop_api_integration/features/products/domain/models/product.dart';

/// Serves products one page at a time, backed by real server-side pagination.
///
/// DummyJSON pages with `?limit=&skip=`, so each [fetchPage] call maps the
/// zero-based [page] to a `skip` offset and asks the API for just that slice.
/// No caching or client-side slicing — the network is the source of truth, so
/// pull-to-refresh simply re-requests page 0.
class ProductRepository {
  ProductRepository(this._service);

  final ProductApiService _service;

  /// Number of items requested per page.
  static const int pageSize = 8;

  /// Returns the products for [page] (zero-based). An empty list means there
  /// are no more pages. Throws an [ApiException] if the network call fails.
  Future<List<Product>> fetchPage(int page) async {
    final result = await _service.fetchPage(
      limit: pageSize,
      skip: page * pageSize,
    );
    // dataOrThrow surfaces the typed ApiException to the view-model, which
    // already handles errors and shows a retry affordance.
    return result.dataOrThrow;
  }
}

/// Base URL for the DummyJSON API.
const _dummyJsonBaseUrl = 'https://dummyjson.com';

/// Single shared [ProductApiService] backed by a configured Dio instance.
final productApiServiceProvider = Provider<ProductApiService>((ref) {
  final dio = ApiClient.create(baseUrl: _dummyJsonBaseUrl);
  return ProductApiService(dio);
});

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.read(productApiServiceProvider)),
);
