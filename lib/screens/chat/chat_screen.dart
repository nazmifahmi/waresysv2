import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message_model.dart';
import '../../constants/theme.dart';
import '../../widgets/chat_message_widget.dart';
import '../../widgets/chat_input_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    // Animation untuk slide up
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animation
    _slideController.forward();
    
    // Initialize chat provider jika belum
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      if (!chatProvider.isInitialized) {
        chatProvider.initialize();
      }
      chatProvider.markAsRead();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _closeChat() {
    _slideController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: screenHeight * 0.85, // 85% dari tinggi layar
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.surfaceDark
              : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Divider
            Divider(
              height: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.borderDark
                  : AppTheme.borderLight,
            ),
            
            // Chat messages
            Expanded(
              child: _buildMessagesList(),
            ),
            
            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // AI Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.mainGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: AppTheme.heading4.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.textPrimary
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    String status = 'Online';
                    Color statusColor = AppTheme.successColor;
                    
                    if (chatProvider.isLoading) {
                      status = 'Mengetik...';
                      statusColor = AppTheme.accentBlue;
                    } else if (chatProvider.error != null) {
                      status = 'Offline';
                      statusColor = AppTheme.errorColor;
                    }
                    
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.textSecondary
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Clear chat button
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return IconButton(
                    onPressed: chatProvider.messages.length > 1
                        ? () => _showClearChatDialog(chatProvider)
                        : null,
                    icon: Icon(
                      Icons.delete_outline,
                      color: chatProvider.messages.length > 1
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.textSecondary
                              : AppTheme.textSecondaryLight)
                          : Colors.grey,
                    ),
                  );
                },
              ),
              
              // Close button
              IconButton(
                onPressed: _closeChat,
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.textSecondary
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        // Auto scroll ke bawah ketika ada pesan baru
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return ChatMessageWidget(
              message: message,
              onRetry: () => chatProvider.retryMessage(message),
            );
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.cardDark
            : AppTheme.cardLight,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.borderDark
                : AppTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: ChatInputWidget(
        onSendMessage: (text) {
          context.read<ChatProvider>().sendTextMessage(text);
        },
        onSendImage: (imagePath) {
          context.read<ChatProvider>().sendImageMessage(imagePath);
        },
      ),
    );
  }

  void _showClearChatDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat chat? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              chatProvider.clearMessages();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}