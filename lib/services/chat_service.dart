import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../models/user_model.dart'; // <-- Impor model pengguna yang baru dibuat


// Definisikan Tool/Function yang bisa digunakan oleh AI
final _tools = [
  {
    'function_declarations': [
      {
        'name': 'getProductStock',
        'description': 'Mendapatkan jumlah stok terkini untuk produk tertentu',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'productName': {
              'type': 'STRING',
              'description': 'Nama produk yang ingin diperiksa stoknya'
            }
          },
          'required': ['productName']
        }
      }
    ]
  }
];

// Fungsi dummy untuk mensimulasikan pengambilan data stok
// Di aplikasi nyata, ini akan memanggil database atau API internal Anda
int _getProductStock(String productName) {
  debugPrint('📦 Checking stock for: $productName');
  final lowerCaseProduct = productName.toLowerCase();
  if (lowerCaseProduct.contains('baut')) {
    return 150;
  } else if (lowerCaseProduct.contains('mur')) {
    return 300;
  } else if (lowerCaseProduct.contains('paku')) {
    return 1000;
  }
  return 0;
}

class ChatService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _apiKey = 'AIzaSyC6rf7yigVEVtuk9gTwPQa1W-iBl3o8S_I'; // Gemini API key
  
  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Getter untuk memeriksa apakah API Key sudah diatur
  bool get isApiKeyValid {
    return _apiKey.isNotEmpty && _apiKey != 'AIzaSyC6rf7yigVEVtuk9gTwPQa1W-iBl3o8S_I';
  }

  // Headers untuk API request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  Uri _url(String method) => Uri.parse('$_baseUrl/$method?key=$_apiKey');

  Future<http.Response> _postWithRetry({
    required String method,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // First attempt
    final first = await http
        .post(_url(method), headers: _headers, body: jsonEncode(body))
        .timeout(timeout);

    if (first.statusCode != 400) return first;

    // Minimal retry on 400: remove safetySettings and relax generationConfig
    final Map<String, dynamic> minimal = Map<String, dynamic>.from(body);
    minimal.remove('safetySettings');
    final Map<String, dynamic> genCfg = {
      'temperature': 0.7,
      'maxOutputTokens': 512,
    };
    minimal['generationConfig'] = genCfg;

    return await http
        .post(_url(method), headers: _headers, body: jsonEncode(minimal))
        .timeout(timeout);
  }

  /// Mengirim pesan teks ke Gemini AI
  Future<String> sendTextMessage(
    String message, {
    List<ChatMessage>? context,
    UserModel? user, // <-- Tambahkan parameter user
  }) async {
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
        // Tambahkan System Instruction jika ada user
        if (user != null)
          'systemInstruction': {
            'parts': [{
              'text': 'Anda adalah asisten AI untuk WareSys, sebuah sistem ERP. Pengguna yang bertanya adalah ${user.name}, seorang ${user.role}. Berikan jawaban yang relevan dengan perannya dan sapa pengguna dengan namanya jika memungkinkan.'
            }]
          },
        'contents': contents,
        'tools': _tools, // <-- Menambahkan daftar alat yang tersedia
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

      final response = await _postWithRetry(
        method: 'gemini-flash-latest:generateContent',
        body: requestBody,
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          final content = candidate['content'];

          // Cek apakah AI ingin memanggil fungsi
          if (content['parts'] != null && content['parts'][0]['functionCall'] != null) {
            final functionCall = content['parts'][0]['functionCall'];
            final functionName = functionCall['name'];
            final args = functionCall['args'];

            if (functionName == 'getProductStock') {
              final productName = args['productName'];
              final stock = _getProductStock(productName);

              // Kirim hasil fungsi kembali ke AI
              contents.add(content); // Tambahkan permintaan function call dari AI ke histori
              contents.add({
                'role': 'tool',
                'parts': [
                  {
                    'functionResponse': {
                      'name': 'getProductStock',
                      'response': {'result': stock}
                    }
                  }
                ]
              });

              // Panggil API lagi dengan hasil dari fungsi
              final secondResponse = await _postWithRetry(
                method: 'gemini-flash-latest:generateContent',
                body: {'contents': contents, 'tools': _tools},
                timeout: const Duration(seconds: 30),
              );

              if (secondResponse.statusCode == 200) {
                final secondData = jsonDecode(secondResponse.body);
                if (secondData['candidates'] != null && secondData['candidates'].isNotEmpty) {
                  final textResponse = secondData['candidates'][0]['content']['parts'][0]['text'];
                  debugPrint('✅ Received final response from Gemini AI after function call');
                  return textResponse ?? 'Maaf, saya tidak dapat memberikan respons yang sesuai.';
                }
              }
            }
          }

          // Jika tidak ada function call, kembalikan teks biasa
          final text = candidate['content']['parts'][0]['text'];
          debugPrint('✅ Received response from Gemini AI');
          return text ?? 'Maaf, saya tidak dapat memberikan respons yang sesuai.';
        } else {
          throw Exception('No valid response from Gemini AI');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to connect to Gemini AI: ${response.statusCode} - ${errorBody['error']['message']}');
      }
    } on SocketException {
      debugPrint('🛑 SocketException: No Internet connection or host not reachable.');
      return 'Maaf, koneksi internet Anda tampaknya terputus. Mohon periksa kembali koneksi Anda.';
    } on TimeoutException {
      debugPrint('🛑 TimeoutException: The request to Gemini AI timed out.');
      return 'Maaf, server sedang sibuk atau merespons terlalu lama. Silakan coba lagi dalam beberapa saat.';
    } catch (e) {
      debugPrint('🛑 An unexpected error occurred in sendTextMessage: $e');
      // Fallback to keyword-based response if API fails
      return _getFallbackResponse(message);
    }
  }

  /// Mengirim gambar dan pesan teks (opsional) ke Gemini AI untuk analisis
  Future<String> sendImageMessage(
    String imagePath, {
    String? prompt,
    UserModel? user, // <-- Tambahkan parameter user
  }) async {
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

      // Buat prompt dengan konteks pengguna
      String finalPrompt = prompt ?? 'Analisis gambar ini dan berikan deskripsi yang detail. Jika ini adalah gambar yang berkaitan dengan bisnis atau inventori, berikan insight yang berguna.';
      if (user != null) {
        finalPrompt = 'Sebagai asisten untuk ${user.name} (${user.role}), ${finalPrompt.toLowerCase()}';
      }

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': finalPrompt
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

      final response = await _postWithRetry(
        method: 'gemini-flash-latest:generateContent',
        body: requestBody,
        timeout: const Duration(seconds: 45),
      );

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
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to connect to Gemini AI: ${response.statusCode} - ${errorBody['error']['message']}');
      }
    } on SocketException {
      debugPrint('🛑 SocketException: No Internet connection or host not reachable.');
      return 'Maaf, koneksi internet Anda tampaknya terputus. Mohon periksa kembali koneksi Anda.';
    } on TimeoutException {
      debugPrint('🛑 TimeoutException: The request to Gemini AI timed out.');
      return 'Maaf, server sedang sibuk atau merespons terlalu lama. Silakan coba lagi dalam beberapa saat.';
    } catch (e) {
      debugPrint('🛑 An unexpected error occurred in sendImageMessage: $e');
      return 'Maaf, saya gagal menganalisis gambar tersebut. Pastikan koneksi Anda stabil dan coba lagi.';
    }
  }

  /// Memeriksa koneksi ke Gemini AI
  Future<bool> testConnection() async {
    try {
      if (!isApiKeyValid) {
        debugPrint('⚠️ Gemini API key not configured');
        return false;
      }
      
      // Gunakan GET request yang ringan untuk mengetes API key dan koneksi
      final response = await http.get(Uri.parse('$_baseUrl?key=$_apiKey'));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Connection test successful');
        return true;
      } else {
        debugPrint('❌ Connection test failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Connection test failed with error: $e');
      return false;
    }
  }

  // Respons fallback berbasis kata kunci jika API gagal
  String _getFallbackResponse(String message) {
    final lowerCaseMessage = message.toLowerCase();
    if (lowerCaseMessage.contains('stok') || lowerCaseMessage.contains('inventori')) {
      return 'Maaf, saya tidak dapat terhubung ke server untuk memeriksa data stok saat ini. Silakan coba lagi nanti.';
    }
    if (lowerCaseMessage.contains('bantuan') || lowerCaseMessage.contains('tolong')) {
      return 'Maaf, saya sedang mengalami gangguan koneksi. Anda bisa mencoba bertanya lagi dalam beberapa saat.';
    }
    return 'Maaf, terjadi gangguan koneksi ke server AI. Mohon coba lagi beberapa saat lagi.';
  }
}