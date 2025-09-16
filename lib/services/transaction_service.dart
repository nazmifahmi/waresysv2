import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import '../models/finance_model.dart';
import 'firestore_service.dart';
import 'finance_service.dart';

class TransactionService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;
  final FinanceService _financeService;

  TransactionService() : 
    _firestore = FirebaseFirestore.instance,
    _firestoreService = FirestoreService(),
    _financeService = FinanceService();

  TransactionService.withFirestore(FirebaseFirestore firestore) :
    _firestore = firestore,
    _firestoreService = FirestoreService.withFirestore(firestore),
    _financeService = FinanceService.withFirestore(firestore);

  CollectionReference get transactions => _firestore.collection('transactions');

  // Stream semua transaksi (bisa difilter di query)
  Stream<List<TransactionModel>> getTransactionsStream({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('transactions')
        .where('type', isEqualTo: type.name)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true);

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      // Add one day to include the end date fully
      final endDateTime = endDate.add(const Duration(days: 1));
      query = query.where('createdAt', isLessThan: Timestamp.fromDate(endDateTime));
    }

    return query.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList()
    );
  }

  // Tambah transaksi baru (update stok, log)
  Future<void> addTransaction(TransactionModel trx, {required String userId, required String userName}) async {
    final batch = _firestore.batch();
    final docRef = transactions.doc(trx.id);
    
    // Ensure all required fields are set
    final transactionData = {
      ...trx.toMap(),
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    batch.set(docRef, transactionData);
    
    // Update stok produk
    for (final item in trx.items) {
      final productRef = _firestore.collection('products').doc(item.productId);
      final productSnap = await productRef.get();
      if (productSnap.exists) {
        final data = productSnap.data() as Map<String, dynamic>;
        int stock = (data['stock'] ?? 0) as int;
        int newStock = trx.type == TransactionType.sales
            ? stock - item.quantity
            : stock + item.quantity;
        if (trx.type == TransactionType.sales && item.quantity > stock) {
          throw Exception('Stok produk ${item.productName} tidak cukup!');
        }
        batch.update(productRef, {
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();

    // Create finance record if transaction is paid
    if (trx.paymentStatus == PaymentStatus.paid) {
      final balance = await _financeService.getBalance();
      await _financeService.addTransaction(
        FinanceTransaction(
          id: 'trx_${trx.id}',
          type: trx.type == TransactionType.sales ? FinanceTransactionType.income : FinanceTransactionType.expense,
          category: trx.type == TransactionType.sales ? 'Penjualan (Sales)' : 'Pembelian (Purchase)',
          amount: trx.total,
          description: '${trx.type == TransactionType.sales ? "Penjualan" : "Pembelian"} - ${trx.customerSupplierName}',
          date: DateTime.now(),
          createdBy: userId,
        ),
        currentKas: balance.kasUtama,
        userId: userId,
        userName: userName,
      );
    }

    // Logging global
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'transaction',
      action: 'create',
      description: 'Transaksi baru dibuat',
      details: trx.toMap(),
    );
  }

  // Update transaksi (status, log, dsb)
  Future<void> updateTransaction(TransactionModel trx, {required String userId, required String userName}) async {
    await transactions.doc(trx.id).update(trx.toMap());
    // Logging global
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'transaction',
      action: 'update',
      description: 'Transaksi diupdate',
      details: trx.toMap(),
    );
  }

  // Soft delete/cancel transaksi (kembalikan stok jika perlu)
  Future<void> cancelTransaction(TransactionModel trx, String userId, String userName) async {
    final batch = _firestore.batch();
    final docRef = transactions.doc(trx.id);
    // Kembalikan stok jika transaksi sales (stok keluar dikembalikan), purchase (stok masuk dikurangi)
    for (final item in trx.items) {
      final productRef = _firestore.collection('products').doc(item.productId);
      final productSnap = await productRef.get();
      if (productSnap.exists) {
        final data = productSnap.data() as Map<String, dynamic>;
        int stock = (data['stock'] ?? 0) as int;
        int newStock = trx.type == TransactionType.sales
            ? stock + item.quantity
            : stock - item.quantity;
        batch.update(productRef, {
          'stock': newStock,
          'updatedAt': Timestamp.now(),
        });
      }
    }
    // Update status transaksi
    final updatedLog = List<TransactionLog>.from(trx.logHistory)
      ..add(TransactionLog(
        action: 'cancel',
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
        note: 'Transaksi dibatalkan',
      ));
    batch.update(docRef, {
      'isDeleted': true,
      'deliveryStatus': DeliveryStatus.canceled.name,
      'logHistory': updatedLog.map((e) => e.toMap()).toList(),
      'updatedAt': Timestamp.now(),
    });
    await batch.commit();
    // Logging global
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'transaction',
      action: 'cancel',
      description: 'Transaksi dibatalkan',
      details: trx.toMap(),
    );
  }

  // Update status pembayaran/pengiriman
  Future<void> updateStatus({
    required String trxId,
    PaymentStatus? paymentStatus,
    DeliveryStatus? deliveryStatus,
    String? trackingNumber,
    required String userId,
    required String userName,
    String? note,
  }) async {
    final docRef = transactions.doc(trxId);
    final doc = await docRef.get();
    if (!doc.exists) throw Exception('Transaksi tidak ditemukan');
    
    final trx = TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
    
    // Validate kas utama balance if changing to paid status
    if (paymentStatus == PaymentStatus.paid && trx.paymentStatus == PaymentStatus.unpaid) {
      final balance = await _financeService.getBalance();
      
      // For purchase transactions, check if kas utama is sufficient
      if (trx.type == TransactionType.purchase && balance.kasUtama < trx.total) {
        throw Exception('Saldo kas utama tidak mencukupi untuk pembayaran pembelian ini!');
      }
    }

    final updatedLog = [...trx.logHistory];
    updatedLog.add(TransactionLog(
      action: 'update_status',
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      note: note ?? 'Status transaksi diupdate',
    ));

    final batch = _firestore.batch();

    // Update transaction status
    batch.update(docRef, {
      if (paymentStatus != null) 'paymentStatus': paymentStatus.name,
      if (deliveryStatus != null) 'deliveryStatus': deliveryStatus.name,
      if (trackingNumber != null) 'trackingNumber': trackingNumber,
      'logHistory': updatedLog.map((e) => e.toMap()).toList(),
      'updatedAt': Timestamp.now(),
    });

    // Create finance record if status changed to paid
    if (paymentStatus == PaymentStatus.paid && trx.paymentStatus == PaymentStatus.unpaid) {
      final balance = await _financeService.getBalance();
      
      // Add finance transaction
      final financeTransaction = FinanceTransaction(
        id: 'trx_${trx.id}',
        type: trx.type == TransactionType.sales ? FinanceTransactionType.income : FinanceTransactionType.expense,
        category: trx.type == TransactionType.sales ? 'Penjualan (Sales)' : 'Pembelian (Purchase)',
        amount: trx.total,
        description: '${trx.type == TransactionType.sales ? "Penjualan" : "Pembelian"} - ${trx.customerSupplierName}',
        date: DateTime.now(),
        createdBy: userId,
      );

      // Update balance in the same batch
      final newBalance = trx.type == TransactionType.sales 
        ? balance.kasUtama + trx.total 
        : balance.kasUtama - trx.total;

      batch.set(_firestore.collection('finance').doc('balance'), 
        {'kasUtama': newBalance}, 
        SetOptions(merge: true)
      );

      // Add finance transaction record
      batch.set(
        _firestore.collection('finance_transactions').doc(financeTransaction.id),
        financeTransaction.toMap()
      );

      // Add balance log
      final logId = DateTime.now().millisecondsSinceEpoch.toString();
      batch.set(
        _firestore.collection('finance_balance_logs').doc(logId),
        FinanceBalanceLog(
          id: logId,
          before: balance.kasUtama,
          after: newBalance,
          userId: userId,
          userName: userName,
          date: DateTime.now(),
          note: '${trx.type == TransactionType.sales ? "Pemasukan" : "Pengeluaran"} dari transaksi ${trx.type.name}',
        ).toMap()
      );
    }

    // Commit all changes
    await batch.commit();

    // Logging global
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'transaction',
      action: 'update_status',
      description: 'Status transaksi diupdate',
      details: trx.toMap(),
    );
  }

  // Get transaksi by ID
  Future<TransactionModel?> getTransaction(String id) async {
    final doc = await transactions.doc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
  }
} 