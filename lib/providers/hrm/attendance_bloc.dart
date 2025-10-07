import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/hrm/attendance_model.dart';
import '../../services/hrm/attendance_repository.dart';

enum AttendanceButtonState { idle, canCheckIn, canCheckOut, loading, error }

class AttendanceBloc {
  final AttendanceRepository _repo;
  final String employeeId;

  final StreamController<AttendanceButtonState> _stateController = StreamController.broadcast();
  final StreamController<String?> _errorController = StreamController.broadcast();

  String? _todayAttendanceId;

  AttendanceBloc({required AttendanceRepository repository, required this.employeeId})
      : _repo = repository {
    _init();
  }

  Stream<AttendanceButtonState> get state => _stateController.stream;
  Stream<String?> get error => _errorController.stream;

  Future<void> _init() async {
    _stateController.add(AttendanceButtonState.loading);
    final today = DateTime.now();
    final existing = await _repo.getTodayAttendance(employeeId, today);
    if (existing == null) {
      _todayAttendanceId = null;
      _stateController.add(AttendanceButtonState.canCheckIn);
    } else if (existing.checkOutTimestamp == null) {
      _todayAttendanceId = existing.attendanceId;
      _stateController.add(AttendanceButtonState.canCheckOut);
    } else {
      _todayAttendanceId = existing.attendanceId;
      _stateController.add(AttendanceButtonState.idle);
    }
  }

  Future<void> checkIn() async {
    try {
      _stateController.add(AttendanceButtonState.loading);

      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _errorController.add('Izin lokasi ditolak');
        _stateController.add(AttendanceButtonState.canCheckIn);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final now = DateTime.now();
      final isLate = now.hour > 8 || (now.hour == 8 && now.minute > 0);

      final id = await _repo.checkIn(
        employeeId: employeeId,
        checkInTime: now,
        location: GeoPoint(position.latitude, position.longitude),
        isLate: isLate,
      );
      _todayAttendanceId = id;
      _stateController.add(AttendanceButtonState.canCheckOut);
    } catch (e) {
      _errorController.add(e.toString());
      _stateController.add(AttendanceButtonState.canCheckIn);
    }
  }

  Future<void> checkOut() async {
    if (_todayAttendanceId == null) return;
    try {
      _stateController.add(AttendanceButtonState.loading);
      await _repo.checkOut(attendanceId: _todayAttendanceId!, checkOutTime: DateTime.now());
      _stateController.add(AttendanceButtonState.idle);
    } catch (e) {
      _errorController.add(e.toString());
      _stateController.add(AttendanceButtonState.canCheckOut);
    }
  }

  void dispose() {
    _stateController.close();
    _errorController.close();
  }
}