import 'package:flutter/material.dart';
import '../../models/hrm/claim_model.dart';
import '../../providers/hrm/claim_bloc.dart';
import '../../services/hrm/claim_repository.dart';

class ClaimReviewPage extends StatelessWidget {
  const ClaimReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = ClaimBloc(repository: ClaimRepository());
    return Scaffold(
      appBar: AppBar(title: const Text('Review Klaim')),
      body: StreamBuilder<List<ClaimModel>>(
        stream: bloc.watchPending(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Tidak ada klaim pending.'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final c = data[i];
              return ListTile(
                title: Text(c.description),
                subtitle: Text('${c.employeeId} • ${c.amount.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => bloc.setStatus(c.claimId, ClaimStatus.rejected)),
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => bloc.setStatus(c.claimId, ClaimStatus.approved)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}