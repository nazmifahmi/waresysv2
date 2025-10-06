import 'package:flutter/foundation.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService _newsService = NewsService();
  
  List<NewsItem> _news = [];
  List<NewsItem> _featuredNews = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String _selectedCategory = 'all';
  
  // Getters
  List<NewsItem> get news => _news;
  List<NewsItem> get featuredNews => _featuredNews;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  
  List<NewsItem> get filteredNews {
    if (_selectedCategory == 'all') {
      return _news;
    }
    return _news.where((news) => news.category == _selectedCategory).toList();
  }
  
  List<NewsCategory> get categories => NewsCategory.defaultCategories;
  
  // Initialize news data
  Future<void> initialize() async {
    await loadNews();
  }
  
  // Load news from service
  Future<void> loadNews() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newsData = await _newsService.fetchLatestNews();
      _news = newsData;
      
      // Set featured news (first 5 items)
      _featuredNews = _news.take(5).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Gagal memuat berita: ${e.toString()}';
      _isLoading = false;
      debugPrint('Error loading news: $e');
      notifyListeners();
    }
  }
  
  // Refresh news
  Future<void> refreshNews() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    _error = null;
    notifyListeners();
    
    try {
      final newsData = await _newsService.fetchLatestNews(forceRefresh: true);
      _news = newsData;
      _featuredNews = _news.take(5).toList();
      
      _isRefreshing = false;
      notifyListeners();
    } catch (e) {
      _error = 'Gagal memperbarui berita: ${e.toString()}';
      _isRefreshing = false;
      debugPrint('Error refreshing news: $e');
      notifyListeners();
    }
  }
  
  // Load more news (pagination)
  Future<void> loadMoreNews() async {
    if (_isLoading) return;
    
    try {
      final moreNews = await _newsService.fetchMoreNews(_news.length);
      
      // Filter out duplicates based on news ID
      final existingIds = _news.map((news) => news.id).toSet();
      final uniqueNews = moreNews.where((news) => !existingIds.contains(news.id)).toList();
      
      if (uniqueNews.isNotEmpty) {
        _news.addAll(uniqueNews);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading more news: $e');
    }
  }
  
  // Filter by category
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }
  
  // Search news
  List<NewsItem> searchNews(String query) {
    if (query.isEmpty) return filteredNews;
    
    return filteredNews.where((news) {
      return news.title.toLowerCase().contains(query.toLowerCase()) ||
             news.summary.toLowerCase().contains(query.toLowerCase()) ||
             news.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }
  
  // Get news by ID
  NewsItem? getNewsById(String id) {
    try {
      return _news.firstWhere((news) => news.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Mark news as read (for analytics)
  void markAsRead(String newsId) {
    // Could implement read tracking here
    debugPrint('News marked as read: $newsId');
  }
  
  // Share news
  void shareNews(NewsItem news) {
    // Could implement sharing analytics here
    debugPrint('News shared: ${news.title}');
  }
  
  // Private methods - removed to reduce unnecessary notifyListeners calls
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
}