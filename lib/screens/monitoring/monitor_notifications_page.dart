import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:waresys_fix1/providers/auth_provider.dart';
import 'package:waresys_fix1/providers/transaction_provider.dart';
import 'package:waresys_fix1/providers/inventory_provider.dart';
import 'package:waresys_fix1/services/finance_service.dart';
import 'package:intl/intl.dart';

class MonitorNotificationsPage extends StatefulWidget {
  const MonitorNotificationsPage({super.key});

  @override
  State<MonitorNotificationsPage> createState() => _MonitorNotificationsPageState();
}

class _MonitorNotificationsPageState extends State<MonitorNotificationsPage> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Inventory', 'Transaction', 'Finance', 'System'];
  late TabController _tabController;
  final _financeService = FinanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddAlertDialog() {
    String title = '';
    String message = '';
    String type = 'System';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Alert Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Judul'),
              onChanged: (v) => title = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Pesan'),
              onChanged: (v) => message = v,
            ),
            DropdownButtonFormField<String>(
              value: type,
              items: ['System', 'Inventory', 'Transaction', 'Finance']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => type = v ?? 'System',
              decoration: const InputDecoration(labelText: 'Tipe'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (title.trim().isEmpty || message.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('notifications').add({
                'title': title,
                'message': message,
                'type': type,
                'timestamp': Timestamp.now(),
                'isRead': false,
              });
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddAlertDialog,
              child: const Icon(Icons.add),
              tooltip: 'Tambah Alert Manual',
            )
          : null,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Manual'),
              Tab(text: 'Otomatis'),
            ],
            onTap: (_) => setState(() {}),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Manual (Firestore)
                _buildManualNotifications(),
                // Tab 2: Otomatis (generate dari provider)
                _buildAutoNotifications(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualNotifications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!.docs;
        // Tampilkan hanya yang belum dicentang (isRead == false)
        final filteredNotifications = notifications.where((doc) {
          final notif = doc.data() as Map<String, dynamic>;
          if (notif['isRead'] == true) return false;
          if (_selectedFilter != 'All' && _selectedFilter != (notif['type'] ?? 'System')) return false;
          return true;
        }).toList();
        if (filteredNotifications.isEmpty) {
          return const Center(child: Text('Tidak ada notifikasi manual.'));
        }
        return ListView.builder(
          itemCount: filteredNotifications.length,
          itemBuilder: (context, i) {
            final doc = filteredNotifications[i];
            final notif = doc.data() as Map<String, dynamic>;
            final type = notif['type'] as String? ?? 'System';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(_getIconForType(type), color: _getColorForType(type)),
                title: Text(notif['title'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif['message'] ?? ''),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format((notif['timestamp'] as Timestamp).toDate()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Checkbox(
                  value: false,
                  onChanged: (val) async {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(doc.id)
                        .update({'isRead': true});
                  },
                ),
                onLongPress: () => _deleteNotification(doc.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAutoNotifications() {
    return Consumer3<InventoryProvider, TransactionProvider, AuthProvider>(
      builder: (context, inventoryProvider, transactionProvider, authProvider, child) {
        // Selalu clear list di awal
        final List<_AutoNotification> autoNotifications = [];
        
        // Inventory: Stok menipis
        for (var product in inventoryProvider.products) {
          final stock = (product['stock'] ?? 0).toInt();
          final minStock = (product['minStock'] ?? 5).toInt();
          final lastUpdated = product['lastUpdated'];
          final timestamp = lastUpdated is Timestamp ? lastUpdated.toDate() : 
                          lastUpdated is DateTime ? lastUpdated : 
                          DateTime.now();
          
          if (stock <= minStock) {
            autoNotifications.add(_AutoNotification(
              type: 'Inventory',
              title: 'Stok menipis',
              message: 'Stok produk "${product['name']}" hanya $stock (min: $minStock)',
              timestamp: timestamp,
            ));
          }
        }

        // Transaction: Transaksi gagal
        for (var trx in transactionProvider.transactions) {
          if ((trx['status'] ?? '') == 'failed') {
            final trxTimestamp = trx['timestamp'];
            final timestamp = trxTimestamp is Timestamp ? trxTimestamp.toDate() :
                            trxTimestamp is DateTime ? trxTimestamp :
                            DateTime.now();
                            
            autoNotifications.add(_AutoNotification(
              type: 'Transaction',
              title: 'Transaksi gagal',
              message: 'Transaksi ${trx['id'] ?? ''} gagal diproses: ${trx['failureReason'] ?? 'Tidak ada alasan'}',
              timestamp: timestamp,
            ));
          }
        }

        // Finance: Saldo kritis
        return StreamBuilder(
          stream: _financeService.getBalanceStream(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final balance = snapshot.data!;
              if (balance.kasUtama < 100000) {
                if (!autoNotifications.any((n) => n.type == 'Finance' && n.title == 'Saldo Kritis')) {
                  autoNotifications.add(_AutoNotification(
                    type: 'Finance',
                    title: 'Saldo Kritis',
                    message: 'Saldo kas utama di bawah Rp 100.000 (Saat ini: ${balance.kasUtama})',
                    timestamp: DateTime.now(),
                  ));
                }
              }
            }

            if (autoNotifications.isEmpty) {
              return const Center(child: Text('Tidak ada notifikasi otomatis.'));
            }

            return ListView.builder(
                itemCount: autoNotifications.length,
                itemBuilder: (context, i) {
                  final notif = autoNotifications[i];
                  if (_selectedFilter != 'All' && _selectedFilter != notif.type) return const SizedBox();
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Icon(_getIconForType(notif.type), color: _getColorForType(notif.type)),
                      title: Text(notif.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif.message),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(notif.timestamp),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                );
              },
            );
          },
        );
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Inventory':
        return Icons.inventory;
      case 'Transaction':
        return Icons.shopping_cart;
      case 'Finance':
        return Icons.account_balance_wallet;
      case 'System':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Inventory':
        return Colors.orange;
      case 'Transaction':
        return Colors.blue;
      case 'Finance':
        return Colors.green;
      case 'System':
        return Colors.purple;
      default:
        return Colors.grey;
      }
    }
  }

class _AutoNotification {
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;

  _AutoNotification({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
  });
} 