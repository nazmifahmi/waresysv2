class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final String sourceUrl;
  final String source;
  final DateTime publishedAt;
  final String category;
  final List<String> tags;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.sourceUrl,
    required this.source,
    required this.publishedAt,
    required this.category,
    required this.tags,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      sourceUrl: json['sourceUrl'] ?? '',
      source: json['source'] ?? '',
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now(),
      category: json['category'] ?? 'umkm',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'category': category,
      'tags': tags,
    };
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? sourceUrl,
    String? source,
    DateTime? publishedAt,
    String? category,
    List<String>? tags,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years} tahun yang lalu';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months} bulan yang lalu';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} minggu yang lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
  
  String get formattedPublishedDate {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final day = publishedAt.day;
    final month = months[publishedAt.month - 1];
    final year = publishedAt.year;
    final hour = publishedAt.hour.toString().padLeft(2, '0');
    final minute = publishedAt.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute WIB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class NewsCategory {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  
  NewsCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
  });

  static List<NewsCategory> get defaultCategories => [
    NewsCategory(
      id: 'umkm',
      name: 'UMKM',
      description: 'Berita seputar Usaha Mikro Kecil Menengah',
      iconUrl: '',
    ),
    NewsCategory(
      id: 'digitalisasi',
      name: 'Digitalisasi',
      description: 'Transformasi digital untuk bisnis',
      iconUrl: '',
    ),
    NewsCategory(
      id: 'fintech',
      name: 'Fintech',
      description: 'Teknologi finansial dan pembayaran',
      iconUrl: '',
    ),
    NewsCategory(
      id: 'ecommerce',
      name: 'E-Commerce',
      description: 'Perdagangan elektronik dan marketplace',
      iconUrl: '',
    ),
  ];
}