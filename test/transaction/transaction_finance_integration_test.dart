import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:waresys_fix1/models/transaction_model.dart';
import 'package:waresys_fix1/models/finance_model.dart';
import 'package:waresys_fix1/services/transaction_service.dart';
import 'package:waresys_fix1/services/finance_service.dart';
import 'package:waresys_fix1/services/firestore_service.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late TransactionService transactionService;
  late FinanceService financeService;
  late FirestoreService firestoreService;
  late MockUser mockUser;

  setUp(() async {
    await setupFirebaseForTesting();
    fakeFirestore = getFakeFirestore();
    transactionService = TransactionService.withFirestore(fakeFirestore);
    financeService = FinanceService.withFirestore(fakeFirestore);
    firestoreService = FirestoreService.withFirestore(fakeFirestore);
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );
  });

  group('Transaction-Finance Integration Tests', () {
    test('Paid Sales Transaction Creates Finance Income Record', () async {
      // Setup initial balance
      await fakeFirestore.collection('finance').doc('balance').set({
        'kasUtama': 50000,
        'bank': 0,
      });

      // Create and add sales transaction
      final transaction = TransactionModel(
        id: 'test-sales-1',
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
        deliveryStatus: DeliveryStatus.delivered,
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

      // Execute transaction creation
      await transactionService.addTransaction(
        transaction,
        userId: mockUser.uid,
        userName: mockUser.displayName!,
      );

      // Verify finance record created
      final financeQuery = await fakeFirestore
          .collection('finance_transactions')
          .where('type', isEqualTo: FinanceTransactionType.income.name)
          .where('category', isEqualTo: 'Penjualan')
          .get();
      
      expect(financeQuery.docs.length, 1);
      final financeDoc = financeQuery.docs.first;
      expect(financeDoc.data()['amount'], 20000);
      
      // Verify balance updated
      final balanceDoc = await fakeFirestore
          .collection('finance')
          .doc('balance')
          .get();
      expect(balanceDoc.data()?['kasUtama'], 70000); // 50000 + 20000
    });

    test('Paid Purchase Transaction Creates Finance Expense Record', () async {
      // Setup initial balance
      await fakeFirestore.collection('finance').doc('balance').set({
        'kasUtama': 100000,
        'bank': 0,
      });

      // Create and add purchase transaction
      final transaction = TransactionModel(
        id: 'test-purchase-1',
        type: TransactionType.purchase,
        customerSupplierName: 'Test Supplier',
        items: [
          TransactionItem(
            productId: 'product-1',
            productName: 'Test Product',
            quantity: 5,
            price: 8000,
            subtotal: 40000,
          ),
        ],
        total: 40000,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.delivered,
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

      // Execute transaction creation
      await transactionService.addTransaction(
        transaction,
        userId: mockUser.uid,
        userName: mockUser.displayName!,
      );

      // Verify finance record created
      final financeQuery = await fakeFirestore
          .collection('finance_transactions')
          .where('type', isEqualTo: FinanceTransactionType.expense.name)
          .where('category', isEqualTo: 'Pembelian')
          .get();
      
      expect(financeQuery.docs.length, 1);
      final financeDoc = financeQuery.docs.first;
      expect(financeDoc.data()['amount'], 40000);
      
      // Verify balance updated
      final balanceDoc = await fakeFirestore
          .collection('finance')
          .doc('balance')
          .get();
      expect(balanceDoc.data()?['kasUtama'], 60000); // 100000 - 40000
    });

    test('Transaction Status Update from Unpaid to Paid Creates Finance Record', () async {
      // Setup initial balance
      await fakeFirestore.collection('finance').doc('balance').set({
        'kasUtama': 75000,
        'bank': 0,
      });

      // Create unpaid transaction
      final transaction = TransactionModel(
        id: 'test-sales-2',
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
        paymentStatus: PaymentStatus.unpaid,
        deliveryStatus: DeliveryStatus.pending,
        logHistory: [],
        createdBy: mockUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add transaction to Firestore
      await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      // Update status to paid
      await transactionService.updateStatus(
        trxId: transaction.id,
        paymentStatus: PaymentStatus.paid,
        userId: mockUser.uid,
        userName: mockUser.displayName!,
      );

      // Verify finance record created
      final financeQuery = await fakeFirestore
          .collection('finance_transactions')
          .where('type', isEqualTo: FinanceTransactionType.income.name)
          .where('category', isEqualTo: 'Penjualan')
          .get();
      
      expect(financeQuery.docs.length, 1);
      final financeDoc = financeQuery.docs.first;
      expect(financeDoc.data()['amount'], 30000);
      
      // Verify balance updated
      final balanceDoc = await fakeFirestore
          .collection('finance')
          .doc('balance')
          .get();
      expect(balanceDoc.data()?['kasUtama'], 105000); // 75000 + 30000
    });
  });
}