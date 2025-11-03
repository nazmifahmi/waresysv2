import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  call,
  email,
  meeting,
  task,
  note,
  sms,
  whatsapp,
  linkedin_message,
  demo,
  proposal_sent,
  contract_sent,
  follow_up,
  quote_sent,
  other,
}

enum ActivityStatus {
  planned,
  in_progress,
  completed,
  cancelled,
  overdue,
}

enum ActivityPriority {
  low,
  medium,
  high,
  urgent,
}

enum ActivityOutcome {
  successful,
  unsuccessful,
  no_response,
  rescheduled,
  cancelled,
  pending,
}

class ActivityModel {
  final String id;
  final String? customerId; // Reference to CustomerModel
  final String? leadId; // Reference to LeadModel
  final String? contactId; // Reference to ContactModel
  final ActivityType type;
  final ActivityStatus status;
  final ActivityPriority priority;
  final ActivityOutcome? outcome;
  final String subject;
  final String? description;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final int durationMinutes;
  final String? location;
  final List<String> participants; // User IDs or email addresses
  final List<String> tags;
  final Map<String, dynamic> customFields;
  final String? notes;
  final String? followUpTaskId; // Reference to next activity
  final List<String> attachments; // File URLs or IDs
  final bool isRecurring;
  final String? recurringPattern; // JSON string for recurring rules
  final DateTime? nextRecurrenceDate;
  final String assignedTo; // User ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? updatedBy;

  ActivityModel({
    required this.id,
    this.customerId,
    this.leadId,
    this.contactId,
    required this.type,
    this.status = ActivityStatus.planned,
    this.priority = ActivityPriority.medium,
    this.outcome,
    required this.subject,
    this.description,
    required this.scheduledDate,
    this.completedDate,
    this.durationMinutes = 30,
    this.location,
    this.participants = const [],
    this.tags = const [],
    this.customFields = const {},
    this.notes,
    this.followUpTaskId,
    this.attachments = const [],
    this.isRecurring = false,
    this.recurringPattern,
    this.nextRecurrenceDate,
    required this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.updatedBy,
  });

  // Validation
  bool get isValid {
    return subject.isNotEmpty &&
           assignedTo.isNotEmpty &&
           durationMinutes > 0 &&
           (customerId != null || leadId != null || contactId != null);
  }

