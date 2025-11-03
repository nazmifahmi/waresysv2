import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';
import '../models/hrm/employee_model.dart';
import '../models/user_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  
  NotificationService() : 
    _firestore = FirebaseFirestore.instance,
    _messaging = FirebaseMessaging.instance;

  NotificationService.withFirestore(FirebaseFirestore firestore) :
    _firestore = firestore,
    _messaging = FirebaseMessaging.instance;

  // Collections
  CollectionReference get _notifications => _firestore.collection('notifications');
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _employees => _firestore.collection('employees');

  /// Initialize Firebase Messaging
  Future<void> initializeMessaging() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission for notifications');
      } else {
        debugPrint('User declined or has not accepted permission for notifications');
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Store token in user document for sending targeted notifications
        // This would be called after user login
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        // Update token in user document
      });

    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  /// Store FCM token for a user
  Future<void> storeFCMToken(String userId, String token) async {
    try {
      await _users.doc(userId).update({
        'fcmToken': token,
        'tokenUpdatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  /// Create and send notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? senderId,
    String? senderName,
    bool sendPush = true,
    bool sendEmail = false,
  }) async {
    try {
      // Create notification document
      final notification = NotificationModel(
        notificationId: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        data: data,
        actionUrl: actionUrl,
        senderId: senderId,
        senderName: senderName,
      );

      // Add to Firestore
      final docRef = await _notifications.add(notification.toMap());
      
      // Send push notification if enabled
      if (sendPush) {
        await _sendPushNotification(userId, title, message, data);
      }

      // Send email notification if enabled
      if (sendEmail) {
        await _sendEmailNotification(userId, title, message, type);
      }

      debugPrint('Notification created: ${docRef.id}');
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Send push notification to specific user
  Future<void> _sendPushNotification(
    String userId, 
    String title, 
    String message, 
    Map<String, dynamic>? data
  ) async {
    try {
      // Get user's FCM token
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;
      
      if (fcmToken == null) {
        debugPrint('No FCM token found for user: $userId');
        return;
      }

      // Note: In a production app, you would send this to your backend server
      // which would use the Firebase Admin SDK to send the push notification
      // For now, we'll just log the notification details
      debugPrint('Would send push notification to token: $fcmToken');
      debugPrint('Title: $title, Message: $message, Data: $data');
      
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  /// Send email notification to specific user
  Future<void> _sendEmailNotification(
    String userId,
    String title,
    String message,
    NotificationType type,
  ) async {
    try {
      // Get user's email from user document
      final userDoc = await _users.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userEmail = userData['email'] as String?;
      
      if (userEmail == null) {
        debugPrint('No email found for user: $userId');
        return;
      }

      // Check if this notification type should trigger email
      if (!_shouldSendEmail(type)) {
        debugPrint('Email not required for notification type: ${type.name}');
        return;
      }

      // In a production environment, you would integrate with an email service
      // like SendGrid, AWS SES, or similar. For now, we'll log the email details
      debugPrint('Would send email notification to: $userEmail');
      debugPrint('Subject: $title');
      debugPrint('Body: $message');
      debugPrint('Type: ${type.name}');

      // Example implementation with a hypothetical email service:
      // await _sendEmailViaService(userEmail, title, message, type);
      
    } catch (e) {
      debugPrint('Error sending email notification: $e');
    }
  }

  /// Determine if email should be sent for this notification type
  bool _shouldSendEmail(NotificationType type) {
    // Send email for high-priority HRM notifications
    switch (type) {
      case NotificationType.leave_approved:
      case NotificationType.leave_rejected:
      case NotificationType.claim_approved:
      case NotificationType.claim_rejected:
      case NotificationType.task_assigned:
      case NotificationType.payroll_generated:
        return true;
      case NotificationType.task_overdue:
        return true;
      default:
        return false;
    }
  }

  /// Example method for integrating with external email service
  Future<void> _sendEmailViaService(
    String email,
    String subject,
    String body,
    NotificationType type,
  ) async {
    try {
      // This is a placeholder for actual email service integration
      // You would replace this with your chosen email service API
      
      final emailData = {
        'to': email,
        'subject': subject,
        'html': _buildEmailTemplate(subject, body, type),
        'from': 'noreply@waresys.com',
      };

      // Example API call (replace with actual service)
      // final response = await http.post(
      //   Uri.parse('https://api.emailservice.com/send'),
      //   headers: {
      //     'Authorization': 'Bearer YOUR_API_KEY',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode(emailData),
      // );

      debugPrint('Email service integration placeholder called');
      debugPrint('Email data: $emailData');
      
    } catch (e) {
      debugPrint('Error with email service: $e');
    }
  }

  /// Build HTML email template
  String _buildEmailTemplate(String subject, String body, NotificationType type) {
    final typeColor = _getNotificationTypeColor(type);
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>$subject</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { background-color: $typeColor; color: white; padding: 20px; text-align: center; }
            .content { padding: 30px; }
            .footer { background-color: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; }
            .button { display: inline-block; padding: 12px 24px; background-color: $typeColor; color: white; text-decoration: none; border-radius: 4px; margin-top: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>WARESYS</h1>
                <h2>$subject</h2>
            </div>
            <div class="content">
                <p>$body</p>
                <p>Silakan login ke aplikasi WARESYS untuk melihat detail lebih lanjut.</p>
                <a href="#" class="button">Buka Aplikasi</a>
            </div>
            <div class="footer">
                <p>Email ini dikirim secara otomatis oleh sistem WARESYS.</p>
                <p>Jangan membalas email ini.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Get color for notification type
  String _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.leave_approved:
      case NotificationType.claim_approved:
        return '#4CAF50'; // Green
      case NotificationType.leave_rejected:
      case NotificationType.claim_rejected:
        return '#F44336'; // Red
      case NotificationType.task_assigned:
        return '#2196F3'; // Blue
      case NotificationType.task_overdue:
        return '#FF9800'; // Orange
      case NotificationType.payroll_generated:
        return '#9C27B0'; // Purple
      default:
        return '#607D8B'; // Blue Grey
    }
  }

  /// Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromDoc(doc))
            .toList());
  }

  /// Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notifications
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notifications.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notifications
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // HRM-specific notification methods

  /// Send leave approval notification
  Future<void> sendLeaveApprovedNotification({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String approvedBy,
  }) async {
    await createNotification(
      userId: employeeId,
      title: 'Cuti Disetujui',
      message: 'Permohonan cuti $leaveType Anda dari ${_formatDate(startDate)} sampai ${_formatDate(endDate)} telah disetujui.',
      type: NotificationType.leave_approved,
      priority: NotificationPriority.high,
      data: {
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
      actionUrl: '/hrm/leave-requests',
      senderName: approvedBy,
      sendEmail: true, // Enable email for leave approvals
    );
  }

  /// Send leave rejection notification
  Future<void> sendLeaveRejectedNotification({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String rejectedBy,
    String? reason,
  }) async {
    await createNotification(
      userId: employeeId,
      title: 'Cuti Ditolak',
      message: 'Permohonan cuti $leaveType Anda dari ${_formatDate(startDate)} sampai ${_formatDate(endDate)} ditolak.${reason != null ? ' Alasan: $reason' : ''}',
      type: NotificationType.leave_rejected,
      priority: NotificationPriority.high,
      data: {
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      },
      actionUrl: '/hrm/leave-requests',
      senderName: rejectedBy,
    );
  }

  /// Send task assignment notification
  Future<void> sendTaskAssignedNotification({
    required String assigneeId,
    required String taskTitle,
    required DateTime dueDate,
    required String assignedBy,
    String? taskId,
  }) async {
    await createNotification(
      userId: assigneeId,
      title: 'Tugas Baru Diberikan',
      message: 'Anda mendapat tugas baru: "$taskTitle". Tenggat: ${_formatDate(dueDate)}',
      type: NotificationType.task_assigned,
      priority: NotificationPriority.medium,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'dueDate': dueDate.toIso8601String(),
      },
      actionUrl: '/hrm/my-tasks',
      senderName: assignedBy,
      sendEmail: true, // Enable email for task assignments
    );
  }

  /// Send task completion notification
  Future<void> sendTaskCompletedNotification({
    required String reporterId,
    required String taskTitle,
    required String completedBy,
    String? taskId,
  }) async {
    await createNotification(
      userId: reporterId,
      title: 'Tugas Diselesaikan',
      message: 'Tugas "$taskTitle" telah diselesaikan oleh $completedBy.',
      type: NotificationType.task_completed,
      priority: NotificationPriority.medium,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
      },
      actionUrl: '/hrm/task-dashboard',
      senderName: completedBy,
    );
  }

  /// Send task overdue notification
  Future<void> sendTaskOverdueNotification({
    required String assigneeId,
    required String taskTitle,
    required DateTime dueDate,
    String? taskId,
  }) async {
    await createNotification(
      userId: assigneeId,
      title: 'Tugas Terlambat',
      message: 'Tugas "$taskTitle" telah melewati tenggat waktu (${_formatDate(dueDate)}).',
      type: NotificationType.task_overdue,
      priority: NotificationPriority.urgent,
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'dueDate': dueDate.toIso8601String(),
      },
      actionUrl: '/hrm/my-tasks',
    );
  }

  /// Send claim approval notification
  Future<void> sendClaimApprovedNotification({
    required String employeeId,
    required String claimType,
    required double amount,
    required String approvedBy,
    String? claimId,
  }) async {
    await createNotification(
      userId: employeeId,
      title: 'Klaim Disetujui',
      message: 'Klaim $claimType sebesar Rp ${_formatCurrency(amount)} telah disetujui.',
      type: NotificationType.claim_approved,
      priority: NotificationPriority.high,
      data: {
        'claimId': claimId,
        'claimType': claimType,
        'amount': amount,
      },
      actionUrl: '/hrm/claims',
      senderName: approvedBy,
      sendEmail: true, // Enable email for claim approvals
    );
  }

  /// Send claim rejection notification
  Future<void> sendClaimRejectedNotification({
    required String employeeId,
    required String claimType,
    required double amount,
    required String rejectedBy,
    String? reason,
    String? claimId,
  }) async {
    await createNotification(
      userId: employeeId,
      title: 'Klaim Ditolak',
      message: 'Klaim $claimType sebesar Rp ${_formatCurrency(amount)} ditolak.${reason != null ? ' Alasan: $reason' : ''}',
      type: NotificationType.claim_rejected,
      priority: NotificationPriority.high,
      data: {
        'claimId': claimId,
        'claimType': claimType,
        'amount': amount,
        'reason': reason,
      },
      actionUrl: '/hrm/claims',
      senderName: rejectedBy,
      sendEmail: true, // Enable email for claim rejections
    );
  }

  /// Send payroll generated notification
  Future<void> sendPayrollGeneratedNotification({
    required String employeeId,
    required String month,
    required double totalSalary,
  }) async {
    await createNotification(
      userId: employeeId,
      title: 'Gaji Diproses',
      message: 'Gaji bulan $month sebesar Rp ${_formatCurrency(totalSalary)} telah diproses.',
      type: NotificationType.payroll_generated,
      priority: NotificationPriority.medium,
      data: {
        'month': month,
        'totalSalary': totalSalary,
      },
      actionUrl: '/hrm/payroll',
    );
  }

  /// Send attendance reminder notification
  Future<void> sendAttendanceReminderNotification({
    required String employeeId,
    required String reminderType, // 'check_in' or 'check_out'
  }) async {
    final message = reminderType == 'check_in' 
        ? 'Jangan lupa untuk melakukan check-in hari ini.'
        : 'Jangan lupa untuk melakukan check-out sebelum pulang.';

    await createNotification(
      userId: employeeId,
      title: 'Pengingat Absensi',
      message: message,
      type: NotificationType.attendance_reminder,
      priority: NotificationPriority.low,
      data: {
        'reminderType': reminderType,
      },
      actionUrl: '/hrm/attendance',
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Get employee details for notifications
  Future<EmployeeModel?> _getEmployee(String employeeId) async {
    try {
      final doc = await _employees.doc(employeeId).get();
      if (doc.exists) {
        return EmployeeModel.fromDoc(doc);
      }
    } catch (e) {
      debugPrint('Error getting employee: $e');
    }
    return null;
  }

  /// Send payroll approval update notification
  Future<void> sendPayrollApprovalUpdateNotification({
    required String payrollId,
    required String employeeId,
    required String action,
    required String approverName,
    String? comments,
  }) async {
    String title;
    String message;
    
    switch (action) {
      case 'approve':
        title = 'Payroll Disetujui';
        message = 'Payroll Anda telah disetujui oleh $approverName';
        break;
      case 'reject':
        title = 'Payroll Ditolak';
        message = 'Payroll Anda ditolak oleh $approverName';
        if (comments != null) {
          message += '. Alasan: $comments';
        }
        break;
      default:
        title = 'Update Payroll';
        message = 'Payroll Anda telah diupdate oleh $approverName';
    }

    await createNotification(
      userId: employeeId,
      title: title,
      message: message,
      type: NotificationType.payroll_generated,
      priority: NotificationPriority.high,
      data: {
        'payrollId': payrollId,
        'action': action,
        'approverName': approverName,
        'comments': comments,
      },
      actionUrl: '/hrm/payroll',
      senderName: approverName,
      sendEmail: true,
    );
  }

  /// Send payroll approval request notification
  Future<void> sendPayrollApprovalRequestNotification({
    required String payrollId,
    required String approverId,
    required String employeeName,
    required String month,
    required double amount,
  }) async {
    await createNotification(
      userId: approverId,
      title: 'Permintaan Persetujuan Payroll',
      message: 'Payroll $employeeName untuk bulan $month (Rp ${_formatCurrency(amount)}) memerlukan persetujuan Anda',
      type: NotificationType.payroll_generated,
      priority: NotificationPriority.medium,
      data: {
        'payrollId': payrollId,
        'employeeName': employeeName,
        'month': month,
        'amount': amount,
      },
      actionUrl: '/hrm/payroll/approvals',
      sendEmail: true,
    );
  }

  /// Send payroll approved notification
  Future<void> sendPayrollApprovedNotification({
    required String employeeId,
    required String month,
    required double amount,
    required String approverName,
  }) async {
    await createNotification(
      userId: employeeId,
      title: 'Payroll Disetujui',
      message: 'Payroll bulan $month sebesar Rp ${_formatCurrency(amount)} telah disetujui oleh $approverName',
      type: NotificationType.payroll_generated,
      priority: NotificationPriority.high,
      data: {
        'month': month,
        'amount': amount,
        'approverName': approverName,
      },
      actionUrl: '/hrm/payroll',
      senderName: approverName,
      sendEmail: true,
    );
  }

  /// Send payroll rejected notification
  Future<void> sendPayrollRejectedNotification({
    required String employeeId,
    required String month,
    required double amount,
    required String approverName,
    String? reason,
  }) async {
    String message = 'Payroll bulan $month sebesar Rp ${_formatCurrency(amount)} ditolak oleh $approverName';
    if (reason != null) {
      message += '. Alasan: $reason';
    }

    await createNotification(
      userId: employeeId,
      title: 'Payroll Ditolak',
      message: message,
      type: NotificationType.payroll_generated,
      priority: NotificationPriority.high,
      data: {
        'month': month,
        'amount': amount,
        'approverName': approverName,
        'reason': reason,
      },
      actionUrl: '/hrm/payroll',
      senderName: approverName,
      sendEmail: true,
    );
  }

  /// Send bulk notifications to multiple users
  Future<void> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? senderId,
    String? senderName,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (String userId in userIds) {
        final notification = NotificationModel(
          notificationId: '',
          userId: userId,
          title: title,
          message: message,
          type: type,
          priority: priority,
          createdAt: DateTime.now(),
          data: data,
          actionUrl: actionUrl,
          senderId: senderId,
          senderName: senderName,
        );

        final docRef = _notifications.doc();
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
      debugPrint('Bulk notifications sent to ${userIds.length} users');
    } catch (e) {
      debugPrint('Error sending bulk notifications: $e');
    }
  }
}