import 'dart:async';
import '../../models/hrm/claim_model.dart';
import '../../services/hrm/claim_repository.dart';

class ClaimBloc {
  final ClaimRepository _repo;

  ClaimBloc({required ClaimRepository repository}) : _repo = repository;

  Stream<List<ClaimModel>> watchEmployeeClaims(String employeeId) {
    return _repo.watchByEmployee(employeeId);
  }

  Stream<List<ClaimModel>> watchPending() {
    return _repo.watchPending();
  }

  Future<void> submit(ClaimModel model) async {
    await _repo.create(model);
  }

  Future<void> setStatus(String claimId, ClaimStatus status) async {
    await _repo.updateStatus(claimId, status);
  }
}