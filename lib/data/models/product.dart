class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? category; // Make nullable
  final int? categoryId;  // Make nullable and ensure it's an int
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.category,
    this.categoryId,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      category: json['category_name'],  // This can be null
      categoryId: json['category_id'],  // This can be null
      stock: json['stock'] ?? 0,
    );
  }
}