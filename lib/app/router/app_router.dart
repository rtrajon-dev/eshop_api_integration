import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eshop_api_integration/app/router/app_routes.dart';
import 'package:eshop_api_integration/features/products/presentation/view/product_list_page.dart';

/// Application router (go_router), following the reference project's
/// `AppRouter.router` pattern.
class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.products,
    routes: [
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductListPage(),
      ),
    ],
  );
}
