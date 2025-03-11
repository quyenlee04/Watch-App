import 'package:flutter/material.dart';
import 'package:watch_store/data/models/product.dart';
import 'package:watch_store/data/services/api_service.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  ProductDetailPage({required this.product});

  final ApiService apiService = ApiService();
  
  void addToCart(BuildContext context) async {
  print('Adding product with ID: ${product.id}');
  final success = await apiService.addToCart(product.id, 1);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success 
        ? '${product.name} added to cart successfully!' 
        : 'Failed to add to cart'),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: Duration(seconds: 2),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 16),
              Text(
                product.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, color: Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                product.description,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => addToCart(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}