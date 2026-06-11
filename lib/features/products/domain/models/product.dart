/// A product sold in the eShop.
///
/// Instances are built from the live DummyJSON API (`dummyjson.com/products`)
/// via [Product.fromJson] and never mutated. [imageUrl] is a remote network
/// URL (loaded with `cached_network_image`), not a bundled asset.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.rating,
  });

  /// Stable unique identifier (the API's numeric `id`).
  final int id;

  /// Display name (e.g. "iPhone 17 Pro").
  final String name;

  /// Price in USD.
  final double price;

  /// Remote image URL — rendered with `CachedNetworkImage`.
  final String imageUrl;

  /// Average customer rating, 0.0–5.0.
  final double rating;

  /// Price formatted for display (e.g. "$1199.00").
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Builds a [Product] from one item in the API's `products` array.
  ///
  /// DummyJSON names the fields `title` and `thumbnail`. Numeric fields are
  /// decoded defensively — the API may send them as `int` or `num`, so
  /// [num.toDouble] is used rather than a hard cast.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['title'] as String? ?? 'Unknown',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      imageUrl: json['thumbnail'] as String? ?? '',
    );
  }
}
