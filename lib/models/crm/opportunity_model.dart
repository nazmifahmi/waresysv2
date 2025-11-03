import 'package:cloud_firestore/cloud_firestore.dart';

enum OpportunityStage {
  prospecting,
  qualification,
  needs_analysis,
  value_proposition,
  proposal,
  negotiation,
  closed_won,
  closed_lost,
}

enum OpportunityType {
  new_business,
  existing_business,
  renewal,
  upsell,
  cross_sell,
}

enum OpportunityPriority {
  low,
  medium,
  high,
  critical,
}

enum LossReason {
  price,
  competitor,
  no_budget,
  no_decision,
  timing,
  features,
  relationship,
  other,
}

class OpportunityModel {
  final String id;
  final String name;
  final String? customerId; // Reference to CustomerModel
  final String? leadId; // Reference to LeadModel
  final String? contactId; // Primary contact
  final OpportunityStage stage;
  final OpportunityType type;
  final OpportunityPriority priority;
  final double amount;
  final String currency;
  final int probability; // 0-100
  final DateTime expectedCloseDate;
  final DateTime? actualCloseDate;
  final int salesCycle; // Days from creation to close
  final String? description;
  final List<String> products; // Product IDs or names
  final List<String> competitors;
  final Map<String, dynamic> customFields;
  final String? notes;
  final LossReason? lossReason;
  final String? lossNotes;
  final List<String> stakeholders; // Contact IDs
  final String? campaignId;
  final String assignedTo; // User ID
  final List<String> teamMembers; // User IDs
  final List<String> activityHistory; // Activity IDs
  final Map<String, DateTime> stageHistory; // Stage transitions
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;

  OpportunityModel({
    required this.id,
    required this.name,
    this.customerId,
    this.leadId,
    this.contactId,
    this.stage = OpportunityStage.prospecting,
    this.type = OpportunityType.new_business,
    this.priority = OpportunityPriority.medium,
    required this.amount,
    this.currency = 'IDR',
    this.probability = 10,
    required this.expectedCloseDate,
    this.actualCloseDate,
    this.salesCycle = 0,
    this.description,
    this.products = const [],
    this.competitors = const [],
    this.customFields = const {},
    this.notes,
    this.lossReason,
    this.lossNotes,
    this.stakeholders = const [],
    this.campaignId,
    required this.assignedTo,
    this.teamMembers = const [],
    this.activityHistory = const [],
    this.stageHistory = const {},
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
  });

  // Validation
  bool get isValid {
    return name.isNotEmpty &&
           amount >= 0 &&
           probability >= 0 &&
           probability <= 100 &&
           assignedTo.isNotEmpty &&
           (customerId != null || leadId != null);
  }

  // Business logic helpers
  bool get isOpen => ![OpportunityStage.closed_won, OpportunityStage.closed_lost].contains(stage);
  bool get isClosed => [OpportunityStage.closed_won, OpportunityStage.closed_lost].contains(stage);
  bool get isWon => stage == OpportunityStage.closed_won;
  bool get isLost => stage == OpportunityStage.closed_lost;
  bool get isOverdue => isOpen && DateTime.now().isAfter(expectedCloseDate);
  bool get isHighValue => amount >= 100000000; // 100M IDR
  bool get isHighPriority => priority == OpportunityPriority.high || priority == OpportunityPriority.critical;

  // Pipeline calculations
  double get weightedValue => amount * (probability / 100.0);
  
  int get stageIndex {
    switch (stage) {
      case OpportunityStage.prospecting: return 0;
      case OpportunityStage.qualification: return 1;
      case OpportunityStage.needs_analysis: return 2;
      case OpportunityStage.value_proposition: return 3;
      case OpportunityStage.proposal: return 4;
      case OpportunityStage.negotiation: return 5;
      case OpportunityStage.closed_won: return 6;
      case OpportunityStage.closed_lost: return 6;
    }
  }

  double get stageProgress {
    if (isClosed) return 1.0;
    return stageIndex / 6.0;
  }

  // Time calculations
  int get daysToClose {
    if (isClosed) return 0;
    return expectedCloseDate.difference(DateTime.now()).inDays;
  }

  int get daysInCurrentStage {
    final stageStartDate = stageHistory[stage.name];
    if (stageStartDate == null) return 0;
    return DateTime.now().difference(stageStartDate).inDays;
  }

  int get totalSalesCycle {
    if (actualCloseDate != null) {
      return actualCloseDate!.difference(createdAt).inDays;
    }
    return DateTime.now().difference(createdAt).inDays;
  }

  // Opportunity scoring
  int get opportunityScore {
    int score = 0;
    
    // Amount scoring (0-30 points)
    if (amount >= 1000000000) { // 1B IDR
      score += 30;
    } else if (amount >= 500000000) { // 500M IDR
      score += 25;
    } else if (amount >= 100000000) { // 100M IDR
      score += 20;
    } else if (amount >= 50000000) { // 50M IDR
      score += 15;
    } else {
      score += 10;
    }
    
    // Probability scoring (0-25 points)
    score += (probability * 0.25).round();
    
    // Stage scoring (0-20 points)
    switch (stage) {
      case OpportunityStage.negotiation:
        score += 20;
        break;
      case OpportunityStage.proposal:
        score += 18;
        break;
      case OpportunityStage.value_proposition:
        score += 15;
        break;
      case OpportunityStage.needs_analysis:
        score += 12;
        break;
      case OpportunityStage.qualification:
        score += 8;
        break;
      case OpportunityStage.prospecting:
        score += 5;
        break;
      default:
        break;
    }
    
    // Priority scoring (0-15 points)
    switch (priority) {
      case OpportunityPriority.critical:
        score += 15;
        break;
      case OpportunityPriority.high:
        score += 12;
        break;
      case OpportunityPriority.medium:
        score += 8;
        break;
      case OpportunityPriority.low:
        score += 5;
        break;
    }
    
    // Activity scoring (0-10 points)
    score += (activityHistory.length * 0.5).clamp(0, 10).round();
    
    return score.clamp(0, 100);
  }

