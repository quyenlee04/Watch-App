import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:watch_store/data/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class ApiService {
  static const String baseUrl =
      'http://192.168.100.213:3000/api'; // Update with your server URL

  Future<bool> register(String name, String email, String password,
      {String? phone, String? address}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
      }),
    );

    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // Store the token in SharedPreferences
      final data = jsonDecode(response.body);
      String token = data['token']; // Adjust based on your API response
      await _storeToken(token);
      return data;
    }
    return null;
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      print('API Response: ${response.body}'); // Add this debug line
      final List<dynamic> productList = jsonDecode(response.body);
      return productList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<bool> addToCart(int productId, int quantity) async {
    try {
      String? token = await _retrieveToken();
      if (token == null) return false;

      // First check product stock
      final productResponse = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (productResponse.statusCode != 200) {
        print('Failed to get product details');
        return false;
      }

      final product = json.decode(productResponse.body);
      final availableStock = product['stock'] ?? 0;

      if (quantity > availableStock) {
        throw Exception('out_of_stock');
      }

      // Add to cart
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e.toString().contains('out_of_stock')) {
        throw Exception('out_of_stock');
      }
      print('Error during add to cart: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCartItems() async {
    String? token = await _retrieveToken();

    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<bool> updateCartItemQuantity(int itemId, int quantity) async {
    try {
      String? token = await _retrieveToken();
      if (token == null) return false;

      // First check the cart item and product stock
      final cartResponse = await http.get(
        Uri.parse('$baseUrl/cart/$itemId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (cartResponse.statusCode != 200) {
        print('Failed to get cart item details: ${cartResponse.statusCode}');
        print('Response body: ${cartResponse.body}');
        return false;
      }

      final cartItem = json.decode(cartResponse.body);
      final productId = cartItem['product_id'];

      // Get product stock information
      final productResponse = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (productResponse.statusCode != 200) {
        print('Failed to get product details');
        return false;
      }

      final product = json.decode(productResponse.body);
      final availableStock = product['stock'] ?? 0;

      // Check if requested quantity is available
      if (quantity > availableStock) {
        print('Requested quantity exceeds available stock');
        return false;
      }

      // Update cart quantity
      final cartUpdateResponse = await http.put(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'cart_id': itemId, 'quantity': quantity, 'product_id': productId}),
      );

      print('Cart update response: ${cartUpdateResponse.statusCode}');
      print('Cart update body: ${cartUpdateResponse.body}');

      return cartUpdateResponse.statusCode == 200;
    } catch (e) {
      print('Error updating cart item: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      String? token = await _retrieveToken();
      if (token == null) {
        return {'success': false, 'error': 'No authentication token found'};
      }

      final cartItems = await fetchCartItems();
      if (cartItems.isEmpty) {
        return {'success': false, 'error': 'Cart is empty'};
      }

      // Calculate total here on client side as well
      double totalAmount = cartItems.fold(0, (sum, item) {
        return sum +
            (double.parse(item['price'].toString()) *
                int.parse(item['quantity'].toString()));
      });

      // Prepare order payload with total and all necessary item details
      final payload = {
        'shipping_address': orderData['shipping_address'],
        'total_amount': totalAmount,
        'items': cartItems
            .map((item) => {
                  'product_id': int.parse(item['product_id'].toString()),
                  'quantity': int.parse(item['quantity'].toString()),
                  'price': double.parse(item['price'].toString()),
                })
            .toList(),
      };

      print('Creating order with payload: ${json.encode(payload)}');

      final orderResponse = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('Order creation response: ${orderResponse.statusCode}');
      print('Response body: ${orderResponse.body}');

      if (orderResponse.statusCode == 201) {
        await clearCart();
        return {'success': true};
      }

      final errorBody = json.decode(orderResponse.body);
      return {
        'success': false,
        'error': errorBody['error'] ?? 'Failed to create order'
      };
    } catch (e) {
      print('Error creating order: $e');
      return {'success': false, 'error': 'An unexpected error occurred'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrderHistory() async {
    try {
      String? token = await _retrieveToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> orders = json.decode(response.body);
        // Format the shipping_address if it's stored as a JSON string
        return orders.map((order) {
          var formatted = Map<String, dynamic>.from(order);
          if (order['shipping_address'] is String) {
            try {
              formatted['shipping_address'] =
                  json.decode(order['shipping_address']);
            } catch (e) {
              print('Error parsing shipping address: $e');
            }
          }
          return formatted;
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching order history: $e');
      return [];
    }
  }

  Future<bool> removeFromCart(int itemId) async {
    try {
      String? token = await _retrieveToken();
      if (token == null) {
        print('No authentication token found');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cart_id': itemId}), // Send cart_id in request body
      );

      // Debug logging
      print('Delete request sent to: ${Uri.parse('$baseUrl/cart')}');
      print('Request body: ${jsonEncode({'cart_id': itemId})}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Successfully removed item from cart');
        return true;
      } else {
        print('Failed to remove item: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error removing item from cart: $e');
      return false;
    }
  }

  Future<bool> clearCart() async {
    String? token = await _retrieveToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> updateUserProfile(
    String name,
    String email, {
    String? phone,
    String? address,
    File? imageFile,
  }) async {
    try {
      String? token = await _retrieveToken();
      if (token == null) throw Exception('No authentication token found');

      // Create multipart request
      var uri = Uri.parse('$baseUrl/users/profile');
      var request = http.MultipartRequest('PUT', uri);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (phone != null && phone.isNotEmpty) request.fields['phone'] = phone;
      if (address != null && address.isNotEmpty)
        request.fields['address'] = address;

      // Add image file if provided
      if (imageFile != null) {
        var fileStream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'profile_picture', // This should match your backend field name
          fileStream,
          length,
          filename: 'profile_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );

        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Profile update status code: ${response.statusCode}');
      print('Profile update response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['profile_picture'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profile_picture', data['profile_picture']);
          }
          return true;
        } catch (e) {
          print('Error parsing response: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error in updateUserProfile: $e');
      return false;
    }
  }

  Future<String?> getProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_picture');
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    String? token = await _retrieveToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<bool> checkout(Map<String, dynamic> orderData) async {
    String? token = await _retrieveToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(orderData),
    );

    return response.statusCode == 201;
  }

  // Store the token in SharedPreferences
  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Retrieve the token from SharedPreferences
  Future<String?> _retrieveToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  
}
