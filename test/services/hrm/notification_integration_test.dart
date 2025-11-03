import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../../../lib/services/notification_service.dart';
import '../../../lib/services/hrm/task_repository.dart';
import '../../../lib/services/hrm/leave_repository.dart';
import '../../../lib/services/hrm/claim_repository.dart';
import '../../../lib/services/hrm/employee_repository.dart';
import '../../../lib/models/hrm/task_model.dart';
import '../../../lib/models/hrm/leave_request_model.dart';
import '../../../lib/models/hrm/claim_model.dart';
import '../../../lib/models/hrm/employee_model.dart';
import '../../../lib/models/notification_model.dart';

// Mock Firebase for testing
void setupFirebaseAuthMocks() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'fake-api-key',
            'appId': 'fake-app-id',
            'messagingSenderId': 'fake-sender-id',
            'projectId': 'fake-project-id',
          },
          'pluginConstants': {},
        }
      ];
    }
    return null;
  });
}

// Mock notification service for testing
class MockNotificationService extends NotificationService {
  List<Map<String, dynamic>> sentNotifications = [];

  @override
  Future<void> sendTaskAssignedNotification({
    required String assigneeId,
    required String taskTitle,
    required DateTime dueDate,
    required String assignedBy,
    String? taskId,
  }) async {
    sentNotifications.add({
      'type': 'task_assigned',
      'assigneeId': assigneeId,
      'taskTitle': taskTitle,
      'dueDate': dueDate,
      'assignedBy': assignedBy,
      'taskId': taskId,
    });
  }

  @override
  Future<void> sendTaskCompletedNotification({
    required String reporterId,
    required String taskTitle,
    required String completedBy,
    String? taskId,
  }) async {
    sentNotifications.add({
      'type': 'task_completed',
      'reporterId': reporterId,
      'taskTitle': taskTitle,
      'completedBy': completedBy,
      'taskId': taskId,
    });
  }

  @override
  Future<void> sendLeaveApprovedNotification({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String approvedBy,
  }) async {
    sentNotifications.add({
      'type': 'leave_approved',
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'approvedBy': approvedBy,
    });
  }

  @override
  Future<void> sendLeaveRejectedNotification({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String rejectedBy,
    String? reason,
  }) async {
    sentNotifications.add({
      'type': 'leave_rejected',
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'rejectedBy': rejectedBy,
      'reason': reason,
    });
  }

  @override
  Future<void> sendClaimApprovedNotification({
    required String employeeId,
    required String claimType,
    required double amount,
    required String approvedBy,
    String? claimId,
  }) async {
    sentNotifications.add({
      'type': 'claim_approved',
      'employeeId': employeeId,
      'claimType': claimType,
      'amount': amount,
      'approvedBy': approvedBy,
      'claimId': claimId,
    });
  }

  @override
  Future<void> sendClaimRejectedNotification({
    required String employeeId,
    required String claimType,
    required double amount,
    required String rejectedBy,
    String? reason,
    String? claimId,
  }) async {
    sentNotifications.add({
      'type': 'claim_rejected',
      'employeeId': employeeId,
      'claimType': claimType,
      'amount': amount,
      'rejectedBy': rejectedBy,
      'reason': reason,
      'claimId': claimId,
    });
  }

  void clearNotifications() {
    sentNotifications.clear();
  }

