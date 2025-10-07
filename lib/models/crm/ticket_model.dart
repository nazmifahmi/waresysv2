import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketPriority { LOW, MEDIUM, HIGH }
enum TicketStatus { OPEN, IN_PROGRESS, CLOSED }

class TicketModel {
  final String ticketId;
  final String title;
  final String description;
  final String contactId;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedTo;

  TicketModel({
    required this.ticketId,
    required this.title,
    required this.description,
    required this.contactId,
    this.priority = TicketPriority.MEDIUM,
    this.status = TicketStatus.OPEN,
    this.assignedTo,
  }) : assert(ticketId.isNotEmpty), assert(title.isNotEmpty), assert(description.isNotEmpty), assert(contactId.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'title': title,
        'description': description,
        'contactId': contactId,
        'priority': priority.name,
        'status': status.name,
        'assignedTo': assignedTo,
      };

  factory TicketModel.fromMap(Map<String, dynamic> map) => TicketModel(
        ticketId: map['ticketId'],
        title: map['title'],
        description: map['description'],
        contactId: map['contactId'],
        priority: TicketPriority.values.firstWhere((e) => e.name == map['priority']),
        status: TicketStatus.values.firstWhere((e) => e.name == map['status']),
        assignedTo: map['assignedTo'],
      );

  factory TicketModel.fromDoc(DocumentSnapshot doc) =>
      TicketModel.fromMap({...doc.data() as Map<String, dynamic>, 'ticketId': doc.id});
}

class TicketCommentModel {
  final String commentId;
  final String ticketId;
  final String authorId;
  final DateTime timestamp;
  final String commentText;

  TicketCommentModel({
    required this.commentId,
    required this.ticketId,
    required this.authorId,
    required this.timestamp,
    required this.commentText,
  });

  Map<String, dynamic> toMap() => {
        'commentId': commentId,
        'ticketId': ticketId,
        'authorId': authorId,
        'timestamp': Timestamp.fromDate(timestamp),
        'commentText': commentText,
      };

  factory TicketCommentModel.fromMap(Map<String, dynamic> map) => TicketCommentModel(
        commentId: map['commentId'],
        ticketId: map['ticketId'],
        authorId: map['authorId'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        commentText: map['commentText'],
      );

  factory TicketCommentModel.fromDoc(DocumentSnapshot doc) => TicketCommentModel.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'commentId': doc.id,
      });
}


