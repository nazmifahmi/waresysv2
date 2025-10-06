# 🔌 WareSystem v2 - API Documentation

> **Comprehensive API Documentation for WareSystem v2 ERP Application**

## 📋 Table of Contents

1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Core APIs](#core-apis)
4. [AI/ML APIs](#aiml-apis)
5. [Real-time APIs](#real-time-apis)
6. [External Integrations](#external-integrations)
7. [Error Handling](#error-handling)
8. [Rate Limiting](#rate-limiting)
9. [SDK & Libraries](#sdk--libraries)

## 🌐 API Overview

### **Base Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Flutter   │  │     Web     │  │   Mobile    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Auth Guard  │  │Rate Limiter │  │  Validator  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Firebase   │  │   AI/ML     │  │  External   │        │
│  │  Services   │  │  Services   │  │   APIs      │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### **API Endpoints Structure**

```
Base URL: https://api.waresys.com/v1

├── /auth                    # Authentication endpoints
├── /users                   # User management
├── /products               # Product management
├── /inventory              # Inventory operations
├── /transactions           # Transaction management
├── /finance                # Financial operations
├── /monitoring             # Monitoring & analytics
├── /ai                     # AI/ML services
├── /notifications          # Notification services
├── /reports                # Report generation
└── /webhooks               # Webhook endpoints
```

## 🔐 Authentication

### **Authentication Methods**

#### **1. Firebase Authentication**
```dart
// Email/Password Authentication
Future<UserCredential> signInWithEmailPassword(String email, String password) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Get ID token for API calls
    final idToken = await credential.user?.getIdToken();
    
    return credential;
  } catch (e) {
    throw AuthException(e.toString());
  }
}

// Google Sign-In
Future<UserCredential> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
  
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );
  
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

// Apple Sign-In
Future<UserCredential> signInWithApple() async {
  final appleCredential = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
  );
  
  final oauthCredential = OAuthProvider("apple.com").credential(
    idToken: appleCredential.identityToken,
    accessToken: appleCredential.authorizationCode,
  );
  
  return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
}
```

#### **2. API Token Management**
```dart
class ApiTokenManager {
  static String? _currentToken;
  static DateTime? _tokenExpiry;
  
  static Future<String> getValidToken() async {
    if (_currentToken == null || _isTokenExpired()) {
      await _refreshToken();
    }
    return _currentToken!;
  }
  
  static Future<void> _refreshToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentToken = await user.getIdToken(true);
      _tokenExpiry = DateTime.now().add(Duration(hours: 1));
    }
  }
  
  static bool _isTokenExpired() {
    return _tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!);
  }
}
```

#### **3. API Request Headers**
```dart
Map<String, String> getAuthHeaders() async {
  final token = await ApiTokenManager.getValidToken();
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'X-App-Version': await _getAppVersion(),
    'X-Platform': Platform.isAndroid ? 'android' : 'ios',
  };
}
```

## 🔧 Core APIs

### **1. User Management API**

#### **Get User Profile**
```dart
// GET /users/{userId}
Future<UserProfile> getUserProfile(String userId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/users/$userId'),
    headers: await getAuthHeaders(),
  );
  
  if (response.statusCode == 200) {
    return UserProfile.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to get user profile');
  }
}

// Response Model
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime lastLogin;
  final Map<String, dynamic> preferences;
  
  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.lastLogin,
    required this.preferences,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      lastLogin: DateTime.parse(json['lastLogin']),
      preferences: json['preferences'] ?? {},
    );
  }
}
```

#### **Update User Profile**
```dart
// PUT /users/{userId}
Future<void> updateUserProfile(String userId, UserProfileUpdate update) async {
  final response = await http.put(
    Uri.parse('$baseUrl/users/$userId'),
    headers: await getAuthHeaders(),
    body: jsonEncode(update.toJson()),
  );
  
  if (response.statusCode != 200) {
    throw ApiException('Failed to update user profile');
  }
}

class UserProfileUpdate {
  final String? name;
  final String? phone;
  final String? address;
  final Map<String, dynamic>? preferences;
  
  UserProfileUpdate({this.name, this.phone, this.address, this.preferences});
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (preferences != null) data['preferences'] = preferences;
    return data;
  }
}
```

### **2. Product Management API**

#### **Get Products**
```dart
// GET /products
Future<ProductListResponse> getProducts({
  int page = 1,
  int limit = 20,
  String? category,
  String? search,
  String? sortBy,
  String? sortOrder,
}) async {
  final queryParams = {
    'page': page.toString(),
    'limit': limit.toString(),
    if (category != null) 'category': category,
    if (search != null) 'search': search,
    if (sortBy != null) 'sortBy': sortBy,
    if (sortOrder != null) 'sortOrder': sortOrder,
  };
  
  final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
  final response = await http.get(uri, headers: await getAuthHeaders());
  
  if (response.statusCode == 200) {
    return ProductListResponse.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to get products');
  }
}

class ProductListResponse {
  final List<Product> products;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  
  ProductListResponse({
    required this.products,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
  
  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    return ProductListResponse(
      products: (json['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
      totalCount: json['totalCount'],
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
    );
  }
}
```

#### **Create Product**
```dart
// POST /products
Future<Product> createProduct(ProductCreateRequest request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/products'),
    headers: await getAuthHeaders(),
    body: jsonEncode(request.toJson()),
  );
  
  if (response.statusCode == 201) {
    return Product.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to create product');
  }
}

class ProductCreateRequest {
  final String name;
  final String description;
  final double price;
  final int stock;
  final int minStock;
  final String category;
  final String? sku;
  final String? imageUrl;
  
  ProductCreateRequest({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.category,
    this.sku,
    this.imageUrl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'minStock': minStock,
      'category': category,
      if (sku != null) 'sku': sku,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
```

### **3. Transaction Management API**

#### **Create Transaction**
```dart
// POST /transactions
Future<Transaction> createTransaction(TransactionCreateRequest request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/transactions'),
    headers: await getAuthHeaders(),
    body: jsonEncode(request.toJson()),
  );
  
  if (response.statusCode == 201) {
    return Transaction.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to create transaction');
  }
}

class TransactionCreateRequest {
  final TransactionType type;
  final List<TransactionItemRequest> items;
  final PaymentMethod paymentMethod;
  final CustomerInfo? customer;
  final String? notes;
  
  TransactionCreateRequest({
    required this.type,
    required this.items,
    required this.paymentMethod,
    this.customer,
    this.notes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'items': items.map((item) => item.toJson()).toList(),
      'paymentMethod': paymentMethod.toString().split('.').last,
      if (customer != null) 'customer': customer!.toJson(),
      if (notes != null) 'notes': notes,
    };
  }
}

class TransactionItemRequest {
  final String productId;
  final int quantity;
  final double price;
  
  TransactionItemRequest({
    required this.productId,
    required this.quantity,
    required this.price,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}
```

#### **Get Transactions**
```dart
// GET /transactions
Future<TransactionListResponse> getTransactions({
  int page = 1,
  int limit = 20,
  TransactionType? type,
  PaymentStatus? paymentStatus,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final queryParams = {
    'page': page.toString(),
    'limit': limit.toString(),
    if (type != null) 'type': type.toString().split('.').last,
    if (paymentStatus != null) 'paymentStatus': paymentStatus.toString().split('.').last,
    if (startDate != null) 'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate.toIso8601String(),
  };
  
  final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
  final response = await http.get(uri, headers: await getAuthHeaders());
  
  if (response.statusCode == 200) {
    return TransactionListResponse.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to get transactions');
  }
}
```

### **4. Inventory Management API**

#### **Stock Mutation**
```dart
// POST /inventory/mutations
Future<StockMutation> createStockMutation(StockMutationRequest request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/inventory/mutations'),
    headers: await getAuthHeaders(),
    body: jsonEncode(request.toJson()),
  );
  
  if (response.statusCode == 201) {
    return StockMutation.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to create stock mutation');
  }
}

class StockMutationRequest {
  final String productId;
  final StockMutationType type;
  final int quantity;
  final String reason;
  final String? notes;
  
  StockMutationRequest({
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reason,
    this.notes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'reason': reason,
      if (notes != null) 'notes': notes,
    };
  }
}

enum StockMutationType { in_, out }
```

#### **Get Stock History**
```dart
// GET /inventory/history
Future<StockHistoryResponse> getStockHistory({
  String? productId,
  DateTime? startDate,
  DateTime? endDate,
  int page = 1,
  int limit = 20,
}) async {
  final queryParams = {
    'page': page.toString(),
    'limit': limit.toString(),
    if (productId != null) 'productId': productId,
    if (startDate != null) 'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate.toIso8601String(),
  };
  
  final uri = Uri.parse('$baseUrl/inventory/history').replace(queryParameters: queryParams);
  final response = await http.get(uri, headers: await getAuthHeaders());
  
  if (response.statusCode == 200) {
    return StockHistoryResponse.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to get stock history');
  }
}
```

## 🤖 AI/ML APIs

### AI Chatbot API

#### Send Text Message
```dart
// ChatService - Gemini AI Integration
Future<String> sendTextMessage(String message, {List<ChatMessage>? context}) async {
  try {
    // Buat context dari chat history
    List<Map<String, dynamic>> contents = [];
    
    // Tambahkan context (maksimal 10 pesan terakhir)
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
        // ... other safety settings
      ]
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/gemini-1.5-flash:generateContent'),
      headers: _headers,
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    
    throw Exception('Failed to get AI response');
  } catch (e) {
    return _getFallbackResponse(message);
  }
}
```

#### Send Image Message
```dart
Future<String> sendImageMessage(String imagePath, {String? prompt}) async {
  try {
    // Baca file gambar
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    
    // Tentukan MIME type
    String mimeType = 'image/jpeg';
    if (imagePath.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    }
    
    final requestBody = {
      'contents': [{
        'parts': [
          {'text': prompt ?? 'Analisis gambar ini dan berikan insight bisnis'},
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Image
            }
          }
        ]
      }],
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
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    
    throw Exception('Failed to analyze image');
  } catch (e) {
    return 'Maaf, saya tidak dapat menganalisis gambar saat ini. Silakan coba lagi nanti.';
  }
}
```

#### Chat Provider State Management
```dart
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isChatOpen = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isChatOpen => _isChatOpen;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get hasUnreadMessages => !_isChatOpen && _messages.isNotEmpty && 
                                _messages.last.sender == MessageSender.ai;

  // Send text message
  Future<void> sendTextMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      _error = null;
      
      // Add user message
      final userMessage = ChatMessage.user(
        content: message.trim(),
        type: MessageType.text,
      );
      _messages.add(userMessage);
      notifyListeners();
      
      // Add loading message
      final loadingMessage = ChatMessage.loading();
      _messages.add(loadingMessage);
      _isLoading = true;
      notifyListeners();
      
      // Send to AI service
      final response = await _chatService.sendTextMessage(
        message.trim(),
        context: _messages.where((m) => !m.isLoading).toList(),
      );
      
      // Remove loading message
      _messages.removeWhere((m) => m.id == loadingMessage.id);
      
      // Add AI response
      final aiMessage = ChatMessage.ai(
        content: response,
        type: MessageType.text,
      );
      _messages.add(aiMessage);
      
    } catch (e) {
      _messages.removeWhere((m) => m.isLoading);
      final errorMessage = ChatMessage.error(e.toString());
      _messages.add(errorMessage);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Sales Prediction API**

```dart
// POST /ai/predictions/sales
Future<SalesPrediction> predictSales(SalesPredictionRequest request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ai/predictions/sales'),
    headers: await getAuthHeaders(),
    body: jsonEncode(request.toJson()),
  );
  
  if (response.statusCode == 200) {
    return SalesPrediction.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to predict sales');
  }
}

class SalesPredictionRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String? productId;
  final String? category;
  final List<String>? features;
  
  SalesPredictionRequest({
    required this.startDate,
    required this.endDate,
    this.productId,
    this.category,
    this.features,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (productId != null) 'productId': productId,
      if (category != null) 'category': category,
      if (features != null) 'features': features,
    };
  }
}

class SalesPrediction {
  final double predictedValue;
  final double confidence;
  final String trend;
  final Map<String, dynamic> breakdown;
  final DateTime generatedAt;
  
  SalesPrediction({
    required this.predictedValue,
    required this.confidence,
    required this.trend,
    required this.breakdown,
    required this.generatedAt,
  });
  
  factory SalesPrediction.fromJson(Map<String, dynamic> json) {
    return SalesPrediction(
      predictedValue: json['predictedValue'].toDouble(),
      confidence: json['confidence'].toDouble(),
      trend: json['trend'],
      breakdown: json['breakdown'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}
```

### **2. Stock Optimization API**

```dart
// POST /ai/optimization/stock
Future<StockOptimization> optimizeStock(StockOptimizationRequest request) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ai/optimization/stock'),
    headers: await getAuthHeaders(),
    body: jsonEncode(request.toJson()),
  );
  
  if (response.statusCode == 200) {
    return StockOptimization.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to optimize stock');
  }
}

class StockOptimizationRequest {
  final List<String>? productIds;
  final String? category;
  final int forecastDays;
  final double serviceLevel;
  
  StockOptimizationRequest({
    this.productIds,
    this.category,
    required this.forecastDays,
    required this.serviceLevel,
  });
  
  Map<String, dynamic> toJson() {
    return {
      if (productIds != null) 'productIds': productIds,
      if (category != null) 'category': category,
      'forecastDays': forecastDays,
      'serviceLevel': serviceLevel,
    };
  }
}

class StockOptimization {
  final List<StockRecommendation> recommendations;
  final double totalCostSaving;
  final double serviceLevel;
  final DateTime generatedAt;
  
  StockOptimization({
    required this.recommendations,
    required this.totalCostSaving,
    required this.serviceLevel,
    required this.generatedAt,
  });
  
  factory StockOptimization.fromJson(Map<String, dynamic> json) {
    return StockOptimization(
      recommendations: (json['recommendations'] as List)
          .map((item) => StockRecommendation.fromJson(item))
          .toList(),
      totalCostSaving: json['totalCostSaving'].toDouble(),
      serviceLevel: json['serviceLevel'].toDouble(),
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}

class StockRecommendation {
  final String productId;
  final String productName;
  final int currentStock;
  final int recommendedStock;
  final String action;
  final String reason;
  final double confidence;
  
  StockRecommendation({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.recommendedStock,
    required this.action,
    required this.reason,
    required this.confidence,
  });
  
  factory StockRecommendation.fromJson(Map<String, dynamic> json) {
    return StockRecommendation(
      productId: json['productId'],
      productName: json['productName'],
      currentStock: json['currentStock'],
      recommendedStock: json['recommendedStock'],
      action: json['action'],
      reason: json['reason'],
      confidence: json['confidence'].toDouble(),
    );
  }
}
```

### **3. Business Insights API**

```dart
// GET /ai/insights
Future<BusinessInsights> getBusinessInsights({
  DateTime? startDate,
  DateTime? endDate,
  List<String>? categories,
}) async {
  final queryParams = {
    if (startDate != null) 'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate.toIso8601String(),
    if (categories != null) 'categories': categories.join(','),
  };
  
  final uri = Uri.parse('$baseUrl/ai/insights').replace(queryParameters: queryParams);
  final response = await http.get(uri, headers: await getAuthHeaders());
  
  if (response.statusCode == 200) {
    return BusinessInsights.fromJson(jsonDecode(response.body));
  } else {
    throw ApiException('Failed to get business insights');
  }
}

class BusinessInsights {
  final List<Insight> insights;
  final List<Recommendation> recommendations;
  final Map<String, dynamic> metrics;
  final DateTime generatedAt;
  
  BusinessInsights({
    required this.insights,
    required this.recommendations,
    required this.metrics,
    required this.generatedAt,
  });
  
  factory BusinessInsights.fromJson(Map<String, dynamic> json) {
    return BusinessInsights(
      insights: (json['insights'] as List)
          .map((item) => Insight.fromJson(item))
          .toList(),
      recommendations: (json['recommendations'] as List)
          .map((item) => Recommendation.fromJson(item))
          .toList(),
      metrics: json['metrics'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}
```

## 📊 Real-time APIs

### **1. WebSocket Connection**

```dart
class RealtimeService {
  late WebSocketChannel _channel;
  final StreamController<RealtimeEvent> _eventController = StreamController.broadcast();
  
  Stream<RealtimeEvent> get events => _eventController.stream;
  
  Future<void> connect() async {
    final token = await ApiTokenManager.getValidToken();
    final uri = Uri.parse('wss://api.waresys.com/v1/realtime?token=$token');
    
    _channel = WebSocketChannel.connect(uri);
    
    _channel.stream.listen(
      (data) {
        final event = RealtimeEvent.fromJson(jsonDecode(data));
        _eventController.add(event);
      },
      onError: (error) {
        print('WebSocket error: $error');
        _reconnect();
      },
      onDone: () {
        print('WebSocket connection closed');
        _reconnect();
      },
    );
  }
  
  void subscribe(String channel) {
    _channel.sink.add(jsonEncode({
      'action': 'subscribe',
      'channel': channel,
    }));
  }
  
  void unsubscribe(String channel) {
    _channel.sink.add(jsonEncode({
      'action': 'unsubscribe',
      'channel': channel,
    }));
  }
  
  Future<void> _reconnect() async {
    await Future.delayed(Duration(seconds: 5));
    await connect();
  }
  
  void dispose() {
    _channel.sink.close();
    _eventController.close();
  }
}

class RealtimeEvent {
  final String type;
  final String channel;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  RealtimeEvent({
    required this.type,
    required this.channel,
    required this.data,
    required this.timestamp,
  });
  
  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeEvent(
      type: json['type'],
      channel: json['channel'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
```

### **2. Real-time Channels**

```dart
// Available channels
const String CHANNEL_TRANSACTIONS = 'transactions';
const String CHANNEL_INVENTORY = 'inventory';
const String CHANNEL_NOTIFICATIONS = 'notifications';
const String CHANNEL_SYSTEM_STATUS = 'system_status';

// Usage example
class TransactionRealtimeService {
  final RealtimeService _realtimeService = RealtimeService();
  
  Stream<Transaction> get newTransactions {
    return _realtimeService.events
        .where((event) => event.channel == CHANNEL_TRANSACTIONS && event.type == 'created')
        .map((event) => Transaction.fromJson(event.data));
  }
  
  Stream<Transaction> get updatedTransactions {
    return _realtimeService.events
        .where((event) => event.channel == CHANNEL_TRANSACTIONS && event.type == 'updated')
        .map((event) => Transaction.fromJson(event.data));
  }
  
  void startListening() {
    _realtimeService.subscribe(CHANNEL_TRANSACTIONS);
  }
  
  void stopListening() {
    _realtimeService.unsubscribe(CHANNEL_TRANSACTIONS);
  }
}
```

## 🔗 External Integrations

### **1. News API Integration**

```dart
class NewsService {
  static const String _newsApiKey = 'your-news-api-key';
  static const String _baseUrl = 'https://newsapi.org/v2';
  
  Future<NewsResponse> getBusinessNews({
    String country = 'id',
    String category = 'business',
    int pageSize = 20,
    int page = 1,
  }) async {
    final queryParams = {
      'country': country,
      'category': category,
      'pageSize': pageSize.toString(),
      'page': page.toString(),
      'apiKey': _newsApiKey,
    };
    
    final uri = Uri.parse('$_baseUrl/top-headlines').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return NewsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to fetch news');
    }
  }
  
  Future<NewsResponse> searchNews({
    required String query,
    String sortBy = 'publishedAt',
    int pageSize = 20,
    int page = 1,
  }) async {
    final queryParams = {
      'q': query,
      'sortBy': sortBy,
      'pageSize': pageSize.toString(),
      'page': page.toString(),
      'apiKey': _newsApiKey,
    };
    
    final uri = Uri.parse('$_baseUrl/everything').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      return NewsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to search news');
    }
  }
}

class NewsResponse {
  final String status;
  final int totalResults;
  final List<NewsArticle> articles;
  
  NewsResponse({
    required this.status,
    required this.totalResults,
    required this.articles,
  });
  
  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      status: json['status'],
      totalResults: json['totalResults'],
      articles: (json['articles'] as List)
          .map((item) => NewsArticle.fromJson(item))
          .toList(),
    );
  }
}
```

### **2. Payment Gateway Integration**

```dart
class PaymentService {
  // QRIS Payment
  Future<QRISPaymentResponse> generateQRIS({
    required double amount,
    required String transactionId,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/qris/generate'),
      headers: await getAuthHeaders(),
      body: jsonEncode({
        'amount': amount,
        'transactionId': transactionId,
        'description': description,
      }),
    );
    
    if (response.statusCode == 200) {
      return QRISPaymentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to generate QRIS');
    }
  }
  
  // Bank Transfer
  Future<BankTransferResponse> initiateBankTransfer({
    required double amount,
    required String transactionId,
    required String bankCode,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/bank-transfer/initiate'),
      headers: await getAuthHeaders(),
      body: jsonEncode({
        'amount': amount,
        'transactionId': transactionId,
        'bankCode': bankCode,
        'description': description,
      }),
    );
    
    if (response.statusCode == 200) {
      return BankTransferResponse.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to initiate bank transfer');
    }
  }
  
  // Check Payment Status
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/$paymentId/status'),
      headers: await getAuthHeaders(),
    );
    
    if (response.statusCode == 200) {
      return PaymentStatus.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to check payment status');
    }
  }
}
```

## ❌ Error Handling

### **Error Response Format**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    },
    "timestamp": "2024-01-15T10:30:00Z",
    "requestId": "req_123456789"
  }
}
```

### **Error Handling Implementation**

```dart
class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? requestId;
  
  ApiException(this.message, {this.code = 'UNKNOWN_ERROR', this.details, this.requestId});
  
  factory ApiException.fromResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      final error = json['error'];
      
      return ApiException(
        error['message'],
        code: error['code'],
        details: error['details'],
        requestId: error['requestId'],
      );
    } catch (e) {
      return ApiException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }
  
  @override
  String toString() {
    return 'ApiException: $code - $message';
  }
}

// Error codes
class ApiErrorCodes {
  static const String VALIDATION_ERROR = 'VALIDATION_ERROR';
  static const String AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR';
  static const String AUTHORIZATION_ERROR = 'AUTHORIZATION_ERROR';
  static const String NOT_FOUND = 'NOT_FOUND';
  static const String RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED';
  static const String INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR';
  static const String SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE';
}

// Global error handler
class ApiErrorHandler {
  static void handleError(ApiException error) {
    switch (error.code) {
      case ApiErrorCodes.AUTHENTICATION_ERROR:
        // Redirect to login
        _redirectToLogin();
        break;
      case ApiErrorCodes.RATE_LIMIT_EXCEEDED:
        // Show rate limit message
        _showRateLimitMessage();
        break;
      case ApiErrorCodes.SERVICE_UNAVAILABLE:
        // Show maintenance message
        _showMaintenanceMessage();
        break;
      default:
        // Show generic error message
        _showGenericError(error.message);
    }
  }
  
  static void _redirectToLogin() {
    // Implementation
  }
  
  static void _showRateLimitMessage() {
    // Implementation
  }
  
  static void _showMaintenanceMessage() {
    // Implementation
  }
  
  static void _showGenericError(String message) {
    // Implementation
  }
}
```

## 🚦 Rate Limiting

### **Rate Limit Headers**

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642694400
X-RateLimit-Window: 3600
```

### **Rate Limit Implementation**

```dart
class RateLimitManager {
  static final Map<String, RateLimitInfo> _rateLimits = {};
  
  static void updateRateLimit(String endpoint, http.Response response) {
    final headers = response.headers;
    
    if (headers.containsKey('x-ratelimit-limit')) {
      _rateLimits[endpoint] = RateLimitInfo(
        limit: int.parse(headers['x-ratelimit-limit']!),
        remaining: int.parse(headers['x-ratelimit-remaining']!),
        reset: DateTime.fromMillisecondsSinceEpoch(
          int.parse(headers['x-ratelimit-reset']!) * 1000,
        ),
        window: int.parse(headers['x-ratelimit-window']!),
      );
    }
  }
  
  static bool canMakeRequest(String endpoint) {
    final rateLimit = _rateLimits[endpoint];
    if (rateLimit == null) return true;
    
    if (DateTime.now().isAfter(rateLimit.reset)) {
      _rateLimits.remove(endpoint);
      return true;
    }
    
    return rateLimit.remaining > 0;
  }
  
  static Duration getRetryAfter(String endpoint) {
    final rateLimit = _rateLimits[endpoint];
    if (rateLimit == null) return Duration.zero;
    
    return rateLimit.reset.difference(DateTime.now());
  }
}

class RateLimitInfo {
  final int limit;
  final int remaining;
  final DateTime reset;
  final int window;
  
  RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.reset,
    required this.window,
  });
}
```

## 📚 SDK & Libraries

### **API Client Wrapper**

```dart
class WareSystemApiClient {
  static const String _baseUrl = 'https://api.waresys.com/v1';
  final http.Client _httpClient;
  
  WareSystemApiClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();
  
  // User API
  UserApi get users => UserApi(this);
  
  // Product API
  ProductApi get products => ProductApi(this);
  
  // Transaction API
  TransactionApi get transactions => TransactionApi(this);
  
  // Inventory API
  InventoryApi get inventory => InventoryApi(this);
  
  // AI API
  AIApi get ai => AIApi(this);
  
  // Internal method for making requests
  Future<http.Response> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint')
        .replace(queryParameters: queryParams);
    
    final headers = await getAuthHeaders();
    
    // Check rate limit
    if (!RateLimitManager.canMakeRequest(endpoint)) {
      final retryAfter = RateLimitManager.getRetryAfter(endpoint);
      throw ApiException(
        'Rate limit exceeded. Retry after ${retryAfter.inSeconds} seconds',
        code: ApiErrorCodes.RATE_LIMIT_EXCEEDED,
      );
    }
    
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _httpClient.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await _httpClient.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
    
    // Update rate limit info
    RateLimitManager.updateRateLimit(endpoint, response);
    
    // Handle errors
    if (response.statusCode >= 400) {
      throw ApiException.fromResponse(response);
    }
    
    return response;
  }
  
  void dispose() {
    _httpClient.close();
  }
}

// Usage example
void main() async {
  final client = WareSystemApiClient();
  
  try {
    // Get products
    final products = await client.products.getAll();
    print('Found ${products.length} products');
    
    // Create transaction
    final transaction = await client.transactions.create(
      TransactionCreateRequest(
        type: TransactionType.sales,
        items: [
          TransactionItemRequest(
            productId: 'prod_123',
            quantity: 2,
            price: 50.0,
          ),
        ],
        paymentMethod: PaymentMethod.cash,
      ),
    );
    print('Transaction created: ${transaction.id}');
    
  } catch (e) {
    if (e is ApiException) {
      ApiErrorHandler.handleError(e);
    } else {
      print('Unexpected error: $e');
    }
  } finally {
    client.dispose();
  }
}
```

---

**WareSystem v2 API Documentation** - Complete guide for integrating with WareSystem v2 APIs! 🚀