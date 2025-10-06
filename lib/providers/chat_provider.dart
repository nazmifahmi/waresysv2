import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  // State variables
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isChatOpen = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isChatOpen => _isChatOpen;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  ChatService get chatService => _chatService;

  // Initialize chat provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🤖 Initializing ChatProvider...');
      
      // Test koneksi ke Gemini AI
      final bool isConnected = await _chatService.testConnection();
      
      if (!isConnected) {
        debugPrint('⚠️ Gemini AI connection failed, using fallback mode');
      }
      
      // Tambahkan pesan selamat datang
      _addWelcomeMessage();
      
      _isInitialized = true;
      debugPrint('✅ ChatProvider initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ ChatProvider initialization failed: $e');
      _error = 'Gagal menginisialisasi chat: $e';
      notifyListeners();
    }
  }

  // Tambahkan pesan selamat datang
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage.ai(
      content: 'Halo! Saya adalah AI Assistant untuk WareSys. 👋\n\nSaya dapat membantu Anda dengan:\n• Analisis data inventory\n• Insight keuangan\n• Analisis transaksi\n• Prediksi bisnis\n• Analisis gambar/dokumen\n\nAda yang bisa saya bantu hari ini?',
      type: MessageType.text,
    );
    
    _messages.add(welcomeMessage);
  }

  // Buka/tutup chat window
  void toggleChat() {
    _isChatOpen = !_isChatOpen;
    notifyListeners();
    
    // Initialize jika belum
    if (!_isInitialized && _isChatOpen) {
      initialize();
    }
  }

  void openChat() {
    if (!_isChatOpen) {
      _isChatOpen = true;
      notifyListeners();
      
      // Initialize jika belum
      if (!_isInitialized) {
        initialize();
      }
    }
  }

  void closeChat() {
    if (_isChatOpen) {
      _isChatOpen = false;
      notifyListeners();
    }
  }

  // Kirim pesan teks
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      // Clear error
      _error = null;
      
      // Tambahkan pesan user
      final userMessage = ChatMessage.user(
        content: message.trim(),
        type: MessageType.text,
      );
      _messages.add(userMessage);
      notifyListeners();
      
      // Tambahkan loading message
      final loadingMessage = ChatMessage.loading();
      _messages.add(loadingMessage);
      _isLoading = true;
      notifyListeners();
      
      // Kirim ke AI service
      final response = await _chatService.sendTextMessage(
        message.trim(),
        context: _messages.where((m) => !m.isLoading).toList(),
      );
      
      // Hapus loading message
      _messages.removeWhere((m) => m.id == loadingMessage.id);
      
      // Tambahkan respons AI
      final aiMessage = ChatMessage.ai(
        content: response,
        type: MessageType.text,
      );
      _messages.add(aiMessage);
      
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
      
      // Hapus loading message jika ada
      _messages.removeWhere((m) => m.isLoading);
      
      // Tambahkan error message
      final errorMessage = ChatMessage.error(e.toString());
      _messages.add(errorMessage);
      
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kirim pesan dengan gambar
  Future<void> sendImageMessage(String imagePath, {String? prompt}) async {
    try {
      // Clear error
      _error = null;
      
      // Tambahkan pesan user dengan gambar
      final userMessage = ChatMessage.user(
        content: prompt ?? 'Analisis gambar ini',
        type: MessageType.image,
        imagePath: imagePath,
      );
      _messages.add(userMessage);
      notifyListeners();
      
      // Tambahkan loading message
      final loadingMessage = ChatMessage.loading();
      _messages.add(loadingMessage);
      _isLoading = true;
      notifyListeners();
      
      // Kirim ke AI service
      final response = await _chatService.sendImageMessage(
        imagePath,
        prompt: prompt,
      );
      
      // Hapus loading message
      _messages.removeWhere((m) => m.id == loadingMessage.id);
      
      // Tambahkan respons AI
      final aiMessage = ChatMessage.ai(
        content: response,
        type: MessageType.text,
      );
      _messages.add(aiMessage);
      
    } catch (e) {
      debugPrint('❌ Error sending image message: $e');
      
      // Hapus loading message jika ada
      _messages.removeWhere((m) => m.isLoading);
      
      // Tambahkan error message
      final errorMessage = ChatMessage.error(e.toString());
      _messages.add(errorMessage);
      
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus pesan tertentu
  void removeMessage(String messageId) {
    _messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }

  // Clear semua pesan
  void clearMessages() {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  // Retry pesan yang error
  Future<void> retryMessage(ChatMessage message) async {
    if (message.sender != MessageSender.user) return;
    
    // Hapus pesan error setelah pesan user ini
    final messageIndex = _messages.indexOf(message);
    if (messageIndex != -1 && messageIndex < _messages.length - 1) {
      final nextMessage = _messages[messageIndex + 1];
      if (nextMessage.error != null) {
        _messages.removeAt(messageIndex + 1);
      }
    }
    
    // Kirim ulang pesan
    if (message.type == MessageType.text) {
      await sendTextMessage(message.content);
    } else if (message.type == MessageType.image && message.imagePath != null) {
      await sendImageMessage(message.imagePath!, prompt: message.content);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get message count
  int get messageCount => _messages.length;

  // Check if has unread messages (untuk notifikasi di bubble)
  bool get hasUnreadMessages {
    // Implementasi sederhana: jika chat tertutup dan ada pesan AI terbaru
    if (_isChatOpen || _messages.isEmpty) return false;
    
    final lastMessage = _messages.last;
    return lastMessage.sender == MessageSender.ai && 
           !lastMessage.isLoading && 
           lastMessage.error == null;
  }

  // Mark messages as read
  void markAsRead() {
    // Implementasi untuk menandai pesan sudah dibaca
    // Bisa diperluas untuk tracking read status
    notifyListeners();
  }

  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}