import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeStatus { active, inactive }

class EmployeeModel {
  final String employeeId;
  final String userId;
  final String fullName;
  final String position;
  final DateTime joinDate;
  final double salary;
  final String? contractUrl;
  final EmployeeStatus status;

  EmployeeModel({
    required this.employeeId,
    required this.userId,
    required this.fullName,
    required this.position,
    required this.joinDate,
    required this.salary,
    this.contractUrl,
    this.status = EmployeeStatus.active,
  }) : assert(employeeId.isNotEmpty, 'employeeId cannot be empty'),
       assert(userId.isNotEmpty, 'userId cannot be empty'),
       assert(fullName.isNotEmpty, 'fullName cannot be empty'),
       assert(position.isNotEmpty, 'position cannot be empty'),
       assert(salary >= 0, 'salary must be >= 0');

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'userId': userId,
        'fullName': fullName,
        'position': position,
        'joinDate': Timestamp.fromDate(joinDate),
        'salary': salary,
        'contractUrl': contractUrl,
        'status': status.name,
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> map) => EmployeeModel(
        employeeId: map['employeeId'],
        userId: map['userId'],
        fullName: map['fullName'],
        position: map['position'],
        joinDate: (map['joinDate'] as Timestamp).toDate(),
        salary: (map['salary'] as num).toDouble(),
        contractUrl: map['contractUrl'],
        status: EmployeeStatus.values.firstWhere(
          (e) => e.name == (map['status'] ?? EmployeeStatus.active.name),
          orElse: () => EmployeeStatus.active,
        ),
      );

  factory EmployeeModel.fromDoc(DocumentSnapshot doc) =>
      EmployeeModel.fromMap({...doc.data() as Map<String, dynamic>, 'employeeId': doc.id});
}