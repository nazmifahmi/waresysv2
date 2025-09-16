import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:waresys_fix1/models/transaction_model.dart';
import 'package:waresys_fix1/models/finance_model.dart';
import 'package:waresys_fix1/services/transaction_service.dart';
import 'package:waresys_fix1/services/finance_service.dart';
import 'package:waresys_fix1/services/firestore_service.dart';
import 'package:waresys_fix1/services/monitoring_service.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late TransactionService transactionService;
  late FinanceService financeService;
  late FirestoreService firestoreService;
  late MonitoringService monitoringService;
  late MockUser mockUser;

  setUp(() async {
    await setupFirebaseForTesting();
    fakeFirestore = getFakeFirestore();
    transactionService = TransactionService.withFirestore(fakeFirestore);
    financeService = FinanceService.withFirestore(fakeFirestore);
    firestoreService = FirestoreService.withFirestore(fakeFirestore);
    monitoringService = MonitoringService.withFirestore(fakeFirestore);
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );
  });

  group('Monitoring Integration Tests', () {
    test('Activity Logging - Transaction Creates Activity Log', () async {
      // Create a transaction
      final transaction = TransactionModel(
        id: 'test-transaction-1',
        type: TransactionType.sales,
        customerSupplierId: 'customer-1',
        customerSupplierName: 'Test Customer',
        items: [
          TransactionItem(
            productId: 'product-1',
            productName: 'Test Product',
            quantity: 2,
            price: 10000,
            subtotal: 20000,
          ),
        ],
        total: 20000,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.pending,
        logHistory: [],
        createdBy: mockUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add product with stock
      await fakeFirestore.collection('products').doc('product-1').set({
        'id': 'product-1',
        'name': 'Test Product',
        'stock': 10,
      });

      // Log activity
      await monitoringService.logActivity(
        type: 'transaction',
        action: 'create',
        userId: mockUser.uid,
        userName: mockUser.displayName!,
        description: 'New transaction created',
        details: transaction.toMap(),
      );

      // Verify activity log created
      final activityQuery = await fakeFirestore
          .collection('activities')
          .where('type', isEqualTo: 'transaction')
          .get();
      
      expect(activityQuery.docs.isNotEmpty, true);
      final activityDoc = activityQuery.docs.first;
      expect(activityDoc.data()['userId'], mockUser.uid);
      expect(activityDoc.data()['userName'], mockUser.displayName);
    });

    test('Alert System - Low Stock Creates Alert', () async {
      // Add product with low stock
      final product = {
        'id': 'low-stock-1',
        'name': 'Low Stock Product',
        'stock': 3,
        'minStock': 5,
      };

      // Create alert for low stock
      await monitoringService.checkLowStock(product);

      // Verify alert created
      final alertQuery = await fakeFirestore
          .collection('notifications')
          .where('type', isEqualTo: 'Inventory')
          .where('title', isEqualTo: 'Stok menipis')
          .get();
      
      expect(alertQuery.docs.isNotEmpty, true);
      final alertDoc = alertQuery.docs.first;
      expect(alertDoc.data()['message'].contains('Low Stock Product'), true);
    });

    test('Alert System - Low Balance Creates Alert', () async {
      // Create low balance
      final balance = FinanceBalance(kasUtama: 50000, bank: 0);

      // Create alert for low balance
      await monitoringService.checkLowBalance(balance);

      // Verify alert created
      final alertQuery = await fakeFirestore
          .collection('notifications')
          .where('type', isEqualTo: 'Finance')
          .where('title', isEqualTo: 'Saldo Kritis')
          .get();
      
      expect(alertQuery.docs.isNotEmpty, true);
      final alertDoc = alertQuery.docs.first;
      expect(alertDoc.data()['message'].contains('di bawah Rp 100.000'), true);
    });

    test('Activity Log - Finance Transaction Creates Activity', () async {
      // Create finance transaction
      final financeTransaction = FinanceTransaction(
        id: 'test-finance-1',
        type: FinanceTransactionType.expense,
        category: 'Operasional',
        amount: 50000,
        description: 'Test expense',
        date: DateTime.now(),
        createdBy: mockUser.uid,
      );

      // Log activity
      await monitoringService.logActivity(
        type: 'finance',
        action: 'create',
        userId: mockUser.uid,
        userName: mockUser.displayName!,
        description: 'New finance transaction created',
        details: financeTransaction.toMap(),
      );

      // Verify activity log created
      final activityQuery = await fakeFirestore
          .collection('activities')
          .where('type', isEqualTo: 'finance')
          .get();
      
      expect(activityQuery.docs.isNotEmpty, true);
      final activityDoc = activityQuery.docs.first;
      expect(activityDoc.data()['userId'], mockUser.uid);
      expect(activityDoc.data()['userName'], mockUser.displayName);
    });

    test('Activity Log - Inventory Update Creates Activity', () async {
      // Create product first
      await fakeFirestore.collection('products').doc('product-1').set({
        'id': 'product-1',
        'name': 'Test Product',
        'stock': 10,
      });

      // Log activity for stock update
      await monitoringService.logActivity(
        type: 'inventory',
        action: 'update',
        userId: mockUser.uid,
        userName: mockUser.displayName!,
        description: 'Stock updated',
        details: {'productId': 'product-1', 'oldStock': 10, 'newStock': 15},
      );

      // Verify activity log created
      final activityQuery = await fakeFirestore
          .collection('activities')
          .where('type', isEqualTo: 'inventory')
          .get();
      
      expect(activityQuery.docs.isNotEmpty, true);
      final activityDoc = activityQuery.docs.first;
      expect(activityDoc.data()['action'], 'update');
    });
  });
} 