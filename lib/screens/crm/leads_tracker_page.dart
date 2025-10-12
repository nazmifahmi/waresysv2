import 'package:flutter/material.dart';
import '../../models/crm/lead_model.dart';
import '../../services/crm/lead_repository.dart';
import 'lead_form_page.dart';

class LeadsTrackerPage extends StatefulWidget {
  const LeadsTrackerPage({super.key});

  @override
  State<LeadsTrackerPage> createState() => _LeadsTrackerPageState();
}

class _LeadsTrackerPageState extends State<LeadsTrackerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeadRepository _repository = LeadRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm({LeadModel? lead}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeadFormPage(existing: lead)),
    );
    setState(() {});
  }

  Widget _buildLeadsList(String status) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari leads...',
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
          child: StreamBuilder<List<LeadModel>>(
            stream: _repository.watchByStatus(status),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              final filteredData = _searchCtrl.text.trim().isEmpty
                  ? data
                  : data.where((lead) => 
                      lead.source.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
                      lead.contactInfo.toLowerCase().contains(_searchCtrl.text.toLowerCase())
                    ).toList();

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (filteredData.isEmpty) {
                return Center(child: Text('Belum ada leads dengan status $status.'));
              }
              return ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (context, i) {
                  final lead = filteredData[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text(lead.source),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contact: ${lead.contactInfo}'),
                          Text('Score: ${lead.score}/100'),
                          if (lead.assignedTo.isNotEmpty) Text('Assigned: ${lead.assignedTo}'),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: const Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'convert',
                            child: const Text('Convert to Customer'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Text('Hapus'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _openForm(lead: lead);
                          } else if (value == 'convert') {
                            await _repository.updateStatus(lead.leadId, 'Converted');
                            setState(() {});
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi'),
                                content: const Text('Hapus lead ini?'),
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
                              await _repository.delete(lead.leadId);
                              setState(() {});
                            }
                          }
                        },
                      ),
                      onTap: () => _openForm(lead: lead),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Qualified'),
            Tab(text: 'Converted'),
            Tab(text: 'Lost'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsList('New'),
          _buildLeadsList('Qualified'),
          _buildLeadsList('Converted'),
          _buildLeadsList('Lost'),
        ],
      ),
    );
  }
}