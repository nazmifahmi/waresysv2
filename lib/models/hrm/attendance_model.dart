import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, late, absent }

class AttendanceModel {
  final String attendanceId;
  final String employeeId;
  final DateTime date;
  final DateTime? checkInTimestamp;
  final DateTime? checkOutTimestamp;
  final GeoPoint? checkInLocation;
  final GeoPoint? checkOutLocation;
  final AttendanceStatus? status;
  final int? workingHours; // in minutes

  AttendanceModel({
    required this.attendanceId,
    required this.employeeId,
    required this.date,
    this.checkInTimestamp,
    this.checkOutTimestamp,
    this.checkInLocation,
    this.checkOutLocation,
    this.status,
    this.workingHours,
  });

  Map<String, dynamic> toMap() => {
        'attendanceId': attendanceId,
        'employeeId': employeeId,
        'date': Timestamp.fromDate(date),
        'checkInTimestamp': checkInTimestamp != null ? Timestamp.fromDate(checkInTimestamp!) : null,
        'checkOutTimestamp': checkOutTimestamp != null ? Timestamp.fromDate(checkOutTimestamp!) : null,
        'checkInLocation': checkInLocation,
        'checkOutLocation': checkOutLocation,
        'status': status?.name,
        'workingHours': workingHours,
      };

  factory AttendanceModel.fromMap(Map<String, dynamic> map) => AttendanceModel(
        attendanceId: map['attendanceId'],
        employeeId: map['employeeId'],
        date: (map['date'] as Timestamp).toDate(),
        checkInTimestamp: (map['checkInTimestamp'] as Timestamp?)?.toDate(),
        checkOutTimestamp: (map['checkOutTimestamp'] as Timestamp?)?.toDate(),
        checkInLocation: map['checkInLocation'],
        checkOutLocation: map['checkOutLocation'],
        status: map['status'] != null
            ? AttendanceStatus.values.firstWhere((e) => e.name == map['status'])
            : null,
        workingHours: map['workingHours'],
      );

  factory AttendanceModel.fromDoc(DocumentSnapshot doc) =>
      AttendanceModel.fromMap({...doc.data() as Map<String, dynamic>, 'attendanceId': doc.id});
}