  // Risk assessment
  bool get isAtRisk {
    if (isClosed) return false;
    
    // Overdue opportunities are at risk
    if (isOverdue) return true;
    
    // Long time in current stage
    if (daysInCurrentStage > 30) return true;
    
    // Low probability in late stage
    if (stageIndex >= 3 && probability < 50) return true;
    
    return false;
  }

  // Forecast category
  String get forecastCategory {
    if (isClosed) return isWon ? 'Closed Won' : 'Closed Lost';
    
    if (probability >= 90) return 'Commit';
    if (probability >= 70) return 'Best Case';
    if (probability >= 50) return 'Most Likely';
    return 'Pipeline';
  }

  // Copy with method for updates
  OpportunityModel copyWith({
    String? id,
    String? name,
    String? customerId,
    String? leadId,
    String? contactId,
    OpportunityStage? stage,
    OpportunityType? type,
    OpportunityPriority? priority,
    double? amount,
    String? currency,
    int? probability,
    DateTime? expectedCloseDate,
    DateTime? actualCloseDate,
    int? salesCycle,
    String? description,
    List<String>? products,
    List<String>? competitors,
    Map<String, dynamic>? customFields,
    String? notes,
    LossReason? lossReason,
    String? lossNotes,
    List<String>? stakeholders,
    String? campaignId,
    String? assignedTo,
    List<String>? teamMembers,
    List<String>? activityHistory,
    Map<String, DateTime>? stageHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return OpportunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      customerId: customerId ?? this.customerId,
      leadId: leadId ?? this.leadId,
      contactId: contactId ?? this.contactId,
      stage: stage ?? this.stage,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      probability: probability ?? this.probability,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      actualCloseDate: actualCloseDate ?? this.actualCloseDate,
      salesCycle: salesCycle ?? this.salesCycle,
      description: description ?? this.description,
      products: products ?? this.products,
      competitors: competitors ?? this.competitors,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      lossReason: lossReason ?? this.lossReason,
      lossNotes: lossNotes ?? this.lossNotes,
      stakeholders: stakeholders ?? this.stakeholders,
      campaignId: campaignId ?? this.campaignId,
      assignedTo: assignedTo ?? this.assignedTo,
      teamMembers: teamMembers ?? this.teamMembers,
      activityHistory: activityHistory ?? this.activityHistory,
      stageHistory: stageHistory ?? this.stageHistory,
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
      'customerId': customerId,
      'leadId': leadId,
      'contactId': contactId,
      'stage': stage.name,
      'type': type.name,
      'priority': priority.name,
      'amount': amount,
      'currency': currency,
      'probability': probability,
      'expectedCloseDate': expectedCloseDate.millisecondsSinceEpoch,
      'actualCloseDate': actualCloseDate?.millisecondsSinceEpoch,
      'salesCycle': salesCycle,
      'description': description,
      'products': products,
      'competitors': competitors,
      'customFields': customFields,
      'notes': notes,
      'lossReason': lossReason?.name,
      'lossNotes': lossNotes,
      'stakeholders': stakeholders,
      'campaignId': campaignId,
      'assignedTo': assignedTo,
      'teamMembers': teamMembers,
      'activityHistory': activityHistory,
      'stageHistory': stageHistory.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      // Computed fields for efficient querying
      'weightedValue': weightedValue,
      'stageIndex': stageIndex,
      'isOpen': isOpen,
      'isClosed': isClosed,
      'isWon': isWon,
      'isOverdue': isOverdue,
      'isAtRisk': isAtRisk,
      'opportunityScore': opportunityScore,
      'forecastCategory': forecastCategory,
      'daysToClose': daysToClose,
      // Search fields
      'searchName': name.toLowerCase(),
      'searchDescription': description?.toLowerCase(),
    };
  }

  factory OpportunityModel.fromMap(Map<String, dynamic> map) {
    return OpportunityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      customerId: map['customerId'],
      leadId: map['leadId'],
      contactId: map['contactId'],
      stage: OpportunityStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => OpportunityStage.prospecting,
      ),
      type: OpportunityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => OpportunityType.new_business,
      ),
      priority: OpportunityPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => OpportunityPriority.medium,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'IDR',
      probability: map['probability'] ?? 10,
      expectedCloseDate: DateTime.fromMillisecondsSinceEpoch(map['expectedCloseDate']),
      actualCloseDate: map['actualCloseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['actualCloseDate'])
          : null,
      salesCycle: map['salesCycle'] ?? 0,
      description: map['description'],
      products: List<String>.from(map['products'] ?? []),
      competitors: List<String>.from(map['competitors'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      notes: map['notes'],
      lossReason: map['lossReason'] != null
          ? LossReason.values.firstWhere(
              (e) => e.name == map['lossReason'],
              orElse: () => LossReason.other,
            )
          : null,
      lossNotes: map['lossNotes'],
      stakeholders: List<String>.from(map['stakeholders'] ?? []),
      campaignId: map['campaignId'],
      assignedTo: map['assignedTo'] ?? '',
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      activityHistory: List<String>.from(map['activityHistory'] ?? []),
      stageHistory: (map['stageHistory'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, DateTime.fromMillisecondsSinceEpoch(v))),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  factory OpportunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OpportunityModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'OpportunityModel(id: $id, name: $name, stage: $stage, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpportunityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}