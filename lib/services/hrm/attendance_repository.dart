import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('attendance');

  Future<AttendanceModel?> getTodayAttendance(String employeeId, DateTime now) async {
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _col
        .where('employeeId', isEqualTo: employeeId)
        .where('checkInTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('checkInTimestamp', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AttendanceModel.fromDoc(snap.docs.first);
  }

  Future<String> checkIn({
    required String employeeId,
    required DateTime checkInTime,
    required GeoPoint location,
    required bool isLate,
  }) async {
    final date = DateTime(checkInTime.year, checkInTime.month, checkInTime.day);
    final ref = await _col.add({
      'employeeId': employeeId,
      'checkInTimestamp': Timestamp.fromDate(checkInTime),
      'checkInLocation': location,
      'date': Timestamp.fromDate(date),
      'status': isLate ? AttendanceStatus.late.name : AttendanceStatus.present.name,
    });
    await _col.doc(ref.id).update({'attendanceId': ref.id});
    return ref.id;
  }

  Future<void> checkOut({
    required String attendanceId,
    required DateTime checkOutTime,
  }) async {
    await _col.doc(attendanceId).update({
      'checkOutTimestamp': Timestamp.fromDate(checkOutTime),
    });
  }

  Stream<List<AttendanceModel>> watchMonthly(String employeeId, DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _col
        .where('employeeId', isEqualTo: employeeId)
        .where('checkInTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('checkInTimestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('checkInTimestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AttendanceModel.fromDoc(d)).toList());
  }
}