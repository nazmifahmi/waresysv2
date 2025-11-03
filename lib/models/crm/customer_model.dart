import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerStatus {
  active,
  inactive,
  prospect,
  churned,
}

enum CustomerSegment {
  vip,
  premium,
  standard,
  basic,
}

enum CustomerSource {
  website,
  referral,
  social_media,
  advertisement,
  cold_call,
  trade_show,
  other,
}

class CustomerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? company;
  final String? position;
  final String address;
  final String city;
  final String? province;
  final String? postalCode;
  final CustomerStatus status;
  final CustomerSegment segment;
  final CustomerSource source;
  final double totalPurchases;
  final int totalOrders;
  final DateTime? lastPurchaseDate;
  final DateTime? lastContactDate;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? assignedTo; // User ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.company,
    this.position,
    required this.address,
    required this.city,
    this.province,
    this.postalCode,
    this.status = CustomerStatus.prospect,
    this.segment = CustomerSegment.standard,
    this.source = CustomerSource.website,
    this.totalPurchases = 0.0,
    this.totalOrders = 0,
    this.lastPurchaseDate,
    this.lastContactDate,
    this.tags = const [],
    this.customFields = const {},
    this.notes,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
  });

  // Validation
  bool get isValid {
    return name.isNotEmpty &&
           email.isNotEmpty &&
           phone.isNotEmpty &&
           address.isNotEmpty &&
           city.isNotEmpty &&
           _isValidEmail(email) &&
           _isValidPhone(phone);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // Business logic helpers
  bool get isVip => segment == CustomerSegment.vip;
  bool get isActive => status == CustomerStatus.active;
  bool get hasRecentActivity => lastContactDate != null && 
    DateTime.now().difference(lastContactDate!).inDays <= 30;
  
  String get displayName => company?.isNotEmpty == true ? '$name ($company)' : name;
  String get fullAddress => [address, city, province, postalCode]
    .where((e) => e?.isNotEmpty == true)
    .join(', ');

  // Customer lifetime value calculation
  double get averageOrderValue => totalOrders > 0 ? totalPurchases / totalOrders : 0.0;
  
  // Risk assessment
  bool get isAtRisk {
    if (lastPurchaseDate == null) return false;
    final daysSinceLastPurchase = DateTime.now().difference(lastPurchaseDate!).inDays;
    return daysSinceLastPurchase > 90 && status == CustomerStatus.active;
  }

  // Copy with method for updates
  CustomerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    CustomerStatus? status,
    CustomerSegment? segment,
    CustomerSource? source,
    double? totalPurchases,
    int? totalOrders,
    DateTime? lastPurchaseDate,
    DateTime? lastContactDate,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? notes,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      position: position ?? this.position,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      status: status ?? this.status,
      segment: segment ?? this.segment,
      source: source ?? this.source,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalOrders: totalOrders ?? this.totalOrders,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.toLowerCase(),
      'phone': phone,
      'company': company,
      'position': position,
      'address': address,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'status': status.name,
      'segment': segment.name,
      'source': source.name,
      'totalPurchases': totalPurchases,
      'totalOrders': totalOrders,
      'lastPurchaseDate': lastPurchaseDate?.millisecondsSinceEpoch,
      'lastContactDate': lastContactDate?.millisecondsSinceEpoch,
      'tags': tags,
      'customFields': customFields,
      'notes': notes,
      'assignedTo': assignedTo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      // Search fields for efficient querying
      'searchName': name.toLowerCase(),
      'searchEmail': email.toLowerCase(),
      'searchCompany': company?.toLowerCase(),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      company: map['company'],
      position: map['position'],
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      province: map['province'],
      postalCode: map['postalCode'],
      status: CustomerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CustomerStatus.prospect,
      ),
      segment: CustomerSegment.values.firstWhere(
        (e) => e.name == map['segment'],
        orElse: () => CustomerSegment.standard,
      ),
      source: CustomerSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => CustomerSource.website,
      ),
      totalPurchases: (map['totalPurchases'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      lastPurchaseDate: map['lastPurchaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPurchaseDate'])
          : null,
      lastContactDate: map['lastContactDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastContactDate'])
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      notes: map['notes'],
      assignedTo: map['assignedTo'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, email: $email, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}