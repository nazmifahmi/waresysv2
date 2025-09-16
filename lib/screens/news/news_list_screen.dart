import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/news_model.dart';
import '../../providers/news_provider.dart';
import '../../constants/theme.dart';
import 'news_detail_screen.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more news when reaching bottom
      context.read<NewsProvider>().loadMoreNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Berita UMKM',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppTheme.textPrimary,
            ),
            onPressed: () => context.read<NewsProvider>().refreshNews(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: _buildNewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari berita...',
          hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textTertiary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppTheme.textTertiary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide(color: AppTheme.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide(color: AppTheme.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide(color: AppTheme.accentBlue),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: newsProvider.categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(
                  'Semua',
                  'all',
                  newsProvider.selectedCategory == 'all',
                  newsProvider,
                );
              }
              final category = newsProvider.categories[index - 1];
              return _buildCategoryChip(
                category.name,
                category.id,
                newsProvider.selectedCategory == category.id,
                newsProvider,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    String categoryId,
    bool isSelected,
    NewsProvider newsProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingS),
      child: FilterChip(
        label: Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          newsProvider.setCategory(categoryId);
        },
        backgroundColor: AppTheme.surfaceDark,
        selectedColor: AppTheme.accentBlue,
        checkmarkColor: AppTheme.textPrimary,
        side: BorderSide(
          color: isSelected ? AppTheme.accentBlue : AppTheme.borderDark,
        ),
      ),
    );
  }

  Widget _buildNewsList() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        if (newsProvider.isLoading && newsProvider.news.isEmpty) {
          return _buildLoadingState();
        }

        if (newsProvider.error != null && newsProvider.news.isEmpty) {
          return _buildErrorState(newsProvider);
        }

        List<NewsItem> displayNews;
        if (_searchQuery.isNotEmpty) {
          displayNews = newsProvider.searchNews(_searchQuery);
        } else {
          displayNews = newsProvider.filteredNews;
        }

        if (displayNews.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => newsProvider.refreshNews(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppTheme.spacingL),
            itemCount: displayNews.length + (newsProvider.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayNews.length) {
                return _buildLoadingIndicator();
              }
              return _buildNewsListItem(displayNews[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNewsListItem(NewsItem news) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        color: AppTheme.cardDark,
        child: InkWell(
          onTap: () => _navigateToDetail(news),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNewsItemImage(news),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNewsItemHeader(news),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildNewsItemTitle(news),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildNewsItemSummary(news),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildNewsItemFooter(news),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsItemImage(NewsItem news) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusM)),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: news.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppTheme.surfaceDark,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppTheme.surfaceDark,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: AppTheme.textTertiary,
                  size: 32,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Gambar tidak tersedia',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsItemHeader(NewsItem news) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: _getCategoryColor(news.category),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Text(
            news.category.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Text(
            news.source,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsItemTitle(NewsItem news) {
    return Text(
      news.title,
      style: AppTheme.heading4.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNewsItemSummary(NewsItem news) {
    return Text(
      news.summary,
      style: AppTheme.bodyMedium.copyWith(
        color: AppTheme.textSecondary,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNewsItemFooter(NewsItem news) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: AppTheme.textTertiary,
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          news.timeAgo,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textTertiary,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Memuat berita...',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
        ),
      ),
    );
  }

  Widget _buildErrorState(NewsProvider newsProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Gagal memuat berita',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              newsProvider.error ?? 'Terjadi kesalahan',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton(
              onPressed: () {
                newsProvider.clearError();
                newsProvider.loadNews();
              },
              style: AppTheme.primaryButtonStyle,
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              _searchQuery.isNotEmpty ? 'Tidak ada hasil' : 'Belum ada berita',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain'
                  : 'Berita akan muncul di sini',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'umkm':
        return AppTheme.accentGreen;
      case 'digitalisasi':
        return AppTheme.accentBlue;
      case 'fintech':
        return AppTheme.accentPurple;
      case 'ecommerce':
        return AppTheme.accentOrange;
      default:
        return AppTheme.textTertiary;
    }
  }

  void _navigateToDetail(NewsItem news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    );
  }
}