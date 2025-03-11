class CartItem {
  final int id;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;  // Remove nullable

  CartItem({
    required this.id,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,  // Make required
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      productName: json['product_name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['image_url'] ?? '',  // Provide empty string as default
    );
  }
}