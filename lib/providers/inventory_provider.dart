import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class InventoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _products = [];
  int _lowStockCount = 0;
  int _outOfStockCount = 0;

  List<Map<String, dynamic>> get products => _products;
  int get lowStockCount => _lowStockCount;
  int get outOfStockCount => _outOfStockCount;

  Future<void> loadProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('name')
          .get();

      _products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((p) => p['isDeleted'] != true).toList();

      _calculateStockStatus();
      
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
      rethrow;
    }
  }

  void _calculateStockStatus() {
    _lowStockCount = 0;
    _outOfStockCount = 0;
    for (var product in _products) {
      final stock = (product['stock'] ?? 0).toInt();
      final minStock = (product['minStock'] ?? 5).toInt();
      if (stock == 0) {
        _outOfStockCount++;
      } else if (stock <= minStock) {
        _lowStockCount++;
      }
    }
  }

  Stream<QuerySnapshot> getProductStream() {
    return _firestore
        .collection('products')
        .orderBy('name')
        .snapshots();
  }

  Future<void> addProduct(Map<String, dynamic> product, {required String userId, required String userName}) async {
    try {
      final docRef = await _firestore.collection('products').add({
        ...product,
        'timestamp': FieldValue.serverTimestamp(),
        'createdBy': userId,
        'createdByName': userName,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'inventory',
        action: 'add',
        description: 'Tambah produk baru',
        details: {
          'productId': docRef.id,
          'name': product['name'],
          'qty': product['stock'] ?? 0,
          'before': 0,
          'after': product['stock'] ?? 0,
        },
      );

      await loadProducts();
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data, {required String userId, required String userName}) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      final before = (doc.data()?['stock'] ?? 0).toInt();
      final after = (data['stock'] ?? before).toInt();

      await _firestore.collection('products').doc(id).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userId,
        'updatedByName': userName,
      });

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'inventory',
        action: 'update',
        description: 'Update produk',
        details: {
          'productId': id,
          'name': data['name'],
          'qty': after - before,
          'before': before,
          'after': after,
        },
      );

      await loadProducts();
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id, {required String userId, required String userName}) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      final before = (doc.data()?['stock'] ?? 0).toInt();

      await _firestore.collection('products').doc(id).delete();

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'inventory',
        action: 'delete',
        description: 'Hapus produk',
        details: {
          'productId': id,
          'name': doc.data()?['name'],
          'qty': 0,
          'before': before,
          'after': 0,
        },
      );

      await loadProducts();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> updateStock(String id, int quantity, {required String userId, required String userName}) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      final before = (doc.data()?['stock'] ?? 0).toInt();
      final after = before + quantity;

        if (after < 0) {
          throw Exception('Stok tidak boleh negatif!');
        }

        await _firestore.collection('products').doc(id).update({
          'stock': after,
          'lastUpdated': FieldValue.serverTimestamp(),
          'updatedBy': userId,
          'updatedByName': userName,
        });

      // Log activity for stock update
        await _firestoreService.logActivity(
          userId: userId,
          userName: userName,
          type: 'inventory',
          action: 'update_stock',
          description: 'Update stok produk',
          details: {
            'productId': id,
            'name': doc.data()?['name'],
            'qty': quantity,
          'before': before,
            'after': after,
          },
        );

        await loadProducts();
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }
} 
 