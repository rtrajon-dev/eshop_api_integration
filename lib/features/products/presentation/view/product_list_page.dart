import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:eshop_api_integration/features/products/presentation/viewmodel/products_provider.dart';
import 'package:eshop_api_integration/features/products/presentation/widgets/product_card.dart';

/// Lists the catalogue with infinite scroll — more products load as the user
/// scrolls toward the bottom.
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _scrollController = ScrollController();

  /// Distance from the bottom (in px) at which the next page is prefetched.
  static const _loadMoreThreshold = 300.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Trigger the first page after the initial frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('eShop API Integration')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ProductsState state) {
    // First load — nothing to show yet.
    if (state.products.isEmpty) {
      if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.error != null) {
        return _ErrorView(
          message: 'Failed to load products.',
          onRetry: () => ref.read(productsProvider.notifier).loadMore(),
        );
      }
      return const Center(child: Text('No products available.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        // +1 for the footer (loader / end-of-list / retry).
        itemCount: state.products.length + 1,
        itemBuilder: (context, index) {
          if (index < state.products.length) {
            return ProductCard(product: state.products[index]);
          }
          return _Footer(
            state: state,
            onRetry: () => ref.read(productsProvider.notifier).loadMore(),
          );
        },
      ),
    );
  }
}

/// Bottom-of-list status indicator: spinner while loading the next page,
/// a retry prompt on error, or an end-of-list note when fully loaded.
class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final ProductsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Couldn\'t load more — tap to retry'),
          ),
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            'You\'ve reached the end',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(height: 16.h);
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          SizedBox(height: 12.h),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
