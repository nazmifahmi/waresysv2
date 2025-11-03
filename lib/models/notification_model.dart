import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { 
  leave_approved, 
  leave_rejected, 
  task_assigned, 
  task_completed, 
  task_overdue,
  claim_approved, 
  claim_rejected,
  payroll_generated,
  attendance_reminder,
  system_alert,
  general
}

enum NotificationPriority { low, medium, high, urgent }

class NotificationModel {
  final String notificationId;
  final String userId; // recipient user ID
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data; // Additional data for navigation/actions
  final String? actionUrl; // Deep link or route for action
  final String? senderId; // ID of user who triggered the notification
  final String? senderName; // Name of user who triggered the notification

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
    this.actionUrl,
    this.senderId,
    this.senderName,
  }) : assert(notificationId.isNotEmpty, 'notificationId cannot be empty'),
       assert(userId.isNotEmpty, 'userId cannot be empty'),
       assert(title.isNotEmpty, 'title cannot be empty'),
       assert(message.isNotEmpty, 'message cannot be empty');

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
        'data': data,
        'actionUrl': actionUrl,
        'senderId': senderId,
        'senderName': senderName,
      };

  factory NotificationModel.fromMap(Map<String, dynamic> map) => NotificationModel(
        notificationId: map['notificationId'] ?? '',
        userId: map['userId'] ?? '',
        title: map['title'] ?? '',
        message: map['message'] ?? '',
        type: NotificationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => NotificationType.general,
        ),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.name == map['priority'],
          orElse: () => NotificationPriority.medium,
        ),
        isRead: map['isRead'] ?? false,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        readAt: map['readAt'] != null ? (map['readAt'] as Timestamp).toDate() : null,
        data: map['data'],
        actionUrl: map['actionUrl'],
        senderId: map['senderId'],
        senderName: map['senderName'],
      );

  factory NotificationModel.fromDoc(DocumentSnapshot doc) =>
      NotificationModel.fromMap({...doc.data() as Map<String, dynamic>, 'notificationId': doc.id});

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? senderId,
    String? senderName,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
    );
  }

  // Helper methods for notification display
  String get typeDisplayName {
    switch (type) {
      case NotificationType.leave_approved:
        return 'Cuti Disetujui';
      case NotificationType.leave_rejected:
        return 'Cuti Ditolak';
      case NotificationType.task_assigned:
        return 'Tugas Baru';
      case NotificationType.task_completed:
        return 'Tugas Selesai';
      case NotificationType.task_overdue:
        return 'Tugas Terlambat';
      case NotificationType.claim_approved:
        return 'Klaim Disetujui';
      case NotificationType.claim_rejected:
        return 'Klaim Ditolak';
      case NotificationType.payroll_generated:
        return 'Gaji Diproses';
      case NotificationType.attendance_reminder:
        return 'Pengingat Absensi';
      case NotificationType.system_alert:
        return 'Peringatan Sistem';
      case NotificationType.general:
        return 'Umum';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Rendah';
      case NotificationPriority.medium:
        return 'Sedang';
      case NotificationPriority.high:
        return 'Tinggi';
      case NotificationPriority.urgent:
        return 'Mendesak';
    }
  }

  bool get isExpired {
    // Consider notifications older than 30 days as expired
    return DateTime.now().difference(createdAt).inDays > 30;
  }

  bool get isRecent {
    // Consider notifications within last 24 hours as recent
    return DateTime.now().difference(createdAt).inHours <= 24;
  }
}