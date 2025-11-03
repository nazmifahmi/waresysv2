import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadStatus {
  new_lead,
  contacted,
  qualified,
  proposal,
  negotiation,
  closed_won,
  closed_lost,
  on_hold,
}

enum LeadSource {
  website,
  referral,
  social_media,
  advertisement,
  cold_call,
  trade_show,
  email_campaign,
  content_marketing,
  other,
}

enum LeadPriority {
  low,
  medium,
  high,
  urgent,
}

enum LeadQuality {
  cold,
  warm,
  hot,
}

class LeadModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? company;
  final String? position;
  final String? industry;
  final LeadStatus status;
  final LeadSource source;
  final LeadPriority priority;
  final LeadQuality quality;
  final double estimatedValue;
  final int probabilityPercent; // 0-100
  final DateTime? expectedCloseDate;
  final DateTime? lastContactDate;
  final DateTime? nextFollowUpDate;
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? assignedTo; // User ID
  final String? campaignId;
  final int contactAttempts;
  final List<String> interactionHistory; // Activity IDs
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;

  LeadModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.company,
    this.position,
    this.industry,
    this.status = LeadStatus.new_lead,
    this.source = LeadSource.website,
    this.priority = LeadPriority.medium,
    this.quality = LeadQuality.cold,
    this.estimatedValue = 0.0,
    this.probabilityPercent = 10,
    this.expectedCloseDate,
    this.lastContactDate,
    this.nextFollowUpDate,
    this.tags = const [],
    this.customFields = const {},
    this.notes,
    this.assignedTo,
    this.campaignId,
    this.contactAttempts = 0,
    this.interactionHistory = const [],
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
           _isValidEmail(email) &&
           _isValidPhone(phone) &&
           probabilityPercent >= 0 &&
           probabilityPercent <= 100 &&
           estimatedValue >= 0;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[\+]?[0-9]{10,15}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // Business logic helpers
  bool get isOpen => ![LeadStatus.closed_won, LeadStatus.closed_lost].contains(status);
  bool get isClosed => [LeadStatus.closed_won, LeadStatus.closed_lost].contains(status);
  bool get isWon => status == LeadStatus.closed_won;
  bool get isLost => status == LeadStatus.closed_lost;
  bool get isHot => quality == LeadQuality.hot;
  bool get isHighPriority => priority == LeadPriority.high || priority == LeadPriority.urgent;
  
  String get displayName => company?.isNotEmpty == true ? '$name ($company)' : name;
  
  // Pipeline stage progression
  int get stageIndex {
    switch (status) {
      case LeadStatus.new_lead: return 0;
      case LeadStatus.contacted: return 1;
      case LeadStatus.qualified: return 2;
      case LeadStatus.proposal: return 3;
      case LeadStatus.negotiation: return 4;
      case LeadStatus.closed_won: return 5;
      case LeadStatus.closed_lost: return 5;
      case LeadStatus.on_hold: return -1;
    }
  }

  double get stageProgress {
    if (isClosed) return 1.0;
    return stageIndex / 5.0;
  }

  // Weighted value for pipeline forecasting
  double get weightedValue => estimatedValue * (probabilityPercent / 100.0);

  // Follow-up management
  bool get needsFollowUp {
    if (nextFollowUpDate == null) return false;
    return DateTime.now().isAfter(nextFollowUpDate!);
  }

  bool get isOverdue {
    if (expectedCloseDate == null) return false;
    return DateTime.now().isAfter(expectedCloseDate!) && isOpen;
  }

  // Lead scoring (simple implementation)
  int get leadScore {
    int score = 0;
    
    // Quality scoring
    switch (quality) {
      case LeadQuality.hot: score += 40;
      case LeadQuality.warm: score += 25;
      case LeadQuality.cold: score += 10;
    }
    
    // Priority scoring
    switch (priority) {
      case LeadPriority.urgent: score += 30;
      case LeadPriority.high: score += 20;
      case LeadPriority.medium: score += 10;
      case LeadPriority.low: score += 5;
    }
    
    // Engagement scoring
    score += (contactAttempts * 2).clamp(0, 20);
    score += interactionHistory.length.clamp(0, 10);
    
    return score.clamp(0, 100);
  }

  // Days in current stage
  int get daysInStage {
    return DateTime.now().difference(updatedAt).inDays;
  }

  // Copy with method for updates
  LeadModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? industry,
    LeadStatus? status,
    LeadSource? source,
    LeadPriority? priority,
    LeadQuality? quality,
    double? estimatedValue,
    int? probabilityPercent,
    DateTime? expectedCloseDate,
    DateTime? lastContactDate,
    DateTime? nextFollowUpDate,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? notes,
    String? assignedTo,
    String? campaignId,
    int? contactAttempts,
    List<String>? interactionHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      position: position ?? this.position,
      industry: industry ?? this.industry,
      status: status ?? this.status,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      quality: quality ?? this.quality,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      probabilityPercent: probabilityPercent ?? this.probabilityPercent,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
      campaignId: campaignId ?? this.campaignId,
      contactAttempts: contactAttempts ?? this.contactAttempts,
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
      'name': name,
      'email': email.toLowerCase(),
      'phone': phone,
      'company': company,
      'position': position,
      'industry': industry,
      'status': status.name,
      'source': source.name,
      'priority': priority.name,
      'quality': quality.name,
      'estimatedValue': estimatedValue,
      'probabilityPercent': probabilityPercent,
      'expectedCloseDate': expectedCloseDate?.millisecondsSinceEpoch,
      'lastContactDate': lastContactDate?.millisecondsSinceEpoch,
      'nextFollowUpDate': nextFollowUpDate?.millisecondsSinceEpoch,
      'tags': tags,
      'customFields': customFields,
      'notes': notes,
      'assignedTo': assignedTo,
      'campaignId': campaignId,
      'contactAttempts': contactAttempts,
      'interactionHistory': interactionHistory,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      // Computed fields for efficient querying
      'leadScore': leadScore,
      'weightedValue': weightedValue,
      'stageIndex': stageIndex,
      'isOpen': isOpen,
      'needsFollowUp': needsFollowUp,
      'isOverdue': isOverdue,
      // Search fields
      'searchName': name.toLowerCase(),
      'searchEmail': email.toLowerCase(),
      'searchCompany': company?.toLowerCase(),
    };
  }

  factory LeadModel.fromMap(Map<String, dynamic> map) {
    return LeadModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      company: map['company'],
      position: map['position'],
      industry: map['industry'],
      status: LeadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LeadStatus.new_lead,
      ),
      source: LeadSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => LeadSource.website,
      ),
      priority: LeadPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => LeadPriority.medium,
      ),
      quality: LeadQuality.values.firstWhere(
        (e) => e.name == map['quality'],
        orElse: () => LeadQuality.cold,
      ),
      estimatedValue: (map['estimatedValue'] ?? 0.0).toDouble(),
      probabilityPercent: map['probabilityPercent'] ?? 10,
      expectedCloseDate: map['expectedCloseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expectedCloseDate'])
          : null,
      lastContactDate: map['lastContactDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastContactDate'])
          : null,
      nextFollowUpDate: map['nextFollowUpDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextFollowUpDate'])
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      notes: map['notes'],
      assignedTo: map['assignedTo'],
      campaignId: map['campaignId'],
      contactAttempts: map['contactAttempts'] ?? 0,
      interactionHistory: List<String>.from(map['interactionHistory'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeadModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'LeadModel(id: $id, name: $name, status: $status, value: $estimatedValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeadModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}