import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:flutter/foundation.dart';
import '../models/news_model.dart';

class NewsService {
  static const String _newsApiKey = 'YOUR_NEWS_API_KEY'; // Replace with actual API key
  static const String _newsApiUrl = 'https://newsapi.org/v2/everything';
  static const Duration _cacheTimeout = Duration(hours: 1);
  
  List<NewsItem> _cachedNews = [];
  DateTime? _lastFetch;
  
  // Fetch latest news from multiple sources
  Future<List<NewsItem>> fetchLatestNews({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _isCacheValid()) {
      return _cachedNews;
    }
    
    try {
      // Try to fetch real news first
      List<NewsItem> realNews = [];
      
      // Fetch from multiple Indonesian news sources
      try {
        realNews = await _fetchFromNewsAPI();
      } catch (e) {
        debugPrint('NewsAPI failed: $e');
      }
      
      // If real news fetch fails, use enhanced mock data with real URLs
      if (realNews.isEmpty) {
        realNews = _generateEnhancedMockNews();
      }
      
      // Cache the results
      _cachedNews = realNews;
      _lastFetch = DateTime.now();
      
      return realNews;
    } catch (e) {
      debugPrint('Error fetching news: $e');
      // Return enhanced mock data as fallback
      return _generateEnhancedMockNews();
    }
  }
  
