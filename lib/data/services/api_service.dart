import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:watch_store/data/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

class ApiService {
  final String baseUrl =
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

      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId, 'quantity': quantity}),
      );

      // Consider both 200 and 201 as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Successfully added to cart: ${response.body}');
        return true;
      } else {
        print('Failed to add to cart: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
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

      final response = await http.put(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cart_id': itemId, 'quantity': quantity}),
      );

      print('Update request sent with body: ${jsonEncode({
            'cart_id': itemId,
            'quantity': quantity
          })}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating cart item: $e');
      return false;
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
