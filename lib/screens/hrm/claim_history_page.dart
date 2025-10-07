import 'package:flutter/material.dart';
import '../../models/hrm/claim_model.dart';
import '../../providers/hrm/claim_bloc.dart';
import '../../services/hrm/claim_repository.dart';

class ClaimHistoryPage extends StatelessWidget {
  final String employeeId;
  const ClaimHistoryPage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final bloc = ClaimBloc(repository: ClaimRepository());
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Klaim')),
      body: StreamBuilder<List<ClaimModel>>(
        stream: bloc.watchEmployeeClaims(employeeId),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Belum ada pengajuan klaim.'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final c = data[i];
              return ListTile(
                title: Text(c.description),
                subtitle: Text('${c.amount.toStringAsFixed(2)} • ${c.status.name}'),
                trailing: c.receiptImageUrl != null ? const Icon(Icons.receipt_long) : null,
              );
            },
          );
        },
      ),
    );
  }
}