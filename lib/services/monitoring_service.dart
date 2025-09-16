import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_model.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import 'firestore_service.dart';
import 'package:rxdart/rxdart.dart';

class MonitoringService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  MonitoringService() : 
    _firestore = FirebaseFirestore.instance,
    _firestoreService = FirestoreService();

  MonitoringService.withFirestore(FirebaseFirestore firestore) :
    _firestore = firestore,
    _firestoreService = FirestoreService.withFirestore(firestore);

  // Collections
  CollectionReference get _notifications => _firestore.collection('notifications');
  CollectionReference get _activities => _firestore.collection('activities');
  CollectionReference get _transactions => _firestore.collection('transactions');
  CollectionReference get _finance => _firestore.collection('finance');

  // Get transactions stream
  Stream<List<TransactionModel>> getTransactionsStream() {
    return _transactions.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList()
    );
  }

  // Get balance stream
  Stream<FinanceBalance> getBalanceStream() {
    return _finance.doc('balance').snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return FinanceBalance(
        kasUtama: (data?['kasUtama'] ?? 0.0).toDouble(),
        bank: (data?['bank'] ?? 0.0).toDouble(),
      );
    });
  }

  // Create alert
  Future<void> createAlert({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? details,
  }) async {
    await _notifications.add({
      'type': type,
      'title': title,
      'message': message,
      'details': details,
      'isRead': false,
      'timestamp': Timestamp.now(),
    });
  }

  // Create activity log
  Future<void> logActivity({
    required String type,
    required String action,
    required String userId,
    required String userName,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    await _activities.add({
      'type': type,
      'action': action,
      'userId': userId,
      'userName': userName,
      'description': description,
      'details': details,
      'timestamp': Timestamp.now(),
    });
  }

  // Check low stock and create alerts
  Future<void> checkLowStock(Map<String, dynamic> product) async {
    final stock = (product['stock'] ?? 0) as int;
    final minStock = (product['minStock'] ?? 5) as int;
    if (stock <= minStock) {
      await createAlert(
        type: 'Inventory',
        title: 'Stok menipis',
        message: 'Stok produk "${product['name']}" hanya $stock (min: $minStock)',
        details: product,
      );
    }
  }

  // Check low balance and create alert
  Future<void> checkLowBalance(FinanceBalance balance) async {
    if (balance.kasUtama < 100000) {
      await createAlert(
        type: 'Finance',
        title: 'Saldo Kritis',
        message: 'Saldo kas utama di bawah Rp 100.000 (Saat ini: ${balance.kasUtama})',
        details: balance.toMap(),
      );
    }
  }

  // Get unread notifications count including automatic alerts
  Stream<int> getUnreadNotificationsCount() {
    // Stream for manual notifications from Firestore
    final manualNotificationsStream = _notifications
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);

    // Stream for automatic alerts
    final automaticAlertsStream = Rx.combineLatest3<List<Product>, List<TransactionModel>, FinanceBalance, int>(
      _firestoreService.getProductsStream(),
      getTransactionsStream(),
      getBalanceStream(),
      (products, transactions, balance) {
        int count = 0;

        // Check low stock products
        for (var product in products) {
          if (product.stock <= product.minStock) count++;
        }

        // Check failed transactions
        for (var transaction in transactions) {
          if (transaction.deliveryStatus == DeliveryStatus.canceled) count++;
        }

        // Check low balance
        if (balance.kasUtama < 100000) count++;

        return count;
      }
    );

    // Combine both streams
    return Rx.combineLatest2<int, int, int>(
      manualNotificationsStream,
      automaticAlertsStream,
      (manualCount, autoCount) => manualCount + autoCount
    );
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  // Get activities stream
  Stream<List<Map<String, dynamic>>> getActivitiesStream({
    String? type,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _activities.orderBy('timestamp', descending: true);
    
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snap) => 
      snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList()
    );
  }
} 