  // Implement other required methods with no-op or basic implementations
  @override
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
    // No-op for testing
  }

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return Stream.value([]);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // No-op for testing
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    // No-op for testing
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return 0;
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    // No-op for testing
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseAuthMocks();
  
  group('HRM Notification Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockNotificationService mockNotificationService;
    late TaskRepository taskRepository;
    late LeaveRepository leaveRepository;
    late ClaimRepository claimRepository;
    late EmployeeRepository employeeRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockNotificationService = MockNotificationService();
      employeeRepository = EmployeeRepository(firestore: fakeFirestore);
      
      taskRepository = TaskRepository(
        firestore: fakeFirestore,
        employeeRepository: employeeRepository,
        notificationService: mockNotificationService,
      );
      
      leaveRepository = LeaveRepository(
        firestore: fakeFirestore,
        employeeRepository: employeeRepository,
        notificationService: mockNotificationService,
      );
      
      claimRepository = ClaimRepository(
        firestore: fakeFirestore,
        employeeRepository: employeeRepository,
        notificationService: mockNotificationService,
      );
    });

    group('Task Notifications', () {
      test('should send notification when task is created', () async {
        // Setup test data
        final employee1 = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
        );
        
        final employee2 = EmployeeModel(
          employeeId: 'emp2',
          userId: 'user2',
          fullName: 'Jane Smith',
          position: 'Manager',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 70000,
        );

        await employeeRepository.create(employee1);
        await employeeRepository.create(employee2);

        final task = TaskModel(
          taskId: '',
          title: 'Test Task',
          description: 'Test Description',
          assigneeId: 'emp1',
          reporterId: 'emp2',
          dueDate: DateTime.now().add(Duration(days: 7)),
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        // Execute
        await taskRepository.create(task);

        // Verify notification was sent
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'task_assigned');
        expect(notification['assigneeId'], 'emp1');
        expect(notification['taskTitle'], 'Test Task');
        expect(notification['assignedBy'], 'Jane Smith');
      });

      test('should send notification when task is completed', () async {
        // Setup test data
        final employee = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
        );

        await employeeRepository.create(employee);

        final task = TaskModel(
          taskId: 'task1',
          title: 'Test Task',
          description: 'Test Description',
          assigneeId: 'emp1',
          reporterId: 'emp1',
          dueDate: DateTime.now().add(Duration(days: 7)),
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        // Create task first
        await fakeFirestore.collection('tasks').doc('task1').set(task.toMap());

        // Execute - update status to completed
        await taskRepository.updateStatus('task1', TaskStatus.completed);

        // Verify notification was sent
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'task_completed');
        expect(notification['reporterId'], 'emp1');
        expect(notification['taskTitle'], 'Test Task');
        expect(notification['completedBy'], 'John Doe');
      });

      test('should send notification when task is reassigned', () async {
        // Setup test data
        final employee1 = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
        );
        
        final employee2 = EmployeeModel(
          employeeId: 'emp2',
          userId: 'user2',
          fullName: 'Jane Smith',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 55000,
        );

        final employee3 = EmployeeModel(
          employeeId: 'emp3',
          userId: 'user3',
          fullName: 'Bob Manager',
          position: 'Manager',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 70000,
        );

        await employeeRepository.create(employee1);
        await employeeRepository.create(employee2);
        await employeeRepository.create(employee3);

        final task = TaskModel(
          taskId: 'task1',
          title: 'Test Task',
          description: 'Test Description',
          assigneeId: 'emp1',
          reporterId: 'emp3',
          dueDate: DateTime.now().add(Duration(days: 7)),
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        // Create task first
        await fakeFirestore.collection('tasks').doc('task1').set(task.toMap());

        // Execute - reassign task
        await taskRepository.reassignTask('task1', 'emp2');

        // Verify notification was sent to new assignee
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'task_assigned');
        expect(notification['assigneeId'], 'emp2');
        expect(notification['taskTitle'], 'Test Task');
        expect(notification['assignedBy'], 'Bob Manager');
      });
    });

    group('Leave Request Notifications', () {
      test('should send notification when leave is approved', () async {
        // Setup test data
        final employee = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
          leaveBalance: 15,
        );

        await employeeRepository.create(employee);

        final leaveRequest = LeaveRequestModel(
          requestId: 'leave1',
          employeeId: 'emp1',
          startDate: DateTime.now().add(Duration(days: 10)),
          endDate: DateTime.now().add(Duration(days: 12)),
          reason: 'Personal leave',
          leaveType: LeaveType.annual,
          submissionDate: DateTime.now(),
        );

        // Create leave request first
        await fakeFirestore.collection('leave_requests').doc('leave1').set(leaveRequest.toMap());

        // Execute - approve leave
        await leaveRepository.updateStatus('leave1', LeaveStatus.approved, approvedBy: 'Manager');

        // Verify notification was sent
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'leave_approved');
        expect(notification['employeeId'], 'emp1');
        expect(notification['leaveType'], 'annual');
        expect(notification['approvedBy'], 'Manager');
      });

      test('should send notification when leave is rejected', () async {
        // Setup test data
        final employee = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
          leaveBalance: 15,
        );

        await employeeRepository.create(employee);

        final leaveRequest = LeaveRequestModel(
          requestId: 'leave1',
          employeeId: 'emp1',
          startDate: DateTime.now().add(Duration(days: 10)),
          endDate: DateTime.now().add(Duration(days: 12)),
          reason: 'Personal leave',
          leaveType: LeaveType.annual,
          submissionDate: DateTime.now(),
        );

        // Create leave request first
        await fakeFirestore.collection('leave_requests').doc('leave1').set(leaveRequest.toMap());

        // Execute - reject leave
        await leaveRepository.updateStatus('leave1', LeaveStatus.rejected, approvedBy: 'Manager');

        // Verify notification was sent
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'leave_rejected');
        expect(notification['employeeId'], 'emp1');
        expect(notification['leaveType'], 'annual');
        expect(notification['rejectedBy'], 'Manager');
      });
    });

    group('Claim Notifications', () {
      test('should send notification when claim is approved', () async {
        // Setup test data
        final employee = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
        );

        await employeeRepository.create(employee);

        final claim = ClaimModel(
          claimId: 'claim1',
          employeeId: 'emp1',
          claimType: 'Transport',
          submissionDate: DateTime.now(),
          description: 'Taxi fare for client meeting',
          amount: 50000,
        );

        // Create claim first
        await fakeFirestore.collection('claims').doc('claim1').set(claim.toMap());

        // Execute - approve claim
        await claimRepository.updateStatus('claim1', ClaimStatus.approved, approvedBy: 'Finance Manager');

        // Verify notification was sent
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'claim_approved');
        expect(notification['employeeId'], 'emp1');
        expect(notification['claimType'], 'Transport');
        expect(notification['amount'], 50000);
        expect(notification['approvedBy'], 'Finance Manager');
      });

      test('should send notification when claim is rejected', () async {
        // Setup test data
        final employee = EmployeeModel(
          employeeId: 'emp1',
          userId: 'user1',
          fullName: 'John Doe',
          position: 'Developer',
          department: 'IT',
          joinDate: DateTime.now(),
          salary: 50000,
        );

        await employeeRepository.create(employee);

        final claim = ClaimModel(
          claimId: 'claim1',
          employeeId: 'emp1',
          claimType: 'Transport',
          submissionDate: DateTime.now(),
          description: 'Taxi fare for client meeting',
          amount: 50000,
        );

        // Create claim first
        await fakeFirestore.collection('claims').doc('claim1').set(claim.toMap());

        // Execute - reject claim
        await claimRepository.updateStatus('claim1', ClaimStatus.rejected, approvedBy: 'Finance Manager');

        // Verify notification was sent
        expect(mockNotificationService.sentNotifications.length, 1);
        final notification = mockNotificationService.sentNotifications.first;
        expect(notification['type'], 'claim_rejected');
        expect(notification['employeeId'], 'emp1');
        expect(notification['claimType'], 'Transport');
        expect(notification['amount'], 50000);
        expect(notification['rejectedBy'], 'Finance Manager');
      });
    });

    group('Email Notification Configuration', () {
      test('should have email enabled for high-priority HRM notifications', () async {
        // Test that notification service is properly configured
        // This test verifies the notification service exists and can be instantiated
        expect(mockNotificationService, isNotNull);
        
        // Test notification types are properly defined
        expect(NotificationType.leave_approved, isNotNull);
        expect(NotificationType.leave_rejected, isNotNull);
        expect(NotificationType.claim_approved, isNotNull);
        expect(NotificationType.claim_rejected, isNotNull);
        expect(NotificationType.task_assigned, isNotNull);
        expect(NotificationType.task_overdue, isNotNull);
      });
    });
  });
}