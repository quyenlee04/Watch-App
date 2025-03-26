import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner_item.dart';

class BannerService {
  final String baseUrl = 'http://192.168.100.213:3000/api';

  Future<List<BannerItem>> fetchBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/banners'));
      print('Banner response status: ${response.statusCode}');
      print('Banner response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final banners = data.map((json) => BannerItem.fromJson(json)).toList();
        print('Parsed banners: ${banners.length}');
        return banners;
      } else {
        // Return mock data for testing
        return [
          BannerItem(
            id: 1,
            imageUrl: '$baseUrl/uploads/banners/banner1.jpg',
            title: 'Test Banner 1',
            link: '/test1',
          ),
          BannerItem(
            id: 2,
            imageUrl: '$baseUrl/uploads/banners/banner2.jpg',
            title: 'Test Banner 2',
            link: '/test2',
          ),
        ];
      }
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }
}
