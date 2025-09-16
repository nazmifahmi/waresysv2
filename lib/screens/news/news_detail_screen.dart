import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/news_model.dart';
import '../../constants/theme.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem news;

  const NewsDetailScreen({super.key, required this.news});

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
          'Detail Berita',
          style: AppTheme.heading3.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: AppTheme.textPrimary,
            ),
            onPressed: () => _shareNews(context),
          ),
          IconButton(
            icon: Icon(
              Icons.open_in_browser,
              color: AppTheme.textPrimary,
            ),
            onPressed: () => _openInBrowser(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNewsImage(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNewsHeader(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildNewsContent(),
                  const SizedBox(height: AppTheme.spacingXL),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsImage() {
    return Container(
      height: 250,
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
                size: 48,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Gambar tidak tersedia',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          news.title,
          style: AppTheme.heading2.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  'Dipublikasikan: ${news.formattedPublishedDate}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan',
          style: AppTheme.heading4.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: AppTheme.cardDecoration,
          child: Text(
            news.summary,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Konten Lengkap',
          style: AppTheme.heading4.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          news.content,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            height: 1.6,
          ),
        ),
        if (news.tags.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Tags',
            style: AppTheme.heading4.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: news.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Text(
                '#$tag',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openInBrowser(context),
            style: AppTheme.primaryButtonStyle,
            icon: Icon(Icons.open_in_browser),
            label: Text('Baca Selengkapnya di Website'),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareNews(context),
                style: AppTheme.secondaryButtonStyle,
                icon: Icon(Icons.share),
                label: Text('Bagikan'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.secondaryButtonStyle,
                icon: Icon(Icons.arrow_back),
                label: Text('Kembali'),
              ),
            ),
          ],
        ),
      ],
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

  Future<void> _openInBrowser(BuildContext context) async {
    if (news.sourceUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(news.sourceUrl);
        
        // Try different launch modes for better compatibility
        bool launched = false;
        
        // First try with external application
        if (await canLaunchUrl(uri)) {
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
          } catch (e) {
            debugPrint('Failed to launch with externalApplication: $e');
          }
        }
        
        // If external app fails, try with platform default
        if (!launched) {
          try {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            launched = true;
          } catch (e) {
            debugPrint('Failed to launch with platformDefault: $e');
          }
        }
        
        // If still fails, try with in-app web view
        if (!launched) {
          try {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
            launched = true;
          } catch (e) {
            debugPrint('Failed to launch with inAppWebView: $e');
          }
        }
        
        // If all methods fail, show error message
        if (!launched) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tidak dapat membuka link: ${news.sourceUrl}'),
                backgroundColor: AppTheme.errorColor,
                action: SnackBarAction(
                  label: 'Salin Link',
                  textColor: AppTheme.textPrimary,
                  onPressed: () {
                    // Copy URL to clipboard
                    // Clipboard.setData(ClipboardData(text: news.sourceUrl));
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing URL: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('URL tidak valid: ${news.sourceUrl}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _shareNews(BuildContext context) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur berbagi akan segera tersedia'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }
}