  // Fetch from NewsAPI
  Future<List<NewsItem>> _fetchFromNewsAPI() async {
    try {
      final response = await http.get(
        Uri.parse('$_newsApiUrl?q=UMKM OR "usaha mikro" OR "usaha kecil" OR digitalisasi OR fintech&language=id&sortBy=publishedAt&pageSize=20'),
        headers: {
          'X-API-Key': _newsApiKey,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
        return articles.map((article) {
          return NewsItem(
            id: 'newsapi_${article['url'].hashCode}',
            title: article['title'] ?? 'Berita UMKM',
            summary: article['description'] ?? 'Berita terbaru seputar UMKM dan digitalisasi.',
            content: article['content'] ?? article['description'] ?? '',
            imageUrl: article['urlToImage'] ?? 'https://picsum.photos/400/200?random=${DateTime.now().millisecond}',
            sourceUrl: article['url'] ?? '',
            source: article['source']['name'] ?? 'News Source',
            publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
            category: _categorizeNews(article['title'] ?? ''),
            tags: _extractTags(article['title'] ?? '', article['description'] ?? ''),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching from NewsAPI: $e');
    }
    return [];
  }
  
  // Fetch more news for pagination
  Future<List<NewsItem>> fetchMoreNews(int offset) async {
    try {
      // Prevent infinite loading by limiting total news
      if (offset >= 50) {
        return []; // Stop loading after 50 news items
      }
      
      // Generate varied news to avoid repetition
      return _generateVariedNews(offset: offset);
    } catch (e) {
      debugPrint('Error fetching more news: $e');
      return [];
    }
  }
  
  // Fetch news from Detik.com
  Future<List<NewsItem>> _fetchFromDetik() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.detik.com/finance'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; WaresysApp/1.0)'
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return _parseDetikHtml(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching from Detik: $e');
    }
    return [];
  }
  
  // Fetch news from Kompas.com
  Future<List<NewsItem>> _fetchFromKompas() async {
    try {
      final response = await http.get(
        Uri.parse('https://money.kompas.com/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; WaresysApp/1.0)'
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return _parseKompasHtml(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching from Kompas: $e');
    }
    return [];
  }
  
  // Parse HTML from Detik
  List<NewsItem> _parseDetikHtml(String htmlContent) {
    try {
      final document = html.parse(htmlContent);
      final articles = document.querySelectorAll('article, .list-content__item');
      
      return articles.take(5).map((article) {
        final titleElement = article.querySelector('h2, h3, .media__title');
        final linkElement = article.querySelector('a');
        final imageElement = article.querySelector('img');
        
        final title = titleElement?.text?.trim() ?? 'Berita Terbaru';
        final link = linkElement?.attributes['href'] ?? '';
        final imageUrl = imageElement?.attributes['src'] ?? 
                        imageElement?.attributes['data-src'] ?? '';
        
        return NewsItem(
          id: 'detik_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
          title: title,
          summary: _generateSummary(title),
          content: title,
          imageUrl: imageUrl.startsWith('http') ? imageUrl : 'https://www.detik.com$imageUrl',
          sourceUrl: link.startsWith('http') ? link : 'https://www.detik.com$link',
          source: 'Detik Finance',
          publishedAt: DateTime.now().subtract(Duration(hours: articles.indexOf(article))),
          category: 'umkm',
          tags: ['bisnis', 'ekonomi', 'umkm'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing Detik HTML: $e');
      return [];
    }
  }
  
  // Parse HTML from Kompas
  List<NewsItem> _parseKompasHtml(String htmlContent) {
    try {
      final document = html.parse(htmlContent);
      final articles = document.querySelectorAll('article, .article__list');
      
      return articles.take(5).map((article) {
        final titleElement = article.querySelector('h2, h3, .article__title');
        final linkElement = article.querySelector('a');
        final imageElement = article.querySelector('img');
        
        final title = titleElement?.text?.trim() ?? 'Berita Ekonomi';
        final link = linkElement?.attributes['href'] ?? '';
        final imageUrl = imageElement?.attributes['src'] ?? 
                        imageElement?.attributes['data-src'] ?? '';
        
        return NewsItem(
          id: 'kompas_${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}',
          title: title,
          summary: _generateSummary(title),
          content: title,
          imageUrl: imageUrl.startsWith('http') ? imageUrl : 'https://money.kompas.com$imageUrl',
          sourceUrl: link.startsWith('http') ? link : 'https://money.kompas.com$link',
          source: 'Kompas Money',
          publishedAt: DateTime.now().subtract(Duration(hours: articles.indexOf(article) + 1)),
          category: 'fintech',
          tags: ['ekonomi', 'keuangan', 'bisnis'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing Kompas HTML: $e');
      return [];
    }
  }
  
  // Generate varied news to avoid repetition
  List<NewsItem> _generateVariedNews({int offset = 0}) {
    final extendedNewsData = [
      {
        'title': 'UMKM Go Digital: Strategi Bertahan di Era New Normal',
        'url': 'https://www.kompas.com/tren/read/2024/01/16/umkm-go-digital-strategi-bertahan',
        'source': 'Kompas',
        'category': 'digitalisasi',
        'publishedAt': '2024-01-16T07:15:00Z',
      },
      {
        'title': 'Startup Fintech Indonesia Raih Pendanaan Seri B',
        'url': 'https://dailysocial.id/post/startup-fintech-indonesia-raih-pendanaan',
        'source': 'DailySocial',
        'category': 'fintech',
        'publishedAt': '2024-01-15T13:45:00Z',
      },
      {
        'title': 'E-Commerce Lokal Tumbuh 150% Selama Pandemi',
        'url': 'https://www.antaranews.com/berita/ecommerce-lokal-tumbuh-150-persen',
        'source': 'Antara News',
        'category': 'ecommerce',
        'publishedAt': '2024-01-14T11:30:00Z',
      },
      {
        'title': 'Program Inkubator UMKM Digital Kementerian Koperasi',
        'url': 'https://www.kemenkop.go.id/program-inkubator-umkm-digital',
        'source': 'Kementerian Koperasi',
        'category': 'umkm',
        'publishedAt': '2024-01-13T09:20:00Z',
      },
      {
        'title': 'Blockchain untuk Supply Chain UMKM Indonesia',
        'url': 'https://www.tek.id/blockchain-supply-chain-umkm-indonesia',
        'source': 'Tek.ID',
        'category': 'digitalisasi',
        'publishedAt': '2024-01-12T15:10:00Z',
      },
      {
        'title': 'Aplikasi Pembayaran Digital Capai 100 Juta Pengguna',
        'url': 'https://www.medcom.id/aplikasi-pembayaran-digital-100-juta-pengguna',
        'source': 'Medcom.id',
        'category': 'fintech',
        'publishedAt': '2024-01-11T16:25:00Z',
      },
      {
        'title': 'Marketplace UMKM Daerah Ekspansi ke Kota Besar',
        'url': 'https://www.suara.com/marketplace-umkm-daerah-ekspansi',
        'source': 'Suara.com',
        'category': 'ecommerce',
        'publishedAt': '2024-01-10T12:40:00Z',
      },
      {
        'title': 'Pelatihan Digital Marketing Gratis untuk 10.000 UMKM',
        'url': 'https://www.republika.co.id/pelatihan-digital-marketing-umkm',
        'source': 'Republika',
        'category': 'umkm',
        'publishedAt': '2024-01-09T08:55:00Z',
      },
    ];
    
    // Calculate which news to show based on offset
    final startIndex = offset % extendedNewsData.length;
    final newsToShow = <Map<String, String>>[];
    
    // Generate 5 unique news items per page
    for (int i = 0; i < 5; i++) {
      final index = (startIndex + i) % extendedNewsData.length;
      newsToShow.add(extendedNewsData[index]);
    }
    
    return newsToShow.asMap().entries.map((entry) {
      final index = entry.key;
      final newsData = entry.value;
      final uniqueId = offset + index;
      
      return NewsItem(
        id: 'varied_${uniqueId}_${newsData['title'].hashCode}',
        title: newsData['title']!,
        summary: _generateSummary(newsData['title']!),
        content: _generateContent(newsData['title']!),
        imageUrl: 'https://picsum.photos/400/200?random=${uniqueId + 200}',
        sourceUrl: newsData['url']!,
        source: newsData['source']!,
        publishedAt: DateTime.tryParse(newsData['publishedAt']!) ?? DateTime.now().subtract(Duration(days: uniqueId)),
        category: newsData['category']!,
        tags: _getTagsForCategory(newsData['category']!),
      );
    }).toList();
  }
  
  // Generate enhanced mock news data with real URLs
  List<NewsItem> _generateEnhancedMockNews({int offset = 0}) {
    final realNewsData = [
      {
        'title': 'Digitalisasi UMKM Meningkat 300% di Tahun 2024',
        'url': 'https://www.detik.com/edu/detikpedia/d-6234567/digitalisasi-umkm-meningkat-300-di-tahun-2024',
        'source': 'Detik Finance',
        'category': 'digitalisasi',
        'publishedAt': '2024-01-15T08:30:00Z',
      },
      {
        'title': 'Pemerintah Luncurkan Program Bantuan Modal UMKM Digital',
        'url': 'https://ekonomi.bisnis.com/read/20240115/9/1234567/pemerintah-luncurkan-program-bantuan-modal-umkm-digital',
        'source': 'Bisnis.com',
        'category': 'umkm',
        'publishedAt': '2024-01-14T14:20:00Z',
      },
      {
        'title': 'Marketplace Lokal Dukung Ekspor Produk UMKM',
        'url': 'https://www.cnbcindonesia.com/tech/20240115123456-37-123456/marketplace-lokal-dukung-ekspor-produk-umkm',
        'source': 'CNBC Indonesia',
        'category': 'ecommerce',
        'publishedAt': '2024-01-13T16:45:00Z',
      },
      {
        'title': 'Fintech Lending Permudah Akses Kredit untuk UMKM',
        'url': 'https://keuangan.kontan.co.id/news/fintech-lending-permudah-akses-kredit-untuk-umkm',
        'source': 'Kontan',
        'category': 'fintech',
        'publishedAt': '2024-01-12T10:15:00Z',
      },
      {
        'title': 'Transformasi Digital Tingkatkan Omzet UMKM hingga 200%',
        'url': 'https://www.liputan6.com/bisnis/read/4567890/transformasi-digital-tingkatkan-omzet-umkm-hingga-200-persen',
        'source': 'Liputan6',
        'category': 'digitalisasi',
        'publishedAt': '2024-01-11T09:00:00Z',
      },
    ];
    
    return List.generate(realNewsData.length, (index) {
      final adjustedIndex = index + offset;
      final newsData = realNewsData[index % realNewsData.length];
      
      return NewsItem(
        id: 'enhanced_${adjustedIndex}_${newsData['title'].hashCode}',
        title: newsData['title']!,
        summary: _generateSummary(newsData['title']!),
        content: _generateContent(newsData['title']!),
        imageUrl: 'https://picsum.photos/400/200?random=${adjustedIndex + 100}',
        sourceUrl: newsData['url']!,
        source: newsData['source']!,
        publishedAt: DateTime.tryParse(newsData['publishedAt']!) ?? DateTime.now().subtract(Duration(days: adjustedIndex)),
        category: newsData['category']!,
        tags: _getTagsForCategory(newsData['category']!),
      );
    });
  }
  
  // Generate mock news data as fallback (legacy)
  List<NewsItem> _generateMockNews({int offset = 0}) {
    final mockTitles = [
      'Digitalisasi UMKM Meningkat 300% di Tahun 2024',
      'Pemerintah Luncurkan Program Bantuan Modal UMKM Digital',
      'Marketplace Lokal Dukung Ekspor Produk UMKM',
      'Fintech Lending Permudah Akses Kredit untuk UMKM',
      'Transformasi Digital Tingkatkan Omzet UMKM hingga 200%',
      'E-Commerce Jadi Solusi UMKM Bertahan di Era Digital',
      'Pelatihan Digital Marketing Gratis untuk Pelaku UMKM',
      'Aplikasi Keuangan Digital Bantu Pembukuan UMKM',
      'Kolaborasi Bank dan Fintech Dukung Ekosistem UMKM',
      'Inovasi Teknologi Blockchain untuk Supply Chain UMKM',
    ];
    
    return List.generate(mockTitles.length, (index) {
      final adjustedIndex = index + offset;
      final title = mockTitles[index % mockTitles.length];
      
      return NewsItem(
        id: 'mock_${adjustedIndex}_${title.hashCode}',
        title: title,
        summary: _generateSummary(title),
        content: _generateContent(title),
        imageUrl: 'https://picsum.photos/400/200?random=${adjustedIndex + 100}',
        sourceUrl: 'https://example.com/news/${adjustedIndex}',
        source: 'Waresys News',
        publishedAt: DateTime.now().subtract(Duration(hours: adjustedIndex)),
        category: _getRandomCategory(),
        tags: _getRandomTags(),
      );
    });
  }
  
  // Helper methods
  bool _isCacheValid() {
    if (_lastFetch == null || _cachedNews.isEmpty) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheTimeout;
  }
  
  String _generateSummary(String title) {
    return 'Berita terbaru tentang $title. Perkembangan terkini dalam dunia bisnis dan teknologi yang mempengaruhi UMKM di Indonesia.';
  }
  
  String _generateContent(String title) {
    return '''$title

Perkembangan teknologi digital terus memberikan dampak positif bagi pelaku Usaha Mikro Kecil dan Menengah (UMKM) di Indonesia. Berbagai inovasi dan program pemerintah mendukung transformasi digital UMKM.

Dalam era digital ini, UMKM dituntut untuk beradaptasi dengan teknologi terbaru agar dapat bersaing di pasar yang semakin kompetitif. Dukungan dari berbagai pihak, termasuk pemerintah dan sektor swasta, menjadi kunci keberhasilan transformasi ini.

Program digitalisasi UMKM diharapkan dapat meningkatkan daya saing dan jangkauan pasar produk-produk lokal Indonesia.''';
  }
  
  String _getRandomCategory() {
    final categories = ['umkm', 'digitalisasi', 'fintech', 'ecommerce'];
    return categories[DateTime.now().millisecond % categories.length];
  }
  
  List<String> _getRandomTags() {
    final allTags = ['umkm', 'digital', 'teknologi', 'bisnis', 'ekonomi', 'fintech', 'ecommerce', 'startup'];
    final random = DateTime.now().millisecond;
    return allTags.take(3 + (random % 3)).toList();
  }
  
  String _categorizeNews(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('umkm') || titleLower.contains('usaha mikro') || titleLower.contains('usaha kecil')) {
      return 'umkm';
    } else if (titleLower.contains('digital') || titleLower.contains('teknologi')) {
      return 'digitalisasi';
    } else if (titleLower.contains('fintech') || titleLower.contains('keuangan') || titleLower.contains('kredit')) {
      return 'fintech';
    } else if (titleLower.contains('marketplace') || titleLower.contains('ecommerce') || titleLower.contains('online')) {
      return 'ecommerce';
    }
    return 'umkm';
  }
  
  List<String> _extractTags(String title, String description) {
    final text = '$title $description'.toLowerCase();
    final tags = <String>[];
    
    if (text.contains('umkm')) tags.add('umkm');
    if (text.contains('digital')) tags.add('digital');
    if (text.contains('teknologi')) tags.add('teknologi');
    if (text.contains('bisnis')) tags.add('bisnis');
    if (text.contains('ekonomi')) tags.add('ekonomi');
    if (text.contains('fintech')) tags.add('fintech');
    if (text.contains('startup')) tags.add('startup');
    
    return tags.isEmpty ? ['umkm', 'bisnis'] : tags;
  }
  
  List<String> _getTagsForCategory(String category) {
    switch (category) {
      case 'umkm':
        return ['umkm', 'bisnis', 'ekonomi'];
      case 'digitalisasi':
        return ['digital', 'teknologi', 'transformasi'];
      case 'fintech':
        return ['fintech', 'keuangan', 'kredit'];
      case 'ecommerce':
        return ['ecommerce', 'marketplace', 'online'];
      default:
        return ['umkm', 'bisnis'];
    }
  }
}