import 'package:flutter/material.dart';
import '../../models/hrm/employee_model.dart';
import '../../providers/hrm/employee_bloc.dart';
import '../../services/hrm/employee_repository.dart';
import 'employee_form_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final EmployeeBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = EmployeeBloc(repository: EmployeeRepository());
  }

  void _openForm({EmployeeModel? employee}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeFormPage(existing: employee)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Karyawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari nama karyawan...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<EmployeeModel>>(
              future: _bloc.getAll(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
              builder: (context, snapshot) {
                final data = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada data karyawan.'));
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final e = data[i];
                    return ListTile(
                      title: Text(e.fullName),
                      subtitle: Text('${e.position} • ${e.department} • ${e.status.name}'),
                      onTap: () => _openForm(employee: e),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          await _bloc.delete(e.employeeId);
                          setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}