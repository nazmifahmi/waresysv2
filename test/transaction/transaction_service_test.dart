import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:waresys_fix1/models/transaction_model.dart';
import 'package:waresys_fix1/services/transaction_service.dart';
import 'package:waresys_fix1/services/firestore_service.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late TransactionService transactionService;
  late FirestoreService firestoreService;
  late MockUser mockUser;

  setUp(() async {
    await setupFirebaseForTesting();
    fakeFirestore = getFakeFirestore();
    transactionService = TransactionService.withFirestore(fakeFirestore);
    firestoreService = FirestoreService.withFirestore(fakeFirestore);
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );
  });

  group('TransactionService Tests', () {
    test('Add Sales Transaction', () async {
      // Setup test data
      final transaction = TransactionModel(
        id: 'test-transaction-1',
        type: TransactionType.sales,
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

      // Add product with initial stock
      await fakeFirestore.collection('products').doc('product-1').set({
        'id': 'product-1',
        'name': 'Test Product',
        'stock': 10,
      });

      // Execute
      await transactionService.addTransaction(
        transaction,
        userId: mockUser.uid,
        userName: mockUser.displayName!,
      );

      // Verify
      final transactionDoc = await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .get();
      expect(transactionDoc.exists, true);

      // Verify stock update
      final productDoc = await fakeFirestore
          .collection('products')
          .doc('product-1')
          .get();
      expect(productDoc.data()?['stock'], 8); // 10 - 2
    });

    test('Update Transaction Status', () async {
      // Setup test transaction
      final transaction = TransactionModel(
        id: 'test-transaction-2',
        type: TransactionType.sales,
        customerSupplierName: 'Test Customer',
        items: [],
        total: 10000,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.unpaid,
        deliveryStatus: DeliveryStatus.pending,
        logHistory: [],
        createdBy: mockUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      // Execute
      await transactionService.updateStatus(
        trxId: transaction.id,
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.delivered,
        userId: mockUser.uid,
        userName: mockUser.displayName!,
      );

      // Verify
      final updatedDoc = await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .get();
      final data = updatedDoc.data();
      expect(data?['paymentStatus'], PaymentStatus.paid.name);
      expect(data?['deliveryStatus'], DeliveryStatus.delivered.name);
    });

    test('Cancel Transaction', () async {
      // Setup test data
      final transaction = TransactionModel(
        id: 'test-transaction-3',
        type: TransactionType.sales,
        customerSupplierName: 'Test Customer',
        items: [
          TransactionItem(
            productId: 'product-1',
            productName: 'Test Product',
            quantity: 3,
            price: 10000,
            subtotal: 30000,
          ),
        ],
        total: 30000,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.pending,
        logHistory: [],
        createdBy: mockUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Setup initial product stock
      await fakeFirestore.collection('products').doc('product-1').set({
        'id': 'product-1',
        'name': 'Test Product',
        'stock': 5,
      });

      // Add transaction
      await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      // Execute cancel
      await transactionService.cancelTransaction(
        transaction,
        mockUser.uid,
        mockUser.displayName!,
      );

      // Verify transaction status
      final canceledDoc = await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .get();
      expect(canceledDoc.data()?['isDeleted'], true);
      expect(canceledDoc.data()?['deliveryStatus'], DeliveryStatus.canceled.name);

      // Verify stock restored
      final productDoc = await fakeFirestore
          .collection('products')
          .doc('product-1')
          .get();
      expect(productDoc.data()?['stock'], 8); // 5 + 3
    });

    test('Get Transaction Stream', () async {
      // Setup test transactions
      final transactions = [
        TransactionModel(
          id: 'test-transaction-4',
          type: TransactionType.sales,
          customerSupplierName: 'Test Customer',
          items: [
            TransactionItem(
              productId: 'product-1',
              productName: 'Test Product',
              quantity: 1,
              price: 10000,
              subtotal: 10000,
            ),
          ],
          total: 10000,
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.paid,
          deliveryStatus: DeliveryStatus.pending,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TransactionModel(
          id: 'test-transaction-5',
          type: TransactionType.purchase,
          customerSupplierName: 'Test Supplier',
          items: [],
          total: 20000,
          paymentMethod: PaymentMethod.transfer,
          paymentStatus: PaymentStatus.unpaid,
          deliveryStatus: DeliveryStatus.pending,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Add test transactions to Firestore
      for (var trx in transactions) {
        await fakeFirestore
            .collection('transactions')
            .doc(trx.id)
            .set(trx.toMap());
      }

      // Test stream
      final stream = transactionService.getTransactionsStream(type: TransactionType.sales);
      expect(
        stream,
        emits(isA<List<TransactionModel>>()),
      );
    });
  });
}