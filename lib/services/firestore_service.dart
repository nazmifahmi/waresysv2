import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FirestoreService {
  final FirebaseFirestore? _firestore;
  final FirestoreConnectionService _connectionService;
  late SharedPreferences _prefs;
  bool _prefsInitialized = false;

  FirestoreService() : 
    _firestore = FirebaseFirestore.instance,
    _connectionService = FirestoreConnectionService();

  // Constructor untuk testing dengan custom Firestore instance
  FirestoreService.withFirestore(this._firestore) :
    _connectionService = FirestoreConnectionService();

  // Initialize SharedPreferences untuk offline storage
  Future<void> _initPrefs() async {
    if (!_prefsInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _prefsInitialized = true;
    }
  }

  // Collection references dengan safety check
  CollectionReference? get users => _connectionService.getCollection('users');
  CollectionReference? get products => _connectionService.getCollection('products');
  CollectionReference? get notifications => _connectionService.getCollection('notifications');
  CollectionReference? get stockLogs => _connectionService.getCollection('stock_logs');
  CollectionReference? get activities => _connectionService.getCollection('activities');

  // Helper method to check admin access
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await getUser(user.uid);
      final role = userData?['role'] ?? 'user';
      if (role != 'admin') {
        throw Exception('Akses ditolak: Fitur ini hanya untuk admin');
      }
    } else {
      throw Exception('Akses ditolak: Silakan login terlebih dahulu');
    }
  }

  // User Operations
  Future<Map<String, dynamic>?> getUser(String userId) async {
    if (users == null) return null;
    final doc = await users!.doc(userId).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    if (users == null) return;
    await users!.doc(userId).update(data);
  }

  // Product Operations
  Stream<List<Product>> getProductsStream() {
    if (products == null) return Stream.value([]);
    return products!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          stock: (data['stock'] ?? 0).toInt(),
          minStock: (data['minStock'] ?? 5).toInt(),
          category: data['category'] ?? '',
          sku: data['sku'],
          imageUrl: data['imageUrl'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdBy: data['createdBy'] ?? '',
          unit: data['unit'] ?? 'pcs',
          volumePerUnit: ((data['volumePerUnit'] ?? 0) as num).toDouble(),
          volumeUnit: data['volumeUnit'] ?? 'm3',
        );
      }).toList();
    });
  }

  Future<List<Product>> getProducts() async {
    if (products == null) return [];
    final snapshot = await products!.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] ?? 0.0).toDouble(),
        stock: (data['stock'] ?? 0).toInt(),
        minStock: (data['minStock'] ?? 5).toInt(),
        category: data['category'] ?? '',
        sku: data['sku'],
        imageUrl: data['imageUrl'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: data['createdBy'] ?? '',
        unit: data['unit'] ?? 'pcs',
        volumePerUnit: ((data['volumePerUnit'] ?? 0) as num).toDouble(),
        volumeUnit: data['volumeUnit'] ?? 'm3',
      );
    }).toList();
  }

  Future<Product?> getProduct(String productId) async {
    if (products == null) return null;
    final doc = await products!.doc(productId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return Product(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        price: (data['price'] ?? 0.0).toDouble(),
        stock: (data['stock'] ?? 0).toInt(),
        minStock: (data['minStock'] ?? 5).toInt(),
        category: data['category'] ?? '',
        sku: data['sku'],
        imageUrl: data['imageUrl'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdBy: data['createdBy'] ?? '',
        unit: data['unit'] ?? 'pcs',
        volumePerUnit: ((data['volumePerUnit'] ?? 0) as num).toDouble(),
        volumeUnit: data['volumeUnit'] ?? 'm3',
      );
    }
    return null;
  }

  Future<void> addProduct(Product product, {required String userId, required String userName}) async {
    if (products == null) return;
    await products!.doc(product.id).set({
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'stock': product.stock,
      'minStock': product.minStock,
      'category': product.category,
      'sku': product.sku,
      'imageUrl': product.imageUrl,
      'createdAt': Timestamp.fromDate(product.createdAt),
      'updatedAt': Timestamp.fromDate(product.updatedAt),
      'createdBy': userId,
      'unit': product.unit,
      'volumePerUnit': product.volumePerUnit,
      'volumeUnit': product.volumeUnit,
    });
    
    // Log activity
    await logActivity(
      userId: userId,
      userName: userName,
      type: 'inventory',
      action: 'add',
      description: 'Tambah produk baru',
      details: {
        ...product.toMap(),
        'qty': product.stock,
        'before': 0,
        'after': product.stock,
      },
    );
  }

  Future<void> updateProduct(Product product, {required String userId, required String userName}) async {
    if (products == null) return;
    final doc = await products!.doc(product.id).get();
    final data = doc.data() as Map<String, dynamic>?;
    final before = (data?['stock'] ?? 0).toInt();
    final after = product.stock;
    await products!.doc(product.id).update({
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'stock': product.stock,
      'minStock': product.minStock,
      'category': product.category,
      'sku': product.sku,
      'imageUrl': product.imageUrl,
      'updatedAt': Timestamp.fromDate(product.updatedAt),
      'unit': product.unit,
      'volumePerUnit': product.volumePerUnit,
      'volumeUnit': product.volumeUnit,
    });
    
    // Log activity
    await logActivity(
      userId: userId,
      userName: userName,
      type: 'inventory',
      action: 'update',
      description: 'Update produk',
      details: {
        ...product.toMap(),
        'qty': after - before,
        'before': before,
        'after': after,
      },
    );
  }

  Future<void> deleteProduct(String productId, {required String userId, required String userName}) async {
    if (products == null) return;
    final product = await getProduct(productId);
    if (product != null) {
      final before = product.stock;
      await products!.doc(productId).delete();
      
      // Log activity
      await logActivity(
        userId: userId,
        userName: userName,
        type: 'inventory',
        action: 'delete',
        description: 'Hapus produk',
        details: {
          ...product.toMap(),
          'qty': 0,
          'before': before,
          'after': 0,
        },
      );
    }
  }

  // Activity Log Operations (standar ke 'activities')
  Stream<QuerySnapshot> getActivityLogs() {
    if (activities == null) return Stream.empty();
    return activities!.orderBy('timestamp', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getUserActivityLogs(String userId) {
    if (activities == null) return Stream.empty();
    return activities!
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> logActivity({
    required String userId,
    required String userName,
    required String type,
    required String action,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    if (activities == null) return;
    await activities!.add({
      'userId': userId,
      'userName': userName,
      'type': type,
      'action': action,
      'description': description,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Notification Operations
  Stream<QuerySnapshot> getNotifications(String userId) {
    if (notifications == null) return Stream.empty();
    return notifications!
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    if (notifications == null) return;
    await notifications!.add({
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNotification(String notificationId, Map<String, dynamic> data) async {
    if (notifications == null) return;
    await notifications!.doc(notificationId).update(data);
  }

  Future<void> deleteNotification(String notificationId) async {
    if (notifications == null) return;
    await notifications!.doc(notificationId).delete();
  }

  Future<void> clearAllNotifications(String userId) async {
    if (_firestore == null || notifications == null) return;
    final batch = _firestore!.batch();
    final snapshot = await notifications!.where('userId', isEqualTo: userId).get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // User-specific Product Stream
  Stream<List<Product>> getUserProductsStream(String userId) {
    if (products == null) return Stream.value([]);
    return products!.where('createdBy', isEqualTo: userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0.0).toDouble(),
          stock: (data['stock'] ?? 0).toInt(),
          minStock: (data['minStock'] ?? 5).toInt(),
          category: data['category'] ?? '',
          sku: data['sku'],
          imageUrl: data['imageUrl'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdBy: data['createdBy'] ?? '',
        );
      }).toList();
    });
  }

  // Add stock log
  Future<void> addStockLog(Map<String, dynamic> log) async {
    if (stockLogs == null) return;
    await stockLogs!.add(log);
  }

  // Get stock logs stream (optionally filter by productId/category/type)
  Stream<List<Map<String, dynamic>>> getStockLogsStream({
    String? productId, 
    String? category, 
    String? type,
    String? warehouseId,
    DateTime? startDate,
  }) {
    if (stockLogs == null) return Stream.value([]);
    Query query = stockLogs!.orderBy('timestamp', descending: true);
    
    // Filter by start date if provided, otherwise use 35 days ago
    final filterDate = startDate ?? DateTime.now().subtract(const Duration(days: 35));
    query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(filterDate));
    
    if (productId != null && productId.isNotEmpty) {
      query = query.where('productId', isEqualTo: productId);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (warehouseId != null && warehouseId.isNotEmpty) {
      query = query.where('warehouseId', isEqualTo: warehouseId);
    }
    
    return query.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
    );
  }

  Future<void> updateStock(String productId, int quantity, {required String userId, required String userName, String? warehouseId}) async {
    final product = await getProduct(productId);
    if (product != null) {
      final before = product.stock;
      final after = before + quantity;
      
      // Validate stock out
      if (quantity < 0 && after < 0) {
        throw Exception('Stok tidak mencukupi');
      }

      // Update stock
      if (products != null) {
        await products!.doc(productId).update({
          'stock': after,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Log stock movement
      await addStockLog({
        'productId': productId,
        'productName': product.name,
        'category': product.category,
        'type': quantity > 0 ? 'in' : 'out',
        'qty': quantity.abs(),
        'before': before,
        'after': after,
        'userId': userId,
        'userName': userName,
        if (warehouseId != null) 'warehouseId': warehouseId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Log activity ONLY for stock changes
      if (quantity != 0) {
        await logActivity(
          userId: userId,
          userName: userName,
          type: 'inventory',
          action: quantity > 0 ? 'stock_in' : 'stock_out',
          description: '${quantity > 0 ? 'Tambah' : 'Kurang'} stok ${product.name}',
          details: {
            'productId': productId,
            'productName': product.name,
            'qty': quantity.abs(),
            'before': before,
            'after': after,
          },
        );
      }

      // Create alerts for low/out of stock ONLY in notifications
      if (after == 0) {
        await addNotification(
          userId: userId,
          title: 'Stok Habis',
          message: 'Produk "${product.name}" stok habis',
          type: 'inventory_alert',
          data: {
            'productId': productId,
            'productName': product.name,
            'stock': after,
            'minStock': product.minStock,
          },
        );
      } else if (after <= product.minStock && after > 0) {
        await addNotification(
          userId: userId,
          title: 'Stok Menipis',
          message: 'Produk "${product.name}" stok menipis (${after}/${product.minStock})',
          type: 'inventory_alert',
          data: {
            'productId': productId,
            'productName': product.name,
            'stock': after,
            'minStock': product.minStock,
          },
        );
      }
    }
  }

  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? productId,
  }) async {
    if (_firestore == null) return [];
    Query query = _firestore!.collection('transactions');
    
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    if (type != null) {
      query = query.where('type', isEqualTo: type.toString());
    }
    
    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    }
    
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStockLogs({
    String? productId,
    DateTime? startDate,
  }) async {
    if (_firestore == null) return [];
    Query query = _firestore!.collection('stock_logs')
        .orderBy('timestamp', descending: true);
    
    if (productId != null) {
      query = query.where('productId', isEqualTo: productId);
    }
    
    if (startDate != null) {
      query = query.where('timestamp', 
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    }).toList();
  }

  Future<void> cleanupAllData({required String userId, required String userName}) async {
    await _checkAdminAccess();
    if (_firestore == null) return;
    final batch = _firestore!.batch();
    
    try {
      // 1. Reset Finance Data
      batch.set(_firestore!.collection('finance').doc('balance'), {
        'kasUtama': 0.0,
        'bank': 0.0
      });

      // 2. Clear Collections
      final collections = [
        'transactions',      // Sales & Purchase transactions
        'finance_transactions', // Manual finance transactions
        'finance_logs',     // Finance logs
        'notifications',    // All notifications
        'activities',       // Activity logs
        'products',         // Product data
        'categories',       // Product categories
        'customers',        // Customer data
        'suppliers',        // Supplier data
        'budgets',         // Financial budgets
      ];

      for (var collectionName in collections) {
        final snapshot = await _firestore!.collection(collectionName).get();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // 3. Commit all changes
      await batch.commit();

      // 4. Log the cleanup
      await logActivity(
        userId: userId,
        userName: userName,
        type: 'system',
        action: 'cleanup_data',
        description: 'Reset seluruh data sistem',
        details: {
          'collections_cleared': collections,
          'timestamp': DateTime.now().toIso8601String(),
          'performed_by': userName,
        },
      );

    } catch (e) {
      print('Error during data cleanup: $e');
      rethrow;
    }
  }
}