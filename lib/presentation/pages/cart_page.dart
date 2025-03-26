import 'package:flutter/material.dart';
import 'package:watch_store/data/services/api_service.dart';
import 'package:watch_store/data/models/cart_item.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ApiService apiService = ApiService();
  late Future<List<CartItem>> futureCartItems;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  void _refreshCart() {
    setState(() {
      futureCartItems = _fetchCartItems();
    });
  }

  Future<List<CartItem>> _fetchCartItems() async {
    final items = await apiService.fetchCartItems();
    return items.map((item) => CartItem.fromJson(item)).toList();
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(itemId);
    } else {
      try {
        final success = await apiService.updateCartItemQuantity(itemId, newQuantity);
        if (success) {
          _refreshCart();
        }
      } catch (e) {
        String errorMessage = 'Failed to update quantity';
        if (e.toString().contains('out_of_stock')) {
          errorMessage = 'Sản phẩm này đã hết hàng';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int itemId) async {
    final success = await apiService.removeFromCart(itemId);
    if (success) {
      _refreshCart();
    }
  }

  Future<void> _clearCart() async {
    final success = await apiService.clearCart();
    if (success) {
      _refreshCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping Cart'),
      ),
      body: FutureBuilder<List<CartItem>>(
        future: futureCartItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty'),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/products'),
                    child: Text('Continue Shopping'),
                  ),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // In CartPage widget where you display the cart item image
                            // ...existing code...
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Builder(builder: (context) {
                                  String fullImageUrl = item.imageUrl
                                          .startsWith('http')
                                      ? item.imageUrl
                                      : 'http://192.168.100.213:3000${item.imageUrl}';

                                  return Image.network(
                                    fullImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.watch,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () => _updateQuantity(
                                      item.id, item.quantity - 1),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed: () => _updateQuantity(
                                      item.id, item.quantity + 1),
                                ),
                              ],
                            ),
                            IconButton(
                              icon:
                                  Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${calculateTotal(cartItems).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: cartItems.isEmpty
                            ? null
                            : () => Navigator.pushNamed(context, '/checkout'),
                        child: Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double calculateTotal(List<CartItem> cartItems) {
    return cartItems.fold(
        0.0, (total, item) => total + (item.price * item.quantity));
  }
}