  // Business logic helpers
  bool get isCompleted => status == ActivityStatus.completed;
  bool get isOverdue => status != ActivityStatus.completed && 
                       status != ActivityStatus.cancelled &&
                       DateTime.now().isAfter(scheduledDate);
  bool get isDueToday {
    final now = DateTime.now();
    final scheduled = scheduledDate;
    return scheduled.year == now.year &&
           scheduled.month == now.month &&
           scheduled.day == now.day;
  }
  bool get isDueTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final scheduled = scheduledDate;
    return scheduled.year == tomorrow.year &&
           scheduled.month == tomorrow.month &&
           scheduled.day == tomorrow.day;
  }
  bool get isUpcoming => scheduledDate.isAfter(DateTime.now()) && 
                        status == ActivityStatus.planned;
  bool get isHighPriority => priority == ActivityPriority.high || 
                            priority == ActivityPriority.urgent;

  // Duration helpers
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}m';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  DateTime get endTime => scheduledDate.add(Duration(minutes: durationMinutes));

  // Relationship helpers
  String? get relatedEntityId => customerId ?? leadId ?? contactId;
  String get relatedEntityType {
    if (customerId != null) return 'customer';
    if (leadId != null) return 'lead';
    if (contactId != null) return 'contact';
    return 'unknown';
  }

  // Activity scoring for productivity metrics
  int get activityScore {
    int score = 0;
    
    // Base score by type
    switch (type) {
      case ActivityType.meeting:
      case ActivityType.demo:
        score += 20;
        break;
      case ActivityType.call:
        score += 15;
        break;
      case ActivityType.email:
      case ActivityType.proposal_sent:
      case ActivityType.contract_sent:
        score += 10;
        break;
      case ActivityType.follow_up:
        score += 8;
        break;
      default:
        score += 5;
    }
    
    // Priority multiplier
    switch (priority) {
      case ActivityPriority.urgent:
        score = (score * 1.5).round();
        break;
      case ActivityPriority.high:
        score = (score * 1.2).round();
        break;
      default:
        break;
    }
    
    // Completion bonus
    if (isCompleted) {
      score += 5;
      
      // Outcome bonus
      if (outcome == ActivityOutcome.successful) {
        score += 10;
      }
    }
    
    return score;
  }

  // Time management
  bool get needsReminder {
    if (isCompleted || status == ActivityStatus.cancelled) return false;
    final reminderTime = scheduledDate.subtract(const Duration(minutes: 15));
    return DateTime.now().isAfter(reminderTime) && 
           DateTime.now().isBefore(scheduledDate);
  }

  // Copy with method for updates
  ActivityModel copyWith({
    String? id,
    String? customerId,
    String? leadId,
    String? contactId,
    ActivityType? type,
    ActivityStatus? status,
    ActivityPriority? priority,
    ActivityOutcome? outcome,
    String? subject,
    String? description,
    DateTime? scheduledDate,
    DateTime? completedDate,
    int? durationMinutes,
    String? location,
    List<String>? participants,
    List<String>? tags,
    Map<String, dynamic>? customFields,
    String? notes,
    String? followUpTaskId,
    List<String>? attachments,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? nextRecurrenceDate,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      leadId: leadId ?? this.leadId,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      outcome: outcome ?? this.outcome,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      notes: notes ?? this.notes,
      followUpTaskId: followUpTaskId ?? this.followUpTaskId,
      attachments: attachments ?? this.attachments,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      nextRecurrenceDate: nextRecurrenceDate ?? this.nextRecurrenceDate,
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
      'customerId': customerId,
      'leadId': leadId,
      'contactId': contactId,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'outcome': outcome?.name,
      'subject': subject,
      'description': description,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'location': location,
      'participants': participants,
      'tags': tags,
      'customFields': customFields,
      'notes': notes,
      'followUpTaskId': followUpTaskId,
      'attachments': attachments,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'nextRecurrenceDate': nextRecurrenceDate?.millisecondsSinceEpoch,
      'assignedTo': assignedTo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      // Computed fields for efficient querying
      'isCompleted': isCompleted,
      'isOverdue': isOverdue,
      'isDueToday': isDueToday,
      'isDueTomorrow': isDueTomorrow,
      'isUpcoming': isUpcoming,
      'activityScore': activityScore,
      'relatedEntityType': relatedEntityType,
      'relatedEntityId': relatedEntityId,
      // Search fields
      'searchSubject': subject.toLowerCase(),
      'searchDescription': description?.toLowerCase(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      customerId: map['customerId'],
      leadId: map['leadId'],
      contactId: map['contactId'],
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.other,
      ),
      status: ActivityStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ActivityStatus.planned,
      ),
      priority: ActivityPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => ActivityPriority.medium,
      ),
      outcome: map['outcome'] != null
          ? ActivityOutcome.values.firstWhere(
              (e) => e.name == map['outcome'],
              orElse: () => ActivityOutcome.pending,
            )
          : null,
      subject: map['subject'] ?? '',
      description: map['description'],
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(map['scheduledDate']),
      completedDate: map['completedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedDate'])
          : null,
      durationMinutes: map['durationMinutes'] ?? 30,
      location: map['location'],
      participants: List<String>.from(map['participants'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      customFields: Map<String, dynamic>.from(map['customFields'] ?? {}),
      notes: map['notes'],
      followUpTaskId: map['followUpTaskId'],
      attachments: List<String>.from(map['attachments'] ?? []),
      isRecurring: map['isRecurring'] ?? false,
      recurringPattern: map['recurringPattern'],
      nextRecurrenceDate: map['nextRecurrenceDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextRecurrenceDate'])
          : null,
      assignedTo: map['assignedTo'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'],
    );
  }

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel.fromMap({...data, 'id': doc.id});
  }

  @override
  String toString() {
    return 'ActivityModel(id: $id, subject: $subject, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}