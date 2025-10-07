import 'package:flutter/material.dart';
import '../../models/hrm/task_model.dart';
import '../../providers/hrm/task_bloc.dart';
import '../../services/hrm/task_repository.dart';

class MyTasksPage extends StatelessWidget {
  final String employeeId;
  const MyTasksPage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final bloc = TaskBloc(repository: TaskRepository());
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas Saya')),
      body: StreamBuilder<List<TaskModel>>(
        stream: bloc.watchMyTasks(employeeId),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tasks.isEmpty) return const Center(child: Text('Tidak ada tugas.'));
          final todo = tasks.where((t) => t.status == TaskStatus.todo).toList();
          final inprog = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
          final done = tasks.where((t) => t.status == TaskStatus.done).toList();
          Widget section(String title, List<TaskModel> list) => ExpansionTile(
                title: Text(title),
                initiallyExpanded: true,
                children: list
                    .map((t) => ListTile(
                          title: Text(t.title),
                          subtitle: Text(t.description),
                        ))
                    .toList(),
              );
          return ListView(
            children: [
              section('To-Do', todo),
              section('In-Progress', inprog),
              section('Done', done),
            ],
          );
        },
      ),
    );
  }
}