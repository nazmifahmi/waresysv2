import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Stream<List<TransactionModel>> _getTransactionsStream(TransactionType type) {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('type', isEqualTo: type.name)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => 
          snapshot.docs
              .map((doc) => TransactionModel.fromMap({
                    ...doc.data(),
                    'id': doc.id,
                  }))
              .toList());
  }

  void _showResetDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Reset Data Sistem'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peringatan!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tindakan ini akan menghapus SEMUA data dalam sistem, termasuk:',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• Data transaksi penjualan dan pembelian'),
                  Text('• Data keuangan dan saldo kas'),
                  Text('• Data produk dan kategori'),
                  Text('• Data pelanggan dan supplier'),
                  Text('• Riwayat aktivitas dan notifikasi'),
                  Text('• Data anggaran'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apakah Anda yakin ingin melanjutkan?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirestoreService().cleanupAllData(
                    userId: user.uid,
                    userName: user.displayName ?? user.email ?? 'Admin',
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data sistem berhasil direset'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal reset data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDataDialog(context),
            tooltip: 'Reset Data Sistem',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section with Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 32,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Admin!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage your system efficiently',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Stats Card
              _buildStatsCard(context),
              const SizedBox(height: 20),
              
              // Navigation Buttons
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildNavigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'System Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: FirestoreService().getProducts().then((products) => products.length),
              builder: (context, snapshot) {
                return _buildStatItem(
                  icon: Icons.inventory,
                  label: 'Total Products',
                  value: '${snapshot.data ?? 0}',
                );
              },
            ),
            const Divider(height: 24),
            StreamBuilder<List<TransactionModel>>(
              stream: _getTransactionsStream(TransactionType.sales),
              builder: (context, salesSnapshot) {
                return StreamBuilder<List<TransactionModel>>(
                  stream: _getTransactionsStream(TransactionType.purchase),
                  builder: (context, purchaseSnapshot) {
                    if (salesSnapshot.hasError || purchaseSnapshot.hasError) {
                      return const Text('Error loading transactions');
                    }

                    if (!salesSnapshot.hasData || !purchaseSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final activeSales = salesSnapshot.data?.where((t) => !t.isDeleted).length ?? 0;
                    final activePurchases = purchaseSnapshot.data?.where((t) => !t.isDeleted).length ?? 0;

                    return Column(
                      children: [
                        _buildStatItem(
                          icon: Icons.shopping_cart,
                          label: 'Active Sales',
                          value: '$activeSales',
                        ),
                        const SizedBox(height: 12),
                        _buildStatItem(
                          icon: Icons.store,
                          label: 'Active Purchases',
                          value: '$activePurchases',
                        ),
                        const SizedBox(height: 12),
                        _buildStatItem(
                          icon: Icons.receipt_long,
                          label: 'Total Transactions',
                          value: '${activeSales + activePurchases}',
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildNavButton(
          context: context,
          icon: Icons.inventory_2,
          label: 'Manage Products',
          route: '/monitor/products',
          color: Colors.blue,
        ),
        _buildNavButton(
          context: context,
          icon: Icons.receipt,
          label: 'Manage Transactions',
          route: '/monitor/transactions',
          color: Colors.orange,
        ),
        _buildNavButton(
          context: context,
          icon: Icons.people,
          label: 'Manage Users',
          route: '/user-management',
          color: Colors.purple,
        ),
        _buildNavButton(
          context: context,
          icon: Icons.notifications,
          label: 'Notifications',
          route: '/monitor/notifications',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}