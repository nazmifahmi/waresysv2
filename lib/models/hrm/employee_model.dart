import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeStatus { active, inactive }
enum EmployeeRole { employee, manager, admin }

class EmployeeModel {
  final String employeeId;
  final String userId;
  final String fullName;
  final String position;
  final String department;
  final DateTime joinDate;
  final double salary;
  final String? contractUrl;
  final EmployeeStatus status;
  final EmployeeRole role;
  final int leaveBalance;

  EmployeeModel({
    required this.employeeId,
    required this.userId,
    required this.fullName,
    required this.position,
    required this.department,
    required this.joinDate,
    required this.salary,
    this.contractUrl,
    this.status = EmployeeStatus.active,
    this.role = EmployeeRole.employee,
    this.leaveBalance = 12,
  }) : assert(fullName.isNotEmpty, 'fullName cannot be empty'),
       assert(position.isNotEmpty, 'position cannot be empty'),
       assert(department.isNotEmpty, 'department cannot be empty'),
       assert(salary >= 0, 'salary must be >= 0');

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'userId': userId,
        'fullName': fullName,
        'position': position,
        'department': department,
        'joinDate': Timestamp.fromDate(joinDate),
        'salary': salary,
        'contractUrl': contractUrl,
        'status': status.name,
        'role': role.name,
        'leaveBalance': leaveBalance,
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> map) => EmployeeModel(
        employeeId: map['employeeId']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        fullName: (map['fullName']?.toString().trim().isNotEmpty == true)
            ? map['fullName'].toString().trim()
            : 'Unknown',
        position: (map['position']?.toString().trim().isNotEmpty == true)
            ? map['position'].toString().trim()
            : 'N/A',
        department: (map['department']?.toString().trim().isNotEmpty == true)
            ? map['department'].toString().trim()
            : 'N/A',
        joinDate: (map['joinDate'] is Timestamp)
            ? (map['joinDate'] as Timestamp).toDate()
            : DateTime.now(),
        salary: (map['salary'] as num?)?.toDouble() ?? 0.0,
        contractUrl: map['contractUrl']?.toString(),
        status: EmployeeStatus.values.firstWhere(
          (e) => e.name == (map['status'] ?? EmployeeStatus.active.name),
          orElse: () => EmployeeStatus.active,
        ),
        role: EmployeeRole.values.firstWhere(
          (e) => e.name == (map['role'] ?? EmployeeRole.employee.name),
          orElse: () => EmployeeRole.employee,
        ),
        leaveBalance: (map['leaveBalance'] is int) ? map['leaveBalance'] as int : 12,
      );

  factory EmployeeModel.fromDoc(DocumentSnapshot doc) =>
      EmployeeModel.fromMap({...doc.data() as Map<String, dynamic>, 'employeeId': doc.id});
}