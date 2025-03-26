import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryService {
  final String baseUrl = 'http://192.168.100.213:3000/api';

  Future<List<Category>> getAllCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      print('Category response status: ${response.statusCode}');
      print('Category response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        print('Failed to load categories: ${response.statusCode}');
        // Return empty list instead of throwing exception
        return [];
      }
    } catch (e) {
      print('Error fetching categories: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }
}