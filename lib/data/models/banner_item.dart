class BannerItem {
  final int id;
  final String imageUrl;
  final String? link;
  final String? title;

  BannerItem({
    required this.id,
    required this.imageUrl,
    this.link,
    this.title,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['imageUrl'] ?? '';
    // Handle both full URLs and relative paths
    if (!imageUrl.startsWith('http')) {
      imageUrl = 'http://192.168.100.213:3000/uploads/banners/$imageUrl';
    }

    return BannerItem(
      id: json['id'] ?? 0,
      imageUrl: imageUrl,
      link: json['link'],
      title: json['title'],
    );
  }
}
