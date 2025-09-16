import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:waresys_fix1/providers/auth_provider.dart';
import 'package:waresys_fix1/providers/transaction_provider.dart';
import 'package:waresys_fix1/providers/inventory_provider.dart';
import 'package:waresys_fix1/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class MonitorActivityPage extends StatefulWidget {
  const MonitorActivityPage({super.key});

  @override
  State<MonitorActivityPage> createState() => _MonitorActivityPageState();
}

class _MonitorActivityPageState extends State<MonitorActivityPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Transaction', 'Inventory', 'Login/Logout', 'Finance'];

  DateTimeRange? _selectedDateRange;
  String? _selectedUser;
  String _searchText = '';
  List<String> _userList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList() async {
    final snapshot = await FirebaseFirestore.instance.collection('activities').get();
    final users = snapshot.docs
        .map((doc) => doc['userName'] as String? ?? '')
        .where((userName) => userName.isNotEmpty && userName.toLowerCase() != 'system') // Exclude system user
        .toSet()
        .toList();
    setState(() {
      _userList = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Date Range Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_selectedDateRange == null
                      ? 'Filter Tanggal'
                      : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2022, 1, 1),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                ),
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                  tooltip: 'Hapus filter tanggal',
                ),
              ],
              const SizedBox(width: 8),
              // User Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedUser,
                  isExpanded: true,
                  hint: const Text('User'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua User')),
                    ..._userList.map((user) => DropdownMenuItem(
                          value: user,
                          child: Text(user),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUser = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Search Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari aktivitas...'
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
        ),
        // Activity List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getActivityStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter out system activities in memory instead of in query
              var activities = snapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['userName'] as String? ?? '').toLowerCase() != 'system';
              }).toList() ?? [];

              // Filter by search text
              if (_searchText.isNotEmpty) {
                activities = activities.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['title'] as String? ?? '').toLowerCase().contains(_searchText.toLowerCase()) ||
                         (data['description'] as String? ?? '').toLowerCase().contains(_searchText.toLowerCase());
                }).toList();
              }

              if (activities.isEmpty) {
                return const Center(
                  child: Text('No activities found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index].data() as Map<String, dynamic>;
                  final timestamp = (activity['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: _getActivityIcon(activity['type'] as String?),
                      title: Text(activity['title'] as String? ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity['description'] as String? ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          _showActivityDetails(context, activity);
                        },
                      ),
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

  Stream<QuerySnapshot> _getActivityStream() {
    final firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('activities')
        .orderBy('timestamp', descending: true);

    if (_selectedFilter == 'Login/Logout') {
      query = query.where('type', isEqualTo: 'auth');
    } else if (_selectedFilter == 'Inventory') {
      query = query.where('type', isEqualTo: 'inventory')
           .where('action', whereIn: ['stock_in', 'stock_out', 'update', 'add', 'delete']); // Only show actual inventory activities
    } else if (_selectedFilter == 'Finance') {
      query = query.where('type', isEqualTo: 'finance');
    } else if (_selectedFilter != 'All') {
      query = query.where('type', isEqualTo: _selectedFilter.toLowerCase());
    }
    if (_selectedUser != null && _selectedUser!.isNotEmpty) {
      query = query.where('userName', isEqualTo: _selectedUser);
    }
    if (_selectedDateRange != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.start));
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.end.add(const Duration(days: 1))));
    }
    return query.snapshots();
  }

  Widget _getActivityIcon(String? type) {
    IconData iconData;
    Color iconColor;

    switch (type?.toLowerCase()) {
      case 'transaction':
        iconData = Icons.shopping_cart;
        iconColor = Colors.blue;
        break;
      case 'inventory':
        iconData = Icons.inventory_2;
        iconColor = Colors.orange;
        break;
      case 'auth':
        iconData = Icons.person;
        iconColor = Colors.green;
        break;
      case 'finance':
        iconData = Icons.account_balance_wallet;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildDetailsMap(Map details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.entries.map<Widget>((e) {
        String label = e.key;
        dynamic value = e.value;
        if (label.toLowerCase() == 'qty' || label.toLowerCase() == 'before' || label.toLowerCase() == 'after') {
          value = value?.toString();
        } else if (value is Timestamp) {
          value = _formatTimestamp(value);
        } else if (value is DateTime) {
          value = _formatTimestamp(value);
        } else if (label.toLowerCase().contains('harga') || label.toLowerCase().contains('price') || label.toLowerCase().contains('nominal')) {
          value = CurrencyFormatter.format((value as num?)?.toDouble() ?? 0);
        } else if (label == 'file' && value is String) {
          value = value.split('/').last;
        }
        return _detailRow(label, value?.toString());
      }).toList(),
    );
  }

  void _showActivityDetails(BuildContext context, Map<String, dynamic> activity) {
    final timestamp = (activity['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final type = (activity['type'] ?? activity['action'] ?? '').toString();
    final userName = (activity['userName'] as String?)?.isNotEmpty == true
        ? activity['userName']
        : (activity['userId'] ?? 'User');
    final userId = activity['userId'] ?? '-';
    final description = activity['description'] ?? '-';
    final details = activity['details'];

    Widget detailsWidget;
    if (type == 'transaction' && details is Map) {
      detailsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Customer/Supplier', details['customerSupplierName']?.toString()),
          _detailRow('Tanggal', details['createdAt'] != null ? _formatTimestamp(details['createdAt']) : '-'),
          _detailRow('Total', details['total'] != null ? CurrencyFormatter.format((details['total'] as num).toDouble()) : '-'),
          _detailRow('Status Pembayaran', details['paymentStatus']?.toString()),
          _detailRow('Status Pengiriman', details['deliveryStatus']?.toString()),
          if (details['notes'] != null && details['notes'].toString().isNotEmpty)
            _detailRow('Catatan', details['notes'].toString()),
          const SizedBox(height: 8),
          const Text('Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (details['items'] is List)
            ...List.generate((details['items'] as List).length, (i) {
              final item = (details['items'] as List)[i] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('- ${item['productName']} | Qty: ${item['quantity']} x ${item['price']} = ${item['subtotal']}'),
              );
            }),
          const SizedBox(height: 8),
          if (details['logHistory'] is List && (details['logHistory'] as List).isNotEmpty)
            ...[
              const Text('Log History:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...List.generate((details['logHistory'] as List).length, (i) {
                final log = (details['logHistory'] as List)[i] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${_formatTimestamp(log['timestamp'])} - ${log['action'] ?? ''} oleh ${log['userName'] ?? ''}${log['note'] != null ? ' (${log['note']})' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }),
            ],
        ],
      );
    } else if (type == 'stock' && details is Map) {
      detailsWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Produk', details['name'] ?? details['productName']),
          _detailRow('Kategori', details['category']),
          _detailRow('Qty', details['quantity']?.toString() ?? details['qty']?.toString()),
          _detailRow('Sebelum', details['before']?.toString()),
          _detailRow('Sesudah', details['after']?.toString()),
          _detailRow('User', userName),
          if (details['desc'] != null) _detailRow('Keterangan', details['desc']),
        ],
      );
    } else if (details is Map) {
      detailsWidget = _buildDetailsMap(details);
    } else {
      detailsWidget = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(details?.toString() ?? '-'),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getActivityIcon(type),
            const SizedBox(width: 8),
            Expanded(child: Text(activity['title'] as String? ?? 'Detail Aktivitas')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Tipe', type.isNotEmpty ? type : '-'),
              _detailRow('User', userName),
              _detailRow('User ID', userId),
              _detailRow('Waktu', '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}'),
              const SizedBox(height: 8),
              _detailRow('Deskripsi', description),
              if (details != null && details.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Detail Lainnya:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                detailsWidget,
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '-';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute}';
    }
    if (ts is DateTime) {
      return '${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute}';
    }
    return ts.toString();
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }
} 