import 'dart:async';
import '../../models/hrm/claim_model.dart';
import '../../services/hrm/claim_repository.dart';

class ClaimBloc {
  final ClaimRepository _repo;
  final StreamController<String?> _errorController = StreamController.broadcast();
  
  Stream<String?> get error => _errorController.stream;

  ClaimBloc({required ClaimRepository repository}) : _repo = repository;

  Stream<List<ClaimModel>> watchEmployeeClaims(String employeeId) {
    return _repo.watchByEmployee(employeeId);
  }

  Stream<List<ClaimModel>> watchPending() {
    return _repo.watchPending();
  }

  Future<void> submit(ClaimModel model) async {
    try {
      await _repo.create(model);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal mengajukan klaim';
      
      if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Tidak memiliki izin untuk mengajukan klaim';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  Future<void> setStatus(String claimId, ClaimStatus status, {String? approvedBy}) async {
    try {
      await _repo.updateStatus(claimId, status, approvedBy: approvedBy);
      _errorController.add(null); // Clear any previous errors
    } catch (e) {
      String errorMessage = 'Gagal mengubah status klaim';
      
      if (e.toString().contains('Claim not found')) {
        errorMessage = 'Klaim tidak ditemukan';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Tidak ada koneksi internet';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Tidak memiliki izin untuk mengubah status klaim';
      }
      
      _errorController.add(errorMessage);
      rethrow;
    }
  }

  void dispose() {
    _errorController.close();
  }
}