import 'package:flutter/material.dart';
import '../../providers/hrm/attendance_bloc.dart';
import '../../services/hrm/attendance_repository.dart';

class AttendancePage extends StatefulWidget {
  final String employeeId;
  const AttendancePage({super.key, required this.employeeId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late final AttendanceBloc _bloc;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bloc = AttendanceBloc(repository: AttendanceRepository(), employeeId: widget.employeeId);
    _bloc.error.listen((e) => setState(() => _error = e));
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Widget _buildButtons(AttendanceButtonState s) {
    switch (s) {
      case AttendanceButtonState.loading:
        return const CircularProgressIndicator();
      case AttendanceButtonState.canCheckIn:
        return ElevatedButton(
          onPressed: _bloc.checkIn,
          child: const Text('Check-In'),
        );
      case AttendanceButtonState.canCheckOut:
        return ElevatedButton(
          onPressed: _bloc.checkOut,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Check-Out'),
        );
      case AttendanceButtonState.idle:
        return const Text('Anda sudah check-in dan check-out hari ini.');
      case AttendanceButtonState.error:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absensi')),
      body: Center(
        child: StreamBuilder<AttendanceButtonState>(
          stream: _bloc.state,
          initialData: AttendanceButtonState.loading,
          builder: (context, snapshot) {
            final state = snapshot.data ?? AttendanceButtonState.loading;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                _buildButtons(state),
              ],
            );
          },
        ),
      ),
    );
  }
}