import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiApiTester {
  static const String _apiKey = 'AIzaSyCbUmbfANUx7rWGtRJAGtMosW6O6BfkKY0';
  
  /// Test different API versions and models
  static Future<void> runDiagnostics() async {
    debugPrint('🔍 Starting Gemini API Diagnostics...');
    
    // Test different configurations
    final configs = [
      {
        'version': 'v1',
        'model': 'gemini-1.5-flash',
        'description': 'Current configuration'
      },
      {
        'version': 'v1beta',
        'model': 'gemini-1.5-flash',
        'description': 'Beta version'
      },
      {
        'version': 'v1',
        'model': 'gemini-1.5-pro',
        'description': 'Pro model v1'
      },
      {
        'version': 'v1beta',
        'model': 'gemini-1.5-pro',
        'description': 'Pro model beta'
      },
    ];
    
    for (final config in configs) {
      await _testConfiguration(
        config['version']!,
        config['model']!,
        config['description']!,
      );
      await Future.delayed(const Duration(seconds: 2)); // Rate limiting
    }
  }
  
  static Future<void> _testConfiguration(
    String version,
    String model,
    String description,
  ) async {
    try {
      debugPrint('\n🧪 Testing: $description ($version/$model)');
      
      final url = 'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$_apiKey';
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': 'Hello, can you respond with just "API Working"?'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 50,
        }
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('📊 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          debugPrint('✅ SUCCESS: $content');
        } else {
          debugPrint('⚠️ Empty response from API');
        }
      } else {
        debugPrint('❌ FAILED: ${response.statusCode}');
        debugPrint('Error: ${response.body}');
        
        // Try to parse error details
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            debugPrint('Error Details: ${errorData['error']['message']}');
          }
        } catch (e) {
          debugPrint('Could not parse error response');
        }
      }
    } catch (e) {
      debugPrint('❌ Exception: $e');
    }
  }
  
  /// Test API key validity
  static Future<bool> testApiKey() async {
    try {
      debugPrint('🔑 Testing API Key validity...');
      
      final url = 'https://generativelanguage.googleapis.com/v1/models?key=$_apiKey';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['models'] != null) {
          debugPrint('✅ API Key is valid');
          debugPrint('Available models: ${data['models'].length}');
          
          // List available models
          for (final model in data['models']) {
            debugPrint('  - ${model['name']}');
          }
          return true;
        }
      } else {
        debugPrint('❌ API Key test failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ API Key test exception: $e');
    }
    
    return false;
  }
  
  /// Test network connectivity
  static Future<bool> testConnectivity() async {
    try {
      debugPrint('🌐 Testing network connectivity...');
      
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com'),
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('✅ Network connectivity OK (${response.statusCode})');
      return true;
    } catch (e) {
      debugPrint('❌ Network connectivity failed: $e');
      return false;
    }
  }
}