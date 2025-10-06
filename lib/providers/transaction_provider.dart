import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waresys_fix1/utils/currency_formatter.dart';
import 'package:waresys_fix1/services/firestore_service.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _transactions = [];
  double _totalSales = 0;
  double _totalPurchases = 0;
  int _failedTransactions = 0;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> get transactions => _transactions;
  double get totalSales => _totalSales;
  double get totalPurchases => _totalPurchases;
  int get failedTransactions => _failedTransactions;

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      Query query = _firestore
          .collection('transactions')
          .orderBy('timestamp', descending: true);

      // Add date range filter if set
      if (_startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      }
      if (_endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
      }

      final snapshot = await query.get();

      _transactions = snapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data == null || data is! Map<String, dynamic>) return null;
            return {
              ...data,
              'id': doc.id,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      _calculateTotals();
      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
      rethrow;
    }
  }

  void _calculateTotals() {
    _totalSales = 0;
    _totalPurchases = 0;
    _failedTransactions = 0;

    for (var transaction in _transactions) {
      if (transaction['status'] == 'failed') {
        _failedTransactions++;
        continue;
      }

      if (transaction['type'] == 'sale') {
        _totalSales += (transaction['total'] ?? 0).toDouble();
      } else if (transaction['type'] == 'purchase') {
        _totalPurchases += (transaction['total'] ?? 0).toDouble();
      }
    }
  }

  Stream<QuerySnapshot> getTransactionStream() {
    Query query = _firestore
        .collection('transactions')
        .orderBy('timestamp', descending: true);

    // Add date range filter if set
    if (_startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }
    if (_endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
    }

    return query.snapshots();
  }

  Future<void> addTransaction(Map<String, dynamic> transaction, {required String userId, required String userName}) async {
    try {
      final docRef = await _firestore.collection('transactions').add({
        ...transaction,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'success',
        'createdBy': userId,
        'createdByName': userName,
      });

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'transaction',
        action: 'create',
        description: 'Transaksi baru dibuat',
        details: {
          'transactionId': docRef.id,
          'type': transaction['type'],
          'total': transaction['total'],
          'items': transaction['items'],
        },
      );

      await loadTransactions();
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data, {required String userId, required String userName}) async {
    try {
      await _firestore.collection('transactions').doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
        'updatedByName': userName,
      });

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'transaction',
        action: 'update',
        description: 'Transaksi diupdate',
        details: {
          'transactionId': id,
          'updates': data,
        },
      );

      await loadTransactions();
    } catch (e) {
      print('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id, {required String userId, required String userName}) async {
    try {
      await _firestore.collection('transactions').doc(id).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
        'deletedByName': userName,
      });

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'transaction',
        action: 'delete',
        description: 'Transaksi dihapus',
        details: {
          'transactionId': id,
        },
      );

      await loadTransactions();
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  Future<void> markTransactionFailed(String id, String reason, {required String userId, required String userName}) async {
    try {
      await _firestore.collection('transactions').doc(id).update({
        'status': 'failed',
        'failureReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
        'updatedByName': userName,
      });

      // Log activity
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'transaction',
        action: 'failed',
        description: 'Transaksi gagal',
        details: {
          'transactionId': id,
          'reason': reason,
        },
      );

      await loadTransactions();
    } catch (e) {
      print('Error marking transaction as failed: $e');
      rethrow;
    }
  }
} 
 