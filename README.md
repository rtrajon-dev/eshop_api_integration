# eShop API Integration

A small Flutter shopping-catalogue app that fetches a paginated product list
from a live REST API and renders it with infinite scroll and pull-to-refresh.

It is the API-backed version of the `eshop` demo: where `eshop` shipped
hard-coded dummy data, this project pulls real data over the network using
**Dio** and exposes it through **Riverpod**. The architecture mirrors a
production app's feature-first layout (data → domain → presentation).

## Data source

Products come from the free **[DummyJSON](https://dummyjson.com/)** API:

```
GET https://dummyjson.com/products?limit=8&skip=0&select=title,price,rating,thumbnail
```

- **194 products**, served with real server-side pagination (`limit` / `skip`).
- `select` trims the payload to only the fields the UI uses.
- Response shape:

  ```json
  {
    "products": [
      { "id": 1, "title": "Essence Mascara Lash Princess", "price": 9.99, "rating": 2.56, "thumbnail": "https://..." }
    ],
    "total": 194, "skip": 0, "limit": 8
  }
  ```

The base URL lives in
[`lib/features/products/data/product_repository.dart`](lib/features/products/data/product_repository.dart) —
swap `_dummyJsonBaseUrl` (and the field mapping in `Product.fromJson`) to point
at a different API.

## Features

- 🛍️ Live product list fetched from a REST API
- ♾️ Infinite scroll — the next page is requested as you near the bottom
- 🔄 Pull-to-refresh
- 🖼️ Cached network images with loading and error placeholders
- ⚠️ Typed error handling with inline retry
- 📱 Responsive sizing via `flutter_screenutil`, light/dark themes

## Tech stack

| Concern        | Package               |
| -------------- | --------------------- |
| State mgmt     | `flutter_riverpod`    |
| Networking     | `dio`                 |
| Routing        | `go_router`           |
| Images         | `cached_network_image`|
| Responsive UI  | `flutter_screenutil`  |
| Fonts          | `google_fonts`        |

## Architecture

Feature-first, layered. The view never knows where data comes from — the
networking detail is hidden behind the repository, so the API could be swapped
(or mocked) without touching the UI or the view-model.

```
lib/
├── main.dart                     # entry point → bootstrap()
├── bootstrap.dart                # ensures bindings, wraps app in ProviderScope
├── app/
│   ├── app.dart                  # MaterialApp.router + ScreenUtilInit + theme
│   ├── router/                   # go_router config + route constants
│   ├── theme/                    # light / dark themes
│   └── network/                  # reusable networking layer
│       ├── api_client.dart       # Dio factory: timeouts, logging, error interceptor
│       ├── api_result.dart       # sealed ApiResult<T> = Success | Failure
│       └── api_exceptions.dart   # typed ApiException hierarchy + mapDioException
└── features/
    └── products/
        ├── data/
        │   ├── product_repository.dart          # page → API call, exposes providers
        │   └── services/product_api_service.dart # Dio call to DummyJSON
        ├── domain/
        │   └── models/product.dart              # Product model + fromJson
        └── presentation/
            ├── viewmodel/products_provider.dart # ProductsNotifier (pagination state)
            ├── view/product_list_page.dart      # list + scroll + refresh
            └── widgets/product_card.dart         # single product row
```

### Data flow

```
ProductListPage  ──watch/read──▶  productsProvider (ProductsNotifier)
                                        │ loadMore() / refresh()
                                        ▼
                                 ProductRepository.fetchPage(page)
                                        │ limit / skip
                                        ▼
                                 ProductApiService (Dio)  ──HTTP──▶  dummyjson.com
```

- **`ProductApiService`** makes the HTTP call and returns an
  `ApiResult<List<Product>>` (`Success` or typed `Failure`) — it never throws
  across the layer boundary.
- **`ProductRepository`** maps a zero-based page to a `skip` offset and unwraps
  the result.
- **`ProductsNotifier`** holds the accumulated list and pagination flags
  (`isLoading`, `hasMore`, `page`, `error`); `hasMore` flips to `false` once a
  page returns fewer than `pageSize` items.
- **`ProductListPage`** triggers `loadMore()` on first frame and on scroll, and
  shows a footer spinner / retry / end-of-list message.

## Getting started

Requirements: Flutter `3.41.7+` / Dart SDK `^3.11.4`, and an internet
connection (the app fetches from a remote API).

```bash
flutter pub get
flutter run
```

To build a release binary:

```bash
flutter build apk        # Android
flutter build ios        # iOS (requires Xcode signing)
```

> The Android `INTERNET` permission is declared in the main manifest, so
> release builds can reach the network.

## Configuration

| What to change            | Where                                                                 |
| ------------------------- | --------------------------------------------------------------------- |
| API base URL              | `_dummyJsonBaseUrl` in `product_repository.dart`                      |
| Endpoint / query params   | `ProductApiService.fetchPage` in `product_api_service.dart`           |
| Items per page            | `ProductRepository.pageSize`                                          |
| JSON → model mapping      | `Product.fromJson` in `domain/models/product.dart`                    |
| Request timeouts          | `ApiClient.create` in `app/network/api_client.dart`                   |
