import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/customer_model.dart';
import '../../providers/crm/customer_provider.dart';
import '../../constants/theme.dart';
import 'customer_detail_page.dart';
import 'customer_form_page.dart';

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  CustomerStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final customerNotifier = ref.read(customerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Daftar Pelanggan',
          style: AppTheme.heading3,
        ),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.surfaceDecoration,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: AppTheme.bodyMedium,
                  decoration: AppTheme.inputDecoration('Cari pelanggan...'),
                  onChanged: (value) {
                    // TODO: Implement search functionality
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                // Status Filter
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: AppTheme.labelMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<CustomerStatus?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceDark,
                        style: AppTheme.bodyMedium,
                        hint: Text('Semua Status', style: AppTheme.bodyMedium),
                        items: [
                          DropdownMenuItem<CustomerStatus?>(
                            value: null,
                            child: Text('Semua Status', style: AppTheme.bodyMedium),
                          ),
                          ...CustomerStatus.values.map((status) {
                            return DropdownMenuItem<CustomerStatus>(
                              value: status,
                              child: Text(_getStatusText(status), style: AppTheme.bodyMedium),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          // Properly refresh customers with the selected status
                          customerNotifier.refreshCustomers(status: value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Customer List
          Expanded(
            child: _buildCustomerList(customerState, customerNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(CustomerState customerState, CustomerNotifier customerNotifier) {
    if (customerState.isLoading && customerState.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customerState.error != null && customerState.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customerState.error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => customerNotifier.refreshCustomers(
                status: _selectedStatus,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (customerState.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pelanggan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => customerNotifier.refreshCustomers(
        status: _selectedStatus,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        // Optimize performance by limiting initial rendering
        itemCount: customerState.customers.length + (customerState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == customerState.customers.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final customer = customerState.customers[index];
          return _buildCustomerCard(customer);
        },
        // Add caching for better performance
        cacheExtent: 500.0,
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.surfaceDecoration,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerDetailPage(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accentBlue,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: AppTheme.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: AppTheme.heading4,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (customer.company != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            customer.company!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(customer.status),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                        customer.email,
                        style: AppTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ),
                ],
              ),
              if (customer.phone != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                        customer.phone!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.spacingS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSegmentChip(customer.segment),
                  Text(
                    'Total: Rp ${customer.totalPurchases.toStringAsFixed(0)}',
                    style: AppTheme.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(CustomerStatus status) {
    Color color;
    String label;

    switch (status) {
      case CustomerStatus.active:
        color = AppTheme.successColor;
        label = 'Aktif';
        break;
      case CustomerStatus.inactive:
        color = AppTheme.warningColor;
        label = 'Tidak Aktif';
        break;
      case CustomerStatus.prospect:
        color = AppTheme.infoColor;
        label = 'Prospek';
        break;
      case CustomerStatus.churned:
        color = AppTheme.errorColor;
        label = 'Churn';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS, 
        vertical: AppTheme.spacingXS
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSegmentChip(CustomerSegment segment) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS, 
        vertical: AppTheme.spacingXS
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
      ),
      child: Text(
        _getSegmentLabel(segment),
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.accentGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getStatusText(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Aktif';
      case CustomerStatus.inactive:
        return 'Tidak Aktif';
      case CustomerStatus.prospect:
        return 'Prospek';
      case CustomerStatus.churned:
        return 'Churn';
    }
  }

  String _getSegmentLabel(CustomerSegment segment) {
    switch (segment) {
      case CustomerSegment.vip:
        return 'VIP';
      case CustomerSegment.premium:
        return 'Premium';
      case CustomerSegment.standard:
        return 'Standard';
      case CustomerSegment.basic:
        return 'Basic';
    }
  }

  void _showCustomerDetails(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Detail Customer',
          style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nama', customer.name),
              _buildDetailRow('Email', customer.email),
              if (customer.phone != null)
                _buildDetailRow('Telepon', customer.phone!),
              if (customer.company != null)
                _buildDetailRow('Perusahaan', customer.company!),
              _buildDetailRow('Status', _getStatusText(customer.status)),
              _buildDetailRow('Segmen', _getSegmentLabel(customer.segment)),
              _buildDetailRow('Total Pembelian', 'Rp ${customer.totalPurchases.toStringAsFixed(0)}'),
              _buildDetailRow('Total Order', customer.totalOrders.toString()),
              if (customer.lastPurchaseDate != null)
                _buildDetailRow('Pembelian Terakhir', 
                  '${customer.lastPurchaseDate!.day}/${customer.lastPurchaseDate!.month}/${customer.lastPurchaseDate!.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tutup',
              style: AppTheme.labelMedium.copyWith(color: AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }


}