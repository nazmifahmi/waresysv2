import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:waresys_fix1/models/transaction_model.dart';
import 'package:waresys_fix1/services/transaction_service.dart';
import '../helpers/firebase_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late TransactionService transactionService;
  late MockUser mockUser;

  setUp(() async {
    await setupFirebaseForTesting();
    fakeFirestore = getFakeFirestore();
    transactionService = TransactionService.withFirestore(fakeFirestore);
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );
  });

  group('Transaction Validation Tests', () {
    test('Transaction Total Should Match Items Subtotal', () {
      final items = [
        TransactionItem(
          productId: 'product-1',
          productName: 'Product 1',
          quantity: 2,
          price: 10000,
          subtotal: 20000,
        ),
        TransactionItem(
          productId: 'product-2',
          productName: 'Product 2',
          quantity: 1,
          price: 15000,
          subtotal: 15000,
        ),
      ];

      final total = items.fold(0.0, (sum, item) => sum + item.subtotal);

      final transaction = TransactionModel(
        id: 'test-transaction-1',
        type: TransactionType.sales,
        customerSupplierId: 'customer-1',
        customerSupplierName: 'Test Customer',
        items: items,
        total: total,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.paid,
        deliveryStatus: DeliveryStatus.pending,
        logHistory: [],
        createdBy: mockUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(transaction.total, equals(35000));
      expect(transaction.items.length, equals(2));
    });

    test('Transaction Items Should Have Valid Quantities', () {
      expect(
        () => TransactionItem(
          productId: 'product-1',
          productName: 'Product 1',
          quantity: 0, // Invalid quantity
          price: 10000,
          subtotal: 0,
        ),
        throwsAssertionError,
      );

      expect(
        () => TransactionItem(
          productId: 'product-1',
          productName: 'Product 1',
          quantity: -1, // Invalid quantity
          price: 10000,
          subtotal: -10000,
        ),
        throwsAssertionError,
      );
    });

    test('Transaction Items Should Have Valid Prices', () {
      expect(
        () => TransactionItem(
          productId: 'product-1',
          productName: 'Product 1',
          quantity: 1,
          price: -1000, // Invalid price
          subtotal: -1000,
        ),
        throwsAssertionError,
      );

      expect(
        () => TransactionItem(
          productId: 'product-1',
          productName: 'Product 1',
          quantity: 1,
          price: 0, // Invalid price
          subtotal: 0,
        ),
        throwsAssertionError,
      );
    });

    test('Transaction Should Have Valid Customer/Supplier Info', () {
      expect(
        () => TransactionModel(
          id: 'test-transaction-2',
          type: TransactionType.sales,
          customerSupplierId: '', // Invalid empty ID
          customerSupplierName: 'Test Customer',
          items: [],
          total: 0,
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.paid,
          deliveryStatus: DeliveryStatus.pending,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsAssertionError,
      );

      expect(
        () => TransactionModel(
          id: 'test-transaction-2',
          type: TransactionType.sales,
          customerSupplierId: 'customer-1',
          customerSupplierName: '', // Invalid empty name
          items: [],
          total: 0,
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.paid,
          deliveryStatus: DeliveryStatus.pending,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsAssertionError,
      );
    });

    test('Transaction Status Changes Should Be Valid', () async {
      final transaction = TransactionModel(
        id: 'test-transaction-3',
        type: TransactionType.sales,
        customerSupplierId: 'customer-1',
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

      // Cannot mark as delivered if unpaid
      expect(
        () => transactionService.updateStatus(
          trxId: transaction.id,
          deliveryStatus: DeliveryStatus.delivered,
          userId: mockUser.uid,
          userName: mockUser.displayName!,
        ),
        throwsException,
      );

      // Valid status change
      await transactionService.updateStatus(
        trxId: transaction.id,
        paymentStatus: PaymentStatus.paid,
        userId: mockUser.uid,
        userName: mockUser.displayName!,
      );

      final updatedDoc = await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .get();
      expect(updatedDoc.data()?['paymentStatus'], equals(PaymentStatus.paid.name));
    });

    test('Canceled Transaction Should Not Be Modifiable', () async {
      final transaction = TransactionModel(
        id: 'test-transaction-4',
        type: TransactionType.sales,
        customerSupplierId: 'customer-1',
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
        paymentStatus: PaymentStatus.unpaid,
        deliveryStatus: DeliveryStatus.canceled,
        logHistory: [],
        createdBy: mockUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fakeFirestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());

      // Cannot update canceled transaction
      expect(
        () => transactionService.updateStatus(
          trxId: transaction.id,
          paymentStatus: PaymentStatus.paid,
          userId: mockUser.uid,
          userName: mockUser.displayName!,
        ),
        throwsException,
      );
    });
  });
} 