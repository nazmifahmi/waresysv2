import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactType {
  primary,
  secondary,
  billing,
  technical,
  decision_maker,
  influencer,
}

enum ContactStatus {
  active,
  inactive,
  do_not_contact,
  bounced,
}

enum PreferredContactMethod {
  email,
  phone,
  sms,
  whatsapp,
  linkedin,
}

class ContactModel {
  final String id;
  final String customerId; // Reference to CustomerModel
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? mobile;
  final String? position;
  final String? department;
  final ContactType type;
  final ContactStatus status;
  final PreferredContactMethod preferredContactMethod;
  final bool isDecisionMaker;
  final bool canReceiveMarketing;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? notes;
  final DateTime? lastContactDate;
  final DateTime? birthday;
  final String? linkedinProfile;
  final String? twitterHandle;
  final List<String> interactionHistory; // Activity IDs
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;

  ContactModel({
    required this.id,
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.mobile,
    this.position,
    this.department,
    this.type = ContactType.primary,
    this.status = ContactStatus.active,
    this.preferredContactMethod = PreferredContactMethod.email,
    this.isDecisionMaker = false,
    this.canReceiveMarketing = true,
    this.tags = const [],
    this.customFields = const {},
    this.notes,
    this.lastContactDate,
    this.birthday,
    this.linkedinProfile,
    this.twitterHandle,
    this.interactionHistory = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
  });

  // Validation
  bool get isValid {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           email.isNotEmpty &&
           phone.isNotEmpty &&
           customerId.isNotEmpty &&
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
  String get fullName => '$firstName $lastName';
  String get displayName => position?.isNotEmpty == true 
      ? '$fullName ($position)' 
      : fullName;
  
  bool get isActive => status == ContactStatus.active;
  bool get canContact => status != ContactStatus.do_not_contact && status != ContactStatus.bounced;
  bool get isPrimary => type == ContactType.primary;
  
  // Contact preferences
  bool get prefersEmail => preferredContactMethod == PreferredContactMethod.email;
  bool get prefersPhone => preferredContactMethod == PreferredContactMethod.phone;
  bool get prefersDigital => [
    PreferredContactMethod.email,
    PreferredContactMethod.sms,
    PreferredContactMethod.whatsapp,
    PreferredContactMethod.linkedin,
  ].contains(preferredContactMethod);

  // Engagement metrics
  bool get hasRecentActivity => lastContactDate != null && 
    DateTime.now().difference(lastContactDate!).inDays <= 30;
  
  int get engagementScore {
    int score = 0;
    
    // Base score for active status
    if (isActive) score += 20;
    
    // Decision maker bonus
    if (isDecisionMaker) score += 30;
    
    // Recent activity bonus
    if (hasRecentActivity) score += 25;
    
    // Interaction history bonus
    score += (interactionHistory.length * 2).clamp(0, 25);
    
    return score.clamp(0, 100);
  }

  // Birthday and anniversary tracking
  bool get hasBirthdayThisMonth {
    if (birthday == null) return false;
    final now = DateTime.now();
    return birthday!.month == now.month;
  }

  bool get hasBirthdayToday {
    if (birthday == null) return false;
    final now = DateTime.now();
    return birthday!.month == now.month && birthday!.day == now.day;
  }

  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month || 
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  // Copy with method for updates
  ContactModel copyWith({
    String? id,
    String? customerId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? mobile,
    String? position,
    String? department,
    ContactType? type,
    ContactStatus? status,
    PreferredContactMethod? preferredContactMethod,
    bool? isDecisionMaker,
    bool? canReceiveMarketing,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? notes,
    DateTime? lastContactDate,
    DateTime? birthday,
    String? linkedinProfile,
    String? twitterHandle,
    List<String>? interactionHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return ContactModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      position: position ?? this.position,
      department: department ?? this.department,
      type: type ?? this.type,
      status: status ?? this.status,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      isDecisionMaker: isDecisionMaker ?? this.isDecisionMaker,
      canReceiveMarketing: canReceiveMarketing ?? this.canReceiveMarketing,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      birthday: birthday ?? this.birthday,
      linkedinProfile: linkedinProfile ?? this.linkedinProfile,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      interactionHistory: interactionHistory ?? this.interactionHistory,
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
      'customerId': customerId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email.toLowerCase(),
      'phone': phone,
      'mobile': mobile,
      'position': position,
      'department': department,
      'type': type.name,
      'status': status.name,
      'preferredContactMethod': preferredContactMethod.name,
      'isDecisionMaker': isDecisionMaker,
      'canReceiveMarketing': canReceiveMarketing,
      'tags': tags,
      'customFields': customFields,
      'notes': notes,
      'lastContactDate': lastContactDate?.millisecondsSinceEpoch,
      'birthday': birthday?.millisecondsSinceEpoch,
      'linkedinProfile': linkedinProfile,
      'twitterHandle': twitterHandle,
      'interactionHistory': interactionHistory,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      // Computed fields for efficient querying
      'fullName': fullName,
      'engagementScore': engagementScore,
      'canContact': canContact,
      'hasBirthdayThisMonth': hasBirthdayThisMonth,
      // Search fields
      'searchName': fullName.toLowerCase(),
      'searchEmail': email.toLowerCase(),
      'searchPosition': position?.toLowerCase(),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      mobile: map['mobile'],
      position: map['position'],
      department: map['department'],
      type: ContactType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContactType.primary,
      ),
      status: ContactStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContactStatus.active,
      ),
      preferredContactMethod: PreferredContactMethod.values.firstWhere(
        (e) => e.name == map['preferredContactMethod'],
        orElse: () => PreferredContactMethod.email,
      ),
      isDecisionMaker: map['isDecisionMaker'] ?? false,
      canReceiveMarketing: map['canReceiveMarketing'] ?? true,
      tags: List<String>.from(map['tags'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      notes: map['notes'],
      lastContactDate: map['lastContactDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastContactDate'])
          : null,
      birthday: map['birthday'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['birthday'])
          : null,
      linkedinProfile: map['linkedinProfile'],
      twitterHandle: map['twitterHandle'],
      interactionHistory: List<String>.from(map['interactionHistory'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  factory ContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, name: $fullName, email: $email, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}