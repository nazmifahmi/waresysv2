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
    try {
      _stateController.add(AttendanceButtonState.loading);
      print('AttendanceBloc: Initializing for employeeId: $employeeId');
      
      final today = DateTime.now();
      print('AttendanceBloc: Getting today attendance for date: $today');
      
      final existing = await _repo.getTodayAttendance(employeeId, today);
      print('AttendanceBloc: Existing attendance: ${existing?.toMap()}');
      
      if (existing == null) {
        _todayAttendanceId = null;
        _stateController.add(AttendanceButtonState.canCheckIn);
        print('AttendanceBloc: No existing attendance, can check in');
      } else if (existing.checkOutTimestamp == null) {
        _todayAttendanceId = existing.attendanceId;
        _stateController.add(AttendanceButtonState.canCheckOut);
        print('AttendanceBloc: Already checked in, can check out');
      } else {
        _todayAttendanceId = existing.attendanceId;
        _stateController.add(AttendanceButtonState.idle);
        print('AttendanceBloc: Already completed attendance for today');
      }
    } catch (e) {
      print('AttendanceBloc: Error in _init: $e');
      _errorController.add('Gagal memuat data absensi: $e');
      _stateController.add(AttendanceButtonState.error);
    }
  }

  Future<void> checkIn() async {
    try {
      print('AttendanceBloc: Starting check-in process');
      _stateController.add(AttendanceButtonState.loading);

      print('AttendanceBloc: Requesting location permission');
      final permission = await Geolocator.requestPermission();
      print('AttendanceBloc: Location permission result: $permission');
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('AttendanceBloc: Location permission denied');
        _errorController.add('Izin lokasi ditolak. Silakan berikan izin lokasi untuk melakukan check-in.');
        _stateController.add(AttendanceButtonState.canCheckIn);
        return;
      }

      print('AttendanceBloc: Getting current position');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      print('AttendanceBloc: Position obtained: ${position.latitude}, ${position.longitude}');
      
      final now = DateTime.now();
      final isLate = now.hour > 8 || (now.hour == 8 && now.minute > 0);
      print('AttendanceBloc: Check-in time: $now, isLate: $isLate');

      print('AttendanceBloc: Calling repository checkIn');
      final id = await _repo.checkIn(
        employeeId: employeeId,
        checkInTime: now,
        location: GeoPoint(position.latitude, position.longitude),
        isLate: isLate,
      );
      print('AttendanceBloc: Check-in successful with ID: $id');
      
      _todayAttendanceId = id;
      _stateController.add(AttendanceButtonState.canCheckOut);
    } catch (e) {
      print('AttendanceBloc: Error during check-in: $e');
      _errorController.add('Gagal melakukan check-in: ${e.toString()}');
      _stateController.add(AttendanceButtonState.canCheckIn);
    }
  }

  Future<void> checkOut() async {
    if (_todayAttendanceId == null) return;
    try {
      _stateController.add(AttendanceButtonState.loading);
      
      // Get current location for checkout
      GeoPoint? checkOutLocation;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition();
          checkOutLocation = GeoPoint(position.latitude, position.longitude);
        }
      } catch (e) {
        // Continue without location if permission denied or error
      }
      
      await _repo.checkOut(
        attendanceId: _todayAttendanceId!, 
        checkOutTime: DateTime.now(),
        location: checkOutLocation,
      );
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