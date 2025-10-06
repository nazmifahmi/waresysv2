import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:waresys_fix1/models/transaction_model.dart';
import 'package:waresys_fix1/screens/transaction/transaction_form_page.dart';
import 'package:waresys_fix1/screens/transaction/transaction_list_page.dart';
import 'package:waresys_fix1/services/transaction_service.dart';
import 'package:waresys_fix1/providers/transaction_provider.dart';
import '../helpers/firebase_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;
  late TransactionService transactionService;
  late TransactionProvider transactionProvider;

  setUpAll(() async {
    setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    transactionService = TransactionService();
    transactionProvider = TransactionProvider();
    mockUser = MockUser(
      uid: 'test-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    );
  });

  group('Transaction Form Widget Tests', () {
    testWidgets('Sales Transaction Form Shows Required Fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => transactionProvider,
              ),
            ],
            child: const TransactionFormPage(type: TransactionType.sales),
          ),
        ),
      );

      // Verify form fields are present
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Purchase Transaction Form Shows Required Fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => transactionProvider,
              ),
            ],
            child: const TransactionFormPage(type: TransactionType.purchase),
          ),
        ),
      );

      // Verify form fields are present
      expect(find.text('Supplier Name'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Form Validation Shows Error Messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => transactionProvider,
              ),
            ],
            child: const TransactionFormPage(type: TransactionType.sales),
          ),
        ),
      );

      // Try to save without filling required fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify error messages
      expect(find.text('Customer name is required'), findsOneWidget);
      expect(find.text('At least one item is required'), findsOneWidget);
    });
  });

  group('Transaction List Widget Tests', () {
    testWidgets('Transaction List Shows Transactions', (WidgetTester tester) async {
      // Add test transactions to Firestore
      final transactions = [
        TransactionModel(
          id: 'test-sales-1',
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
          deliveryStatus: DeliveryStatus.delivered,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var trx in transactions) {
        await fakeFirestore
            .collection('transactions')
            .doc(trx.id)
            .set(trx.toMap());
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => transactionProvider,
              ),
            ],
            child: const TransactionListPage(type: TransactionType.sales),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify transaction list items
      expect(find.text('Test Customer'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);
    });

    testWidgets('Transaction List Search Works', (WidgetTester tester) async {
      // Add test transactions to Firestore
      final transactions = [
        TransactionModel(
          id: 'test-sales-1',
          type: TransactionType.sales,
          customerSupplierId: 'customer-1',
          customerSupplierName: 'Customer A',
          items: [],
          total: 20000,
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.paid,
          deliveryStatus: DeliveryStatus.delivered,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TransactionModel(
          id: 'test-sales-2',
          type: TransactionType.sales,
          customerSupplierId: 'customer-2',
          customerSupplierName: 'Customer B',
          items: [],
          total: 30000,
          paymentMethod: PaymentMethod.cash,
          paymentStatus: PaymentStatus.paid,
          deliveryStatus: DeliveryStatus.delivered,
          logHistory: [],
          createdBy: mockUser.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (var trx in transactions) {
        await fakeFirestore
            .collection('transactions')
            .doc(trx.id)
            .set(trx.toMap());
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<TransactionProvider>(
                create: (_) => transactionProvider,
              ),
            ],
            child: const TransactionListPage(type: TransactionType.sales),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Customer A');
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.text('Customer A'), findsOneWidget);
      expect(find.text('Customer B'), findsNothing);
    });
  });
} 