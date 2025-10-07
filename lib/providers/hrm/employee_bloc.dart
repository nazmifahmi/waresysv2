import '../../models/hrm/employee_model.dart';
import '../../services/hrm/employee_repository.dart';

class EmployeeBloc {
  final EmployeeRepository _repo;

  EmployeeBloc({required EmployeeRepository repository}) : _repo = repository;

  Stream<List<EmployeeModel>> watchAll() => _repo.watchAll();

  Future<List<EmployeeModel>> getAll({String? search}) => _repo.getAll(search: search);

  Future<EmployeeModel?> getById(String employeeId) => _repo.getById(employeeId);

  Future<String> create(EmployeeModel employee) => _repo.create(employee);

  Future<void> update(EmployeeModel employee) => _repo.update(employee);

  Future<void> delete(String employeeId) => _repo.delete(employeeId);
}