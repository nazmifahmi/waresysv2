# 🔧 WareSystem v2 - Technical Documentation

> **Dokumentasi Teknis Mendalam untuk Developer dan Arsitektur Sistem**

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Database Design](#database-design)
3. [API & Services](#api--services)
4. [AI/ML Implementation](#aiml-implementation)
5. [State Management](#state-management)
6. [Security Implementation](#security-implementation)
7. [Performance Optimization](#performance-optimization)
8. [Testing Strategy](#testing-strategy)
9. [Deployment Guide](#deployment-guide)
10. [Troubleshooting](#troubleshooting)

## 🏗️ Architecture Overview

### **Clean Architecture Pattern**

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Screens   │  │   Widgets   │  │  Providers  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Services   │  │   Models    │  │    Utils    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Firebase   │  │ Local Cache │  │  AI Models  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### **Module Structure**

```
lib/
├── constants/
│   └── theme.dart                 # App theme dan styling
├── models/
│   ├── product_model.dart         # Product entity
│   ├── transaction_model.dart     # Transaction entity
│   ├── finance_model.dart         # Finance entity
│   ├── ai_insight_model.dart      # AI insights entity
│   └── news_model.dart           # News entity
├── providers/
│   ├── auth_provider.dart         # Authentication state
│   ├── inventory_provider.dart    # Inventory state
│   ├── transaction_provider.dart  # Transaction state
│   ├── ai_provider.dart          # AI/ML state
│   ├── news_provider.dart        # News state
│   └── theme_provider.dart       # Theme state
├── screens/
│   ├── monitoring/               # Dashboard & monitoring
│   ├── inventory/                # Inventory management
│   ├── finances/                 # Financial management
│   ├── transaction/              # Transaction management
│   ├── news/                     # News & information
│   └── shared/                   # Shared screens
├── services/
│   ├── ai/                       # AI/ML services
│   ├── auth_service.dart         # Authentication service
│   ├── firestore_service.dart    # Database service
│   ├── transaction_service.dart  # Transaction service
│   ├── finance_service.dart      # Finance service
│   ├── monitoring_service.dart   # Monitoring service
│   ├── news_service.dart         # News service
│   └── pdf_service.dart          # PDF generation
├── utils/
│   ├── currency_formatter.dart   # Currency formatting
│   └── performance_optimizer.dart # Performance utilities
└── widgets/
    ├── common_widgets.dart       # Reusable components
    ├── ai_insight_card.dart      # AI insight widget
    ├── news_section.dart         # News widget
    └── theme_selector.dart       # Theme selector
```

## 🗄️ Database Design

### **Firestore Collections Schema**

#### **Users Collection**
```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "role": "user|admin",
  "createdAt": "timestamp",
  "lastLogin": "timestamp",
  "preferences": {
    "theme": "light|dark|system",
    "language": "string",
    "notifications": "boolean"
  },
  "profile": {
    "avatar": "string",
    "phone": "string",
    "address": "string"
  }
}
```

#### **Products Collection**
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "price": "number",
  "stock": "number",
  "minStock": "number",
  "category": "string",
  "sku": "string",
  "imageUrl": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "string",
  "isActive": "boolean",
  "tags": ["string"],
  "supplier": {
    "name": "string",
    "contact": "string"
  }
}
```

#### **Transactions Collection**
```json
{
  "id": "string",
  "type": "sales|purchase",
  "items": [
    {
      "productId": "string",
      "productName": "string",
      "quantity": "number",
      "price": "number",
      "subtotal": "number"
    }
  ],
  "total": "number",
  "paymentMethod": "cash|transfer|qris|other",
  "paymentStatus": "paid|unpaid",
  "deliveryStatus": "delivered|pending|canceled",
  "customer": {
    "name": "string",
    "contact": "string",
    "address": "string"
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "createdBy": "string",
  "logs": [
    {
      "action": "string",
      "userId": "string",
      "userName": "string",
      "timestamp": "timestamp",
      "note": "string"
    }
  ]
}
```

#### **Finance Collection**
```json
{
  "id": "string",
  "type": "income|expense|budget",
  "amount": "number",
  "category": "string",
  "description": "string",
  "date": "timestamp",
  "transactionId": "string",
  "createdBy": "string",
  "createdAt": "timestamp",
  "tags": ["string"],
  "recurring": {
    "isRecurring": "boolean",
    "frequency": "daily|weekly|monthly|yearly",
    "endDate": "timestamp"
  }
}
```

#### **AI Logs Collection**
```json
{
  "id": "string",
  "type": "prediction|insight|recommendation",
  "model": "sales|stock|financial",
  "input": "object",
  "output": "object",
  "confidence": "number",
  "timestamp": "timestamp",
  "userId": "string",
  "processingTime": "number",
  "version": "string"
}
```

### **Database Indexes**

```json
{
  "indexes": [
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "createdBy", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "category", "order": "ASCENDING"},
        {"fieldPath": "stock", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "finance",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "type", "order": "ASCENDING"},
        {"fieldPath": "date", "order": "DESCENDING"}
      ]
    }
  ]
}
```

## 🔌 API & Services

### **Service Architecture**

#### **FirestoreService**
```dart
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generic CRUD operations
  Future<void> create(String collection, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> read(String collection, String id);
  Future<void> update(String collection, String id, Map<String, dynamic> data);
  Future<void> delete(String collection, String id);
  
  // Stream operations
  Stream<List<T>> getCollectionStream<T>(String collection);
  Stream<T?> getDocumentStream<T>(String collection, String id);
  
  // Batch operations
  Future<void> batchWrite(List<BatchOperation> operations);
  
  // Query operations
  Future<List<T>> query<T>(String collection, List<QueryFilter> filters);
}
```

#### **AuthService**
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Authentication methods
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<void> signOut();
  
  // User management
  Future<void> updateProfile(Map<String, dynamic> data);
  Future<void> changePassword(String newPassword);
  Future<void> resetPassword(String email);
  
  // Biometric authentication
  Future<bool> authenticateWithBiometrics();
}
```

#### **AIService**
```dart
class AIService {
  // Model management
  Future<void> initialize();
  Future<bool> loadModel(String modelPath);
  Future<void> validateModel(String modelPath);
  
  // Prediction services
  Future<SalesPrediction> predictSales(SalesInput input);
  Future<StockPrediction> predictStock(StockInput input);
  Future<FinancialPrediction> predictFinance(FinanceInput input);
  
  // Insights generation
  Future<List<AIInsight>> generateInsights(BusinessData data);
  Future<List<Recommendation>> getRecommendations(String type);
  
  // Background processing
  Future<void> processInBackground(ProcessingTask task);
}
```

### **API Integration Patterns**

#### **Repository Pattern**
```dart
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> create(T entity);
  Future<void> update(String id, T entity);
  Future<void> delete(String id);
  Stream<List<T>> watchAll();
  Stream<T?> watchById(String id);
}

class ProductRepository implements Repository<Product> {
  final FirestoreService _firestore;
  
  @override
  Future<List<Product>> getAll() async {
    final docs = await _firestore.query('products', []);
    return docs.map((doc) => Product.fromMap(doc)).toList();
  }
  
  // Implementation of other methods...
}
```

#### **Service Locator Pattern**
```dart
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};
  
  static void register<T>(T service) {
    _services[T] = service;
  }
  
  static T get<T>() {
    return _services[T] as T;
  }
}

// Usage
ServiceLocator.register<AuthService>(AuthService());
ServiceLocator.register<FirestoreService>(FirestoreService());

final authService = ServiceLocator.get<AuthService>();
```

## 🤖 AI/ML Implementation

### **AI Chatbot System**
#### **Google Gemini AI Integration**
```dart
class ChatService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  
  Future<String> sendTextMessage(String message, {List<ChatMessage>? context}) async {
    // Context-aware conversation dengan chat history
    // Safety settings dan content filtering
    // Error handling dan fallback responses
  }
  
  Future<String> sendImageMessage(String imagePath, {String? prompt}) async {
    // Multi-modal AI untuk analisis gambar
    // Business document analysis
    // Image-to-text insights
  }
}
```

#### **Chat Architecture**
```
ChatSystem
├── ChatProvider (State Management)
├── ChatService (Gemini AI Integration)
├── ChatMessageModel (Data Models)
├── ChatScreen (UI Interface)
├── FloatingChatBubble (Global Access)
└── ChatInputWidget (User Input)
```

#### **Features**
- **Context-Aware Conversations**: Menyimpan 10 pesan terakhir untuk konteks
- **Multi-Modal Support**: Text dan image analysis
- **Real-time Notifications**: Unread message indicators
- **Error Handling**: Fallback responses untuk offline mode
- **Security**: Content filtering dan safety settings

### **TensorFlow Lite Integration**

#### **Model Architecture**
```
Models/
├── sales_prediction.tflite      # Sales forecasting model
├── stock_prediction.tflite      # Stock optimization model
└── financial_prediction.tflite  # Financial forecasting model
```

#### **AI Service Implementation**
```dart
class AIService {
  late Interpreter _salesInterpreter;
  late Interpreter _stockInterpreter;
  late Interpreter _financialInterpreter;
  
  Future<void> initialize() async {
    try {
      // Load models
      _salesInterpreter = await _loadModel('assets/ml/sales_prediction.tflite');
      _stockInterpreter = await _loadModel('assets/ml/stock_prediction.tflite');
      _financialInterpreter = await _loadModel('assets/ml/financial_prediction.tflite');
      
      // Validate models
      await _validateModels();
      
      debugPrint('✅ AI Service initialized successfully');
    } catch (e) {
      debugPrint('❌ AI Service initialization failed: $e');
      _useMockService = true;
    }
  }
  
  Future<SalesPrediction> predictSales(SalesInput input) async {
    if (_useMockService) {
      return _mockService.predictSales(input);
    }
    
    try {
      // Preprocess input
      final processedInput = _preprocessSalesInput(input);
      
      // Run inference
      _salesInterpreter.run(processedInput, _salesOutput);
      
      // Postprocess output
      return _postprocessSalesOutput(_salesOutput);
    } catch (e) {
      debugPrint('Sales prediction error: $e');
      return _mockService.predictSales(input);
    }
  }
}
```

#### **Predictors Implementation**

**Stock Predictor**
```dart
class StockPredictor {
  Future<StockPrediction> predict(List<Product> products, List<Transaction> transactions) async {
    // Feature engineering
    final features = _extractFeatures(products, transactions);
    
    // Normalize features
    final normalizedFeatures = _normalizeFeatures(features);
    
    // Run prediction
    final prediction = await _runInference(normalizedFeatures);
    
    return StockPrediction(
      recommendations: prediction.recommendations,
      confidence: prediction.confidence,
      timestamp: DateTime.now(),
    );
  }
  
  List<double> _extractFeatures(List<Product> products, List<Transaction> transactions) {
    // Extract relevant features for stock prediction
    return [
      _calculateAverageSales(transactions),
      _calculateStockTurnover(products, transactions),
      _calculateSeasonality(transactions),
      _calculateTrend(transactions),
    ];
  }
}
```

**Sales Predictor**
```dart
class SalesPredictor {
  Future<SalesPrediction> predict(List<Transaction> historicalData) async {
    // Time series analysis
    final timeSeries = _createTimeSeries(historicalData);
    
    // Feature extraction
    final features = _extractTimeSeriesFeatures(timeSeries);
    
    // Prediction
    final prediction = await _runTimeSeriesInference(features);
    
    return SalesPrediction(
      nextPeriodSales: prediction.value,
      confidence: prediction.confidence,
      trend: prediction.trend,
      seasonality: prediction.seasonality,
    );
  }
}
```

### **Background Processing**

```dart
class BackgroundAIProcessor {
  static Future<void> processInIsolate(ProcessingTask task) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(_isolateEntryPoint, {
      'sendPort': receivePort.sendPort,
      'task': task.toMap(),
    });
    
    final result = await receivePort.first;
    return result;
  }
  
  static void _isolateEntryPoint(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final task = ProcessingTask.fromMap(params['task']);
    
    try {
      final result = await _processTask(task);
      sendPort.send(result);
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }
}
```

## 🔄 State Management

### **Provider Pattern Implementation**

#### **Base Provider**
```dart
abstract class BaseProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

#### **Transaction Provider**
```dart
class TransactionProvider extends BaseProvider {
  final TransactionService _service = TransactionService();
  
  List<Transaction> _transactions = [];
  Transaction? _selectedTransaction;
  
  List<Transaction> get transactions => _transactions;
  Transaction? get selectedTransaction => _selectedTransaction;
  
  Future<void> loadTransactions() async {
    setLoading(true);
    try {
      _transactions = await _service.getAllTransactions();
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
  
  Future<void> createTransaction(Transaction transaction) async {
    setLoading(true);
    try {
      await _service.createTransaction(transaction);
      _transactions.add(transaction);
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}
```

### **Provider Setup**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
```

## 🔒 Security Implementation

### **Firebase Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data access
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products - read for all authenticated users, write for admins
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Transactions - users can only access their own
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        (resource.data.createdBy == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
    
    // Finance - admin only
    match /finance/{document} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### **Data Encryption**

```dart
class EncryptionService {
  static const String _key = 'your-encryption-key';
  
  static String encrypt(String data) {
    final key = encrypt.Key.fromBase64(_key);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
  
  static String decrypt(String encryptedData) {
    final parts = encryptedData.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    
    final key = encrypt.Key.fromBase64(_key);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
```

### **Biometric Authentication**

```dart
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  Future<bool> isBiometricAvailable() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }
  
  Future<bool> authenticate() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }
}
```

## ⚡ Performance Optimization

### **Memory Management**

```dart
class PerformanceOptimizer {
  static void optimizeImages() {
    // Image caching configuration
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  }
  
  static void optimizeListViews() {
    // ListView optimization
    // Use ListView.builder for large lists
    // Implement lazy loading
    // Use AutomaticKeepAliveClientMixin for expensive widgets
  }
  
  static void disposeResources() {
    // Proper disposal of controllers, streams, etc.
  }
}
```

### **Database Optimization**

```dart
class DatabaseOptimizer {
  static Query optimizeQuery(Query query, {int? limit}) {
    // Add appropriate indexes
    // Limit results
    // Use compound queries efficiently
    return query.limit(limit ?? 50);
  }
  
  static Stream<List<T>> paginatedStream<T>(
    String collection,
    int pageSize,
  ) {
    // Implement pagination for large datasets
    return FirebaseFirestore.instance
        .collection(collection)
        .limit(pageSize)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            T.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }
}
```

### **Caching Strategy**

```dart
class CacheManager {
  static final Map<String, CacheEntry> _cache = {};
  static const Duration _defaultTTL = Duration(minutes: 30);
  
  static void put(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTTL,
    );
  }
  
  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().difference(entry.timestamp) > entry.ttl) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T;
  }
  
  static void clear() {
    _cache.clear();
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
}
```

## 🧪 Testing Strategy

### **Unit Testing**

```dart
// test/services/transaction_service_test.dart
class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  group('TransactionService', () {
    late TransactionService service;
    late MockFirestoreService mockFirestore;
    
    setUp(() {
      mockFirestore = MockFirestoreService();
      service = TransactionService(firestore: mockFirestore);
    });
    
    test('should create transaction successfully', () async {
      // Arrange
      final transaction = Transaction(
        id: 'test-id',
        type: TransactionType.sales,
        total: 100.0,
        // ... other properties
      );
      
      when(mockFirestore.create('transactions', any))
          .thenAnswer((_) async => {});
      
      // Act
      await service.createTransaction(transaction);
      
      // Assert
      verify(mockFirestore.create('transactions', transaction.toMap()));
    });
  });
}
```

### **Widget Testing**

```dart
// test/widgets/transaction_form_test.dart
void main() {
  group('TransactionForm', () {
    testWidgets('should display form fields', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionForm(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Product'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
    });
    
    testWidgets('should validate required fields', (tester) async {
      // Test form validation
    });
  });
}
```

### **Integration Testing**

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('complete transaction flow', (tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle();
      
      // Login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Navigate to transactions
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      
      // Create new transaction
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Fill form and submit
      await tester.enterText(find.byKey(Key('product-field')), 'Test Product');
      await tester.enterText(find.byKey(Key('quantity-field')), '5');
      await tester.enterText(find.byKey(Key('price-field')), '100');
      
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // Verify transaction created
      expect(find.text('Test Product'), findsOneWidget);
    });
  });
}
```

## 🚀 Deployment Guide

### **Environment Configuration**

```dart
// lib/config/environment.dart
class Environment {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';
  
  static String get apiBaseUrl {
    switch (_environment) {
      case 'production':
        return 'https://api.waresys.com';
      case 'staging':
        return 'https://staging-api.waresys.com';
      default:
        return 'https://dev-api.waresys.com';
    }
  }
}
```

### **Build Scripts**

```bash
#!/bin/bash
# scripts/build_android.sh

echo "Building Android APK..."

# Clean previous builds
flutter clean
flutter pub get

# Build APK
flutter build apk --release --dart-define=ENVIRONMENT=production

echo "Android APK built successfully!"
echo "Location: build/app/outputs/flutter-apk/app-release.apk"
```

```bash
#!/bin/bash
# scripts/build_ios.sh

echo "Building iOS IPA..."

# Clean previous builds
flutter clean
flutter pub get

# Build iOS
flutter build ios --release --dart-define=ENVIRONMENT=production

echo "iOS build completed!"
echo "Open ios/Runner.xcworkspace in Xcode to archive"
```

### **CI/CD Pipeline (GitHub Actions)**

```yaml
# .github/workflows/deploy.yml
name: Deploy App

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Run integration tests
        run: flutter test integration_test/

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build APK
        run: flutter build apk --release --dart-define=ENVIRONMENT=production
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build iOS
        run: flutter build ios --release --dart-define=ENVIRONMENT=production --no-codesign
```

## 🔧 Troubleshooting

### **Common Issues**

#### **Firebase Connection Issues**
```dart
// Check Firebase connection
Future<bool> checkFirebaseConnection() async {
  try {
    await FirebaseFirestore.instance
        .collection('test')
        .limit(1)
        .get()
        .timeout(Duration(seconds: 5));
    return true;
  } catch (e) {
    debugPrint('Firebase connection failed: $e');
    return false;
  }
}
```

#### **AI Model Loading Issues**
```dart
// Validate AI models
Future<bool> validateAIModels() async {
  try {
    final modelPath = 'assets/ml/sales_prediction.tflite';
    final modelBytes = await rootBundle.load(modelPath);
    
    if (modelBytes.lengthInBytes == 0) {
      throw Exception('Model file is empty');
    }
    
    // Try to load interpreter
    final interpreter = await Interpreter.fromAsset(modelPath);
    interpreter.close();
    
    return true;
  } catch (e) {
    debugPrint('AI model validation failed: $e');
    return false;
  }
}
```

#### **Performance Issues**
```dart
// Monitor performance
class PerformanceMonitor {
  static void trackWidgetBuild(String widgetName) {
    final stopwatch = Stopwatch()..start();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 16) { // 60fps = 16ms per frame
        debugPrint('Slow widget build: $widgetName took ${stopwatch.elapsedMilliseconds}ms');
      }
    });
  }
}
```

### **Debug Tools**

```dart
// Debug overlay
class DebugOverlay extends StatelessWidget {
  final Widget child;
  
  const DebugOverlay({required this.child});
  
  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return child;
    
    return Stack(
      children: [
        child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: EdgeInsets.all(8),
            color: Colors.black54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debug Info', style: TextStyle(color: Colors.white)),
                Text('FPS: ${_getCurrentFPS()}', style: TextStyle(color: Colors.white)),
                Text('Memory: ${_getMemoryUsage()}', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

---

**WareSystem v2 Technical Documentation** - Comprehensive guide for developers and system architects! 🚀