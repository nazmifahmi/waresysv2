import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class FinanceService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;
  final AuthService _authService;

  FinanceService() : 
    _firestore = FirebaseFirestore.instance,
    _firestoreService = FirestoreService(),
    _authService = AuthService();

  FinanceService.withFirestore(FirebaseFirestore firestore) :
    _firestore = firestore,
    _firestoreService = FirestoreService.withFirestore(firestore),
    _authService = AuthService();

  CollectionReference get _trxCol => _firestore.collection('finance_transactions');
  DocumentReference get _balanceDoc => _firestore.collection('finance').doc('balance');
  CollectionReference get _logCol => _firestore.collection('finance_balance_logs');
  CollectionReference get _budgetCol => _firestore.collection('finance_budgets');

  // Helper method to check admin status
  Future<void> _checkAdminAccess() async {
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin) {
      throw Exception('Akses ditolak: Fitur ini hanya untuk admin');
    }
  }

  // Stream saldo
  Stream<FinanceBalance> getBalanceStream() {
    return _balanceDoc.snapshots().map((snap) =>
      snap.exists ? FinanceBalance.fromMap(snap.data() as Map<String, dynamic>) : FinanceBalance(kasUtama: 0, bank: 0));
  }

  // Stream transaksi
  Stream<List<FinanceTransaction>> getTransactionsStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('finance_transactions')
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      // Add one day to include the end date fully
      final endDateTime = endDate.add(const Duration(days: 1));
      query = query.where('date', isLessThan: Timestamp.fromDate(endDateTime));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Filter out auto-generated finance records from sales/purchase in Other Income/Expense
            if (data['category'] == 'Penjualan (Sales)' || data['category'] == 'Pembelian (Purchase)') {
              return false;
            }
            return true;
          })
          .map((doc) => FinanceTransaction.fromFirestore(doc))
          .toList();
    });
  }

  // Get transactions for specific type (income/expense)
  Stream<List<FinanceTransaction>> getTransactionsByTypeStream({
    required FinanceTransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('finance_transactions')
        .where('type', isEqualTo: type.name)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      final endDateTime = endDate.add(const Duration(days: 1));
      query = query.where('date', isLessThan: Timestamp.fromDate(endDateTime));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Filter out auto-generated finance records from sales/purchase in Other Income/Expense
            if (data['category'] == 'Penjualan (Sales)' || data['category'] == 'Pembelian (Purchase)') {
              return false;
            }
            return true;
          })
          .map((doc) => FinanceTransaction.fromFirestore(doc))
          .toList();
    });
  }

  // Tambah transaksi (income/expense)
  Future<void> addTransaction(FinanceTransaction trx, {required double currentKas, required String userId, required String userName}) async {
    final batch = _firestore.batch();
    final trxRef = _trxCol.doc(trx.id);
    final isIncome = trx.type == FinanceTransactionType.income;
    final before = currentKas;
    final after = isIncome ? before + trx.amount : before - trx.amount;
    if (!isIncome && after < 0) throw Exception('Saldo tidak cukup!');
    
    // Add transaction
    batch.set(trxRef, trx.toMap());
    
    // Update balance
    batch.set(_balanceDoc, {'kasUtama': after}, SetOptions(merge: true));
    
    // Add balance log
    final logId = DateTime.now().millisecondsSinceEpoch.toString();
    batch.set(_logCol.doc(logId), FinanceBalanceLog(
      id: logId,
      before: before,
      after: after,
      userId: userId,
      userName: userName,
      date: DateTime.now(),
      note: '${isIncome ? "Pemasukan" : "Pengeluaran"} - ${trx.category} dengan deskripsi ${trx.description}',
    ).toMap());
    
    await batch.commit();
    
    // Log ke activities
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: isIncome ? 'income' : 'expense',
      description: '${isIncome ? "Pemasukan" : "Pengeluaran"} - ${trx.category}',
      details: trx.toMap(),
    );
  }

  // Hapus transaksi (rollback saldo)
  Future<void> deleteTransaction(FinanceTransaction trx, {required double currentKas, required String userId, required String userName}) async {
    final batch = _firestore.batch();
    final trxRef = _trxCol.doc(trx.id);
    final isIncome = trx.type == FinanceTransactionType.income;
    final before = currentKas;
    final after = isIncome ? before - trx.amount : before + trx.amount;
    batch.delete(trxRef);
    batch.set(_balanceDoc, {'kasUtama': after}, SetOptions(merge: true));
    batch.set(_logCol.doc('${trx.id}_del'), FinanceBalanceLog(
      id: '${trx.id}_del',
      before: before,
      after: after,
      userId: userId,
      userName: userName,
      date: DateTime.now(),
      note: 'Rollback: ${isIncome ? 'Hapus pemasukan' : 'Hapus pengeluaran'}',
    ).toMap());
    await batch.commit();
    // Log ke activities
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: isIncome ? 'delete_income' : 'delete_expense',
      description: isIncome ? 'Hapus pemasukan kas utama' : 'Hapus pengeluaran kas utama',
      details: trx.toMap(),
    );
  }

  // Edit transaksi (hanya deskripsi/kategori, tidak nominal)
  Future<void> updateTransaction(FinanceTransaction trx) async {
    await _trxCol.doc(trx.id).update(trx.toMap());
  }

  // Stream log saldo
  Stream<List<FinanceBalanceLog>> getBalanceLogsStream() {
    return _logCol.orderBy('date', descending: true).snapshots().map((snap) =>
      snap.docs.map((doc) => FinanceBalanceLog.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  // Get saldo sekali
  Future<FinanceBalance> getBalance() async {
    final snap = await _balanceDoc.get();
    if (!snap.exists) return FinanceBalance(kasUtama: 0, bank: 0);
    return FinanceBalance.fromMap(snap.data() as Map<String, dynamic>);
  }

  // List kategori default
  List<String> getCategories() {
    return [
      'Penjualan',
      'Pembelian',
      'Bayar Hutang',
      'Bayar Piutang',
      'Operasional',
      'Lainnya',
    ];
  }

  // Stream budgets per bulan/tahun
  Stream<List<FinanceBudget>> getBudgetsStream({int? month, int? year}) {
    Query q = _budgetCol;
    if (month != null) q = q.where('month', isEqualTo: month);
    if (year != null) q = q.where('year', isEqualTo: year);
    return q.snapshots().map((snap) =>
      snap.docs.map((doc) => FinanceBudget.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> addBudget(FinanceBudget budget, {required String userId, required String userName}) async {
    await _budgetCol.doc(budget.id).set(budget.toMap());
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: 'add_budget',
      description: 'Tambah anggaran',
      details: budget.toMap(),
    );
  }

  Future<void> updateBudget(FinanceBudget budget, {required String userId, required String userName}) async {
    await _budgetCol.doc(budget.id).update(budget.toMap());
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: 'update_budget',
      description: 'Update anggaran',
      details: budget.toMap(),
    );
  }

  Future<void> deleteBudget(String id, {required String userId, required String userName}) async {
    final doc = await _budgetCol.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      await _budgetCol.doc(id).delete();
      await _firestoreService.logActivity(
        userId: userId,
        userName: userName,
        type: 'finance',
        action: 'delete_budget',
        description: 'Hapus anggaran',
        details: data,
      );
    }
  }

  Future<void> updateBalance(double newSaldo, {required String userId, required String userName}) async {
    await _checkAdminAccess();
    await _balanceDoc.set({'kasUtama': newSaldo}, SetOptions(merge: true));
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: 'update_balance',
      description: 'Update saldo kas utama',
      details: {'kasUtama': newSaldo},
    );
  }

  Future<void> addBalanceLog(FinanceBalanceLog log, {required String userId, required String userName, String? action, String? description}) async {
    await _logCol.add(log.toMap());
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: action ?? 'balance_log',
      description: description ?? 'Log saldo kas utama',
      details: log.toMap(),
    );
  }

  Future<void> cleanupFinanceData({required String userId, required String userName}) async {
    await _checkAdminAccess();
    final batch = _firestore.batch();
    
    // 1. Reset saldo ke 0
    batch.set(_balanceDoc, {'kasUtama': 0.0, 'bank': 0.0});
    
    // 2. Hapus semua transaksi keuangan manual
    final trxSnap = await _trxCol.get();
    for (var doc in trxSnap.docs) {
      batch.delete(doc.reference);
    }
    
    // 3. Hapus semua log saldo
    final logSnap = await _logCol.get();
    for (var doc in logSnap.docs) {
      batch.delete(doc.reference);
    }

    // 4. Hapus atau update transaksi sales/purchase yang mempengaruhi keuangan
    final salesSnap = await _firestore.collection('transactions')
      .where('type', isEqualTo: 'sales')
      .where('paymentStatus', isEqualTo: 'paid')
      .get();
    
    final purchaseSnap = await _firestore.collection('transactions')
      .where('type', isEqualTo: 'purchase')
      .where('paymentStatus', isEqualTo: 'paid')
      .get();
    
    // Update status pembayaran menjadi unpaid untuk transaksi yang sudah paid
    for (var doc in [...salesSnap.docs, ...purchaseSnap.docs]) {
      batch.update(doc.reference, {
        'paymentStatus': 'unpaid',
        'updatedAt': Timestamp.now(),
        'logHistory': FieldValue.arrayUnion([{
          'action': 'update_status',
          'userId': userId,
          'userName': userName,
          'timestamp': Timestamp.now(),
          'note': 'Reset status pembayaran karena pembersihan data keuangan',
        }]),
      });
    }
    
    // 5. Commit semua perubahan
    await batch.commit();
    
    // 6. Buat log baru untuk reset data
    await addBalanceLog(
      FinanceBalanceLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        before: 0,
        after: 0,
        userId: userId,
        userName: userName,
        date: DateTime.now(),
        note: 'Reset data keuangan',
      ),
      userId: userId,
      userName: userName,
      action: 'reset_data',
      description: 'Reset seluruh data keuangan'
    );

    // 7. Log aktivitas global
    await _firestoreService.logActivity(
      userId: userId,
      userName: userName,
      type: 'finance',
      action: 'cleanup_data',
      description: 'Pembersihan data keuangan',
      details: {
        'manual_transactions_deleted': trxSnap.docs.length,
        'logs_deleted': logSnap.docs.length,
        'sales_reset': salesSnap.docs.length,
        'purchases_reset': purchaseSnap.docs.length,
      },
    );
  }
} 