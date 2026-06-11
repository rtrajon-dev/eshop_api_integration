import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eshop_api_integration/app/app.dart';

/// App entry sequence — mirrors the reference project's `bootstrap()`:
/// ensure bindings, then run the app inside a Riverpod scope.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
