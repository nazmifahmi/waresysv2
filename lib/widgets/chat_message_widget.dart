import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/chat_message_model.dart';
import '../constants/theme.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  
  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ..._buildAIAvatar(),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: EdgeInsets.only(
                left: isUser ? 40 : 8,
                right: isUser ? 8 : 40,
              ),
              child: _buildMessageBubble(context, isDark, isUser),
            ),
          ),
          
          if (isUser) ..._buildUserAvatar(),
        ],
      ),
    );
  }

  List<Widget> _buildAIAvatar() {
    return [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    ];
  }

  List<Widget> _buildUserAvatar() {
    return [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.accentBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 16,
        ),
      ),
    ];
  }

  Widget _buildMessageBubble(BuildContext context, bool isDark, bool isUser) {
    Color bubbleColor;
    Color textColor;
    
    if (message.error != null) {
      bubbleColor = AppTheme.errorColor.withOpacity(0.1);
      textColor = AppTheme.errorColor;
    } else if (isUser) {
      bubbleColor = AppTheme.primaryGreen;
      textColor = Colors.white;
    } else {
      bubbleColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;
      textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    }
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: message.error != null
              ? Border.all(color: AppTheme.errorColor, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image jika ada
            if (message.type == MessageType.image && message.imagePath != null)
              _buildImageContent(),
            
            // Text content
            if (message.content.isNotEmpty)
              _buildTextContent(textColor),
            
            // Loading indicator
            if (message.isLoading)
              _buildLoadingIndicator(),
            
            // Error actions
            if (message.error != null && onRetry != null)
              _buildErrorActions(),
            
            // Timestamp
            const SizedBox(height: 4),
            _buildTimestamp(isDark, isUser),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(message.imagePath!),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Gambar tidak dapat dimuat'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextContent(Color textColor) {
    return SelectableText(
      message.content,
      style: AppTheme.bodyMedium.copyWith(
        color: textColor,
        height: 1.4,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI sedang mengetik...',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorActions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Gagal terkirim',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Coba Lagi',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(bool isDark, bool isUser) {
    final timeText = _formatTime(message.timestamp);
    
    return Text(
      timeText,
      style: AppTheme.bodySmall.copyWith(
        color: isUser
            ? Colors.white.withOpacity(0.7)
            : (isDark ? AppTheme.textTertiary : AppTheme.textTertiaryLight),
        fontSize: 11,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Salin Teks'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teks berhasil disalin'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (message.error != null && onRetry != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Coba Lagi'),
                onTap: () {
                  Navigator.pop(context);
                  onRetry?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}