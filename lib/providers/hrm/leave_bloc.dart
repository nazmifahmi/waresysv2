import 'dart:async';
import '../../models/hrm/leave_request_model.dart';
import '../../services/hrm/leave_repository.dart';

class LeaveBloc {
  final LeaveRepository _repo;
  final StreamController<List<LeaveRequestModel>> _listController = StreamController.broadcast();
  final StreamController<String?> _errorController = StreamController.broadcast();
  
  Stream<List<LeaveRequestModel>> get leaves => _listController.stream;
  Stream<String?> get error => _errorController.stream;

  LeaveBloc({required LeaveRepository repository}) : _repo = repository;

  Stream<List<LeaveRequestModel>> watchEmployeeLeaves(String employeeId) {
    return _repo.watchByEmployee(employeeId);
  }

  Stream<List<LeaveRequestModel>> watchPending() {
    return _repo.watchPending();
  }

  Future<void> submit(LeaveRequestModel model) async {
    try {
      await _repo.create(model);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal mengajukan cuti';
      
      if (e.toString().contains('Insufficient leave balance')) {
        errorMessage = 'Saldo cuti tidak mencukupi. ${e.toString().split('. ').last}';
      } else if (e.toString().contains('Employee not found')) {
        errorMessage = 'Data karyawan tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  Future<void> setStatus(String requestId, LeaveStatus status) async {
    try {
      await _repo.updateStatus(requestId, status);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal mengubah status cuti';
      
      if (e.toString().contains('Leave request not found')) {
        errorMessage = 'Pengajuan cuti tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  Future<int> getLeaveBalance(String employeeId) async {
    try {
      return await _repo.getEmployeeLeaveBalance(employeeId);
    } catch (e) {
      String errorMessage = 'Gagal mengambil saldo cuti';
      
      if (e.toString().contains('Employee not found')) {
        errorMessage = 'Data karyawan tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  void dispose() {
    _listController.close();
    _errorController.close();
  }
}