import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hrm/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('attendance');

  Stream<AttendanceModel?> watchTodayAttendance(String employeeId) {
    try {
      print('AttendanceRepository: Watching today attendance for employeeId: $employeeId');
      
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      
      print('AttendanceRepository: Watching from $start to $end');
      
      return _col
          .where('employeeId', isEqualTo: employeeId)
          .where('checkInTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('checkInTimestamp', isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              print('AttendanceRepository: No attendance found for today');
              return null;
            }
            
            final attendance = AttendanceModel.fromDoc(snapshot.docs.first);
            print('AttendanceRepository: Found attendance: ${attendance.toMap()}');
            return attendance;
          });
    } catch (e) {
      print('AttendanceRepository: Error in watchTodayAttendance: $e');
      return Stream.error(e);
    }
  }

  Future<AttendanceModel?> getTodayAttendance(String employeeId, DateTime now) async {
    try {
      print('AttendanceRepository: Getting today attendance for employeeId: $employeeId');
      
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      
      print('AttendanceRepository: Querying from $start to $end');
      
      final snap = await _col
          .where('employeeId', isEqualTo: employeeId)
          .where('checkInTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('checkInTimestamp', isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .get();
          
      print('AttendanceRepository: Found ${snap.docs.length} documents');
      
      if (snap.docs.isEmpty) return null;
      
      final attendance = AttendanceModel.fromDoc(snap.docs.first);
      print('AttendanceRepository: Returning attendance: ${attendance.toMap()}');
      
      return attendance;
    } catch (e) {
      print('AttendanceRepository: Error in getTodayAttendance: $e');
      rethrow;
    }
  }

  Future<String> checkIn({
    required String employeeId,
    required DateTime checkInTime,
    required GeoPoint location,
    required bool isLate,
  }) async {
    try {
      print('AttendanceRepository: Starting checkIn for employeeId: $employeeId');
      
      final attendanceId = _firestore.collection('attendance').doc().id;
      print('AttendanceRepository: Generated attendanceId: $attendanceId');
      
      final attendance = AttendanceModel(
        attendanceId: attendanceId,
        employeeId: employeeId,
        date: DateTime(checkInTime.year, checkInTime.month, checkInTime.day),
        checkInTimestamp: checkInTime,
        checkInLocation: location,
        status: isLate ? AttendanceStatus.late : AttendanceStatus.present,
      );
      
      print('AttendanceRepository: Creating attendance record: ${attendance.toMap()}');
      
      await _firestore.collection('attendance').doc(attendanceId).set(attendance.toMap());
      
      print('AttendanceRepository: Check-in successful, returning ID: $attendanceId');
      return attendanceId;
    } catch (e) {
      print('AttendanceRepository: Error in checkIn: $e');
      rethrow;
    }
  }

  Future<void> checkOut({
    required String attendanceId,
    required DateTime checkOutTime,
    GeoPoint? location,
  }) async {
    final doc = await _firestore.collection('attendance').doc(attendanceId).get();
    if (!doc.exists) throw Exception('Attendance record not found');
    
    final attendance = AttendanceModel.fromMap(doc.data()!);
    final workingHours = attendance.checkInTimestamp != null 
        ? checkOutTime.difference(attendance.checkInTimestamp!).inMinutes
        : null;
    
    await _firestore.collection('attendance').doc(attendanceId).update({
      'checkOutTimestamp': Timestamp.fromDate(checkOutTime),
      'checkOutLocation': location,
      'workingHours': workingHours,
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