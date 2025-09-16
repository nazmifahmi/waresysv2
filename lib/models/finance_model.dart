import 'package:cloud_firestore/cloud_firestore.dart';

enum FinanceTransactionType { income, expense }

class FinanceTransaction {
  final String id;
  final FinanceTransactionType type;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String createdBy;

  FinanceTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'category': category,
    'amount': amount,
    'description': description,
    'date': Timestamp.fromDate(date),
    'createdBy': createdBy,
  };

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) => FinanceTransaction(
    id: map['id'],
    type: FinanceTransactionType.values.firstWhere((e) => e.name == map['type']),
    category: map['category'],
    amount: (map['amount'] as num).toDouble(),
    description: map['description'],
    date: (map['date'] as Timestamp).toDate(),
    createdBy: map['createdBy'],
  );

  factory FinanceTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinanceTransaction.fromMap({
      ...data,
      'id': doc.id,
    });
  }
}

class FinanceBalance {
  final double kasUtama;
  final double bank;

  FinanceBalance({required this.kasUtama, required this.bank});

  Map<String, dynamic> toMap() => {
    'kasUtama': kasUtama,
    'bank': bank,
  };

  factory FinanceBalance.fromMap(Map<String, dynamic> map) => FinanceBalance(
    kasUtama: (map['kasUtama'] as num?)?.toDouble() ?? 0.0,
    bank: (map['bank'] as num?)?.toDouble() ?? 0.0,
  );
}

class FinanceBalanceLog {
  final String id;
  final double before;
  final double after;
  final String userId;
  final String userName;
  final DateTime date;
  final String note;

  FinanceBalanceLog({
    required this.id,
    required this.before,
    required this.after,
    required this.userId,
    required this.userName,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'before': before,
    'after': after,
    'userId': userId,
    'userName': userName,
    'date': Timestamp.fromDate(date),
    'note': note,
  };

  factory FinanceBalanceLog.fromMap(Map<String, dynamic> map) => FinanceBalanceLog(
    id: map['id'],
    before: (map['before'] as num).toDouble(),
    after: (map['after'] as num).toDouble(),
    userId: map['userId'],
    userName: map['userName'],
    date: (map['date'] as Timestamp).toDate(),
    note: map['note'],
  );
}

class FinanceBudget {
  final String id;
  final String category;
  final double amount;
  final int month;
  final int year;
  final String createdBy;

  FinanceBudget({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'amount': amount,
    'month': month,
    'year': year,
    'createdBy': createdBy,
  };

  factory FinanceBudget.fromMap(Map<String, dynamic> map) => FinanceBudget(
    id: map['id'],
    category: map['category'],
    amount: (map['amount'] as num).toDouble(),
    month: map['month'],
    year: map['year'],
    createdBy: map['createdBy'],
  );
} 