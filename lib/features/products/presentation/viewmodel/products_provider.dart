import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eshop_api_integration/features/products/data/product_repository.dart';
import 'package:eshop_api_integration/features/products/domain/models/product.dart';

/// Immutable snapshot of the paginated product list.
@immutable
class ProductsState {
  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
  });

  /// Products accumulated across all loaded pages.
  final List<Product> products;

  /// True while a page request is in flight.
  final bool isLoading;

  /// False once the last page has been reached.
  final bool hasMore;

  /// Next page index to request (zero-based).
  final int page;

  /// Set when the most recent page request failed.
  final Object? error;

  /// True before the first page has been requested.
  bool get isInitial => products.isEmpty && page == 0 && !isLoading;

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    int? page,
    Object? error,
    bool clearError = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives infinite-scroll pagination over [ProductRepository].
///
/// The UI calls [loadMore] on first build and again whenever the user scrolls
/// near the bottom; this notifier guards against duplicate/oversized requests.
class ProductsNotifier extends Notifier<ProductsState> {
  @override
  ProductsState build() => const ProductsState();

  /// Loads the next page and appends it. No-op while a request is already in
  /// flight or once every page has been loaded.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(productRepositoryProvider);
      final next = await repo.fetchPage(state.page);

      state = state.copyWith(
        products: [...state.products, ...next],
        page: state.page + 1,
        hasMore: next.length == ProductRepository.pageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Resets to the first page (used by pull-to-refresh). With server-side
  /// pagination there's no local cache to clear — re-requesting page 0 fetches
  /// fresh data from the API.
  Future<void> refresh() async {
    state = const ProductsState();
    await loadMore();
  }
}

final productsProvider =
    NotifierProvider<ProductsNotifier, ProductsState>(ProductsNotifier.new);
