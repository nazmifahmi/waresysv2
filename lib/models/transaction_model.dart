import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { sales, purchase }
enum PaymentStatus { paid, unpaid }
enum DeliveryStatus { delivered, pending, canceled }

enum PaymentMethod { cash, transfer, qris, other }

class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  }) : assert(quantity > 0, 'Quantity must be greater than 0'),
       assert(price > 0, 'Price must be greater than 0'),
       assert(subtotal == price * quantity, 'Subtotal must equal price * quantity');

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'subtotal': subtotal,
      };

  factory TransactionItem.fromMap(Map<String, dynamic> map) => TransactionItem(
        productId: map['productId'],
        productName: map['productName'],
        quantity: map['quantity'],
        price: (map['price'] as num).toDouble(),
        subtotal: (map['subtotal'] as num).toDouble(),
      );
}

class TransactionLog {
  final String action;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String? note;

  TransactionLog({
    required this.action,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'action': action,
        'userId': userId,
        'userName': userName,
        'timestamp': Timestamp.fromDate(timestamp),
        'note': note,
      };

  factory TransactionLog.fromMap(Map<String, dynamic> map) => TransactionLog(
        action: map['action'],
        userId: map['userId'],
        userName: map['userName'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        note: map['note'],
      );
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final String customerSupplierName;
  final List<TransactionItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DeliveryStatus deliveryStatus;
  final String? trackingNumber;
  final String? notes;
  final bool isDeleted;
  final List<TransactionLog> logHistory;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.customerSupplierName,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryStatus,
    this.trackingNumber,
    this.notes,
    this.isDeleted = false,
    required this.logHistory,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(customerSupplierName.isNotEmpty, 'Customer/Supplier name cannot be empty'),
       assert(total >= 0, 'Total must be greater than or equal to 0'),
       assert(total == items.fold(0.0, (sum, item) => sum + item.subtotal), 'Total must equal sum of item subtotals');

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'customerSupplierName': customerSupplierName,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'deliveryStatus': deliveryStatus.name,
        'trackingNumber': trackingNumber,
        'notes': notes,
        'isDeleted': isDeleted,
        'logHistory': logHistory.map((e) => e.toMap()).toList(),
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'],
        type: TransactionType.values.firstWhere((e) => e.name == map['type']),
        customerSupplierName: map['customerSupplierName'],
        items: (map['items'] as List).map((e) => TransactionItem.fromMap(e)).toList(),
        total: (map['total'] as num).toDouble(),
        paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == map['paymentMethod']),
        paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == map['paymentStatus']),
        deliveryStatus: DeliveryStatus.values.firstWhere((e) => e.name == map['deliveryStatus']),
        trackingNumber: map['trackingNumber'],
        notes: map['notes'],
        isDeleted: map['isDeleted'] ?? false,
        logHistory: (map['logHistory'] as List?)?.map((e) => TransactionLog.fromMap(e)).toList() ?? [],
        createdBy: map['createdBy'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  // Getter for date to be used in AI predictions
  DateTime get date => createdAt;

  // Get all product IDs involved in this transaction
  List<String> get productIds => items.map((item) => item.productId).toList();
} 