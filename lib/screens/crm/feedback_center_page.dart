import 'package:flutter/material.dart';
import '../../models/crm/feedback_model.dart';
import '../../services/crm/feedback_repository.dart';
import 'feedback_form_page.dart';

class FeedbackCenterPage extends StatefulWidget {
  const FeedbackCenterPage({super.key});

  @override
  State<FeedbackCenterPage> createState() => _FeedbackCenterPageState();
}

class _FeedbackCenterPageState extends State<FeedbackCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final FeedbackRepository _repository = FeedbackRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _openForm({FeedbackModel? feedback}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FeedbackFormPage(existing: feedback)),
    );
    setState(() {});
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFeedbackList(String? statusFilter) {
    return FutureBuilder<List<FeedbackModel>>(
      future: statusFilter != null
          ? _repository.getByStatus(statusFilter)
          : _repository.getAll(search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('Belum ada feedback.'));
        }

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, i) {
            final feedback = data[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text(feedback.subject),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: ${feedback.customerId}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRatingStars(feedback.rating),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(feedback.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            feedback.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${feedback.createdAt.day}/${feedback.createdAt.month}/${feedback.createdAt.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Text('Hapus'),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _openForm(feedback: feedback);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: const Text('Hapus feedback ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _repository.delete(feedback.feedbackId);
                        setState(() {});
                      }
                    }
                  },
                ),
                onTap: () => _openForm(feedback: feedback),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pending'),
            Tab(text: 'Reviewed'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari feedback...',
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedbackList(null),
                _buildFeedbackList('pending'),
                _buildFeedbackList('reviewed'),
                _buildFeedbackList('resolved'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}