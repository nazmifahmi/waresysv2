import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';

class ChatService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // Ganti dengan API key yang sebenarnya
  
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Headers untuk API request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-goog-api-key': _apiKey,
  };

  /// Mengirim pesan teks ke Gemini AI
  Future<String> sendTextMessage(String message, {List<ChatMessage>? context}) async {
    try {
      debugPrint('🤖 Sending text message to Gemini AI: $message');
      
      // Buat context dari chat history jika ada
      List<Map<String, dynamic>> contents = [];
      
      // Tambahkan context dari chat sebelumnya (maksimal 10 pesan terakhir)
      if (context != null && context.isNotEmpty) {
        final recentMessages = context.take(10).toList();
        for (final msg in recentMessages) {
          if (msg.type == MessageType.text && !msg.isLoading && msg.error == null) {
            contents.add({
              'role': msg.sender == MessageSender.user ? 'user' : 'model',
              'parts': [{'text': msg.content}]
            });
          }
        }
      }
      
      // Tambahkan pesan baru
      contents.add({
        'role': 'user',
        'parts': [{'text': message}]
      });

      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/gemini-1.5-flash:generateContent'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('✅ Received response from Gemini AI');
          return content ?? 'Maaf, saya tidak dapat memberikan respons yang sesuai.';
        } else {
          throw Exception('No valid response from Gemini AI');
        }
      } else {
        debugPrint('❌ Gemini AI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
      return _getFallbackResponse(message);
    }
  }

  /// Mengirim gambar ke Gemini AI untuk analisis
  Future<String> sendImageMessage(String imagePath, {String? prompt}) async {
    try {
      debugPrint('🖼️ Sending image to Gemini AI: $imagePath');
      
      // Baca file gambar
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }
      
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // Tentukan MIME type berdasarkan ekstensi file
      String mimeType = 'image/jpeg';
      final String extension = imagePath.split('.').last.toLowerCase();
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
      }

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': prompt ?? 'Analisis gambar ini dan berikan deskripsi yang detail. Jika ini adalah gambar yang berkaitan dengan bisnis atau inventori, berikan insight yang berguna.'
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 1024,
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/gemini-1.5-flash:generateContent'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('✅ Received image analysis from Gemini AI');
          return content ?? 'Maaf, saya tidak dapat menganalisis gambar ini.';
        } else {
          throw Exception('No valid response from Gemini AI');
        }
      } else {
        debugPrint('❌ Gemini AI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error sending image message: $e');
      return 'Maaf, saya tidak dapat menganalisis gambar saat ini. Silakan coba lagi nanti atau kirim pesan teks.';
    }
  }

  /// Mendapatkan respons fallback jika API gagal
  String _getFallbackResponse(String message) {
    final String lowerMessage = message.toLowerCase();
    
    // Respons berdasarkan kata kunci
    if (lowerMessage.contains('halo') || lowerMessage.contains('hai') || lowerMessage.contains('hello')) {
      return 'Halo! Saya adalah AI Assistant untuk WareSys. Bagaimana saya bisa membantu Anda hari ini?';
    }
    
    if (lowerMessage.contains('inventory') || lowerMessage.contains('stok') || lowerMessage.contains('barang')) {
      return 'Saya dapat membantu Anda dengan manajemen inventori. Anda bisa menanyakan tentang stok barang, prediksi kebutuhan, atau analisis pergerakan inventory.';
    }
    
    if (lowerMessage.contains('keuangan') || lowerMessage.contains('finance') || lowerMessage.contains('laporan')) {
      return 'Untuk masalah keuangan, saya bisa membantu menganalisis laporan keuangan, memberikan insight tentang cash flow, dan prediksi finansial.';
    }
    
    if (lowerMessage.contains('transaksi') || lowerMessage.contains('penjualan') || lowerMessage.contains('pembelian')) {
      return 'Saya dapat membantu menganalisis data transaksi, memberikan insight penjualan, dan membantu optimasi proses bisnis Anda.';
    }
    
    if (lowerMessage.contains('bantuan') || lowerMessage.contains('help')) {
      return 'Saya adalah AI Assistant untuk sistem ERP WareSys. Saya bisa membantu dengan:\n\n• Analisis data inventory\n• Insight keuangan\n• Analisis transaksi\n• Prediksi bisnis\n• Analisis gambar/dokumen\n\nSilakan tanyakan apa yang Anda butuhkan!';
    }
    
    // Respons default
    return 'Maaf, saya sedang mengalami gangguan koneksi. Silakan coba lagi dalam beberapa saat. Sementara itu, Anda bisa menggunakan fitur-fitur lain di aplikasi WareSys.';
  }

  /// Validasi API key
  bool get isApiKeyValid => _apiKey != 'YOUR_GEMINI_API_KEY' && _apiKey.isNotEmpty;

  /// Test koneksi ke Gemini AI
  Future<bool> testConnection() async {
    try {
      if (!isApiKeyValid) {
        debugPrint('⚠️ Gemini API key not configured');
        return false;
      }
      
      final response = await sendTextMessage('Hello');
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }
}