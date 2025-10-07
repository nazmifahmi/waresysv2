import 'dart:async';
import '../../models/hrm/leave_request_model.dart';
import '../../services/hrm/leave_repository.dart';

class LeaveBloc {
  final LeaveRepository _repo;
  final StreamController<List<LeaveRequestModel>> _listController = StreamController.broadcast();
  Stream<List<LeaveRequestModel>> get leaves => _listController.stream;

  LeaveBloc({required LeaveRepository repository}) : _repo = repository;

  Stream<List<LeaveRequestModel>> watchEmployeeLeaves(String employeeId) {
    return _repo.watchByEmployee(employeeId);
  }

  Stream<List<LeaveRequestModel>> watchPending() {
    return _repo.watchPending();
  }

  Future<void> submit(LeaveRequestModel model) async {
    await _repo.create(model);
  }

  Future<void> setStatus(String requestId, LeaveStatus status) async {
    await _repo.updateStatus(requestId, status);
  }

  void dispose() {
    _listController.close();
  }
}