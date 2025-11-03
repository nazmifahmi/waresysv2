import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/customer_model.dart';
import '../../providers/crm/customer_provider.dart';
import '../../constants/theme.dart';
import 'customer_form_page.dart';

class CustomerDetailPage extends ConsumerWidget {
  final CustomerModel customer;

  const CustomerDetailPage({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(
          'Detail Customer',
          style: AppTheme.heading4.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCustomer(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Customer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildContactInfoCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildAddressCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildCategoryCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildStatisticsCard(),
            SizedBox(height: AppTheme.spacingL),
            if (customer.tags.isNotEmpty) _buildTagsCard(),
            if (customer.tags.isNotEmpty) SizedBox(height: AppTheme.spacingL),
            if (customer.notes != null) _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                    style: AppTheme.heading3.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.displayName,
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (customer.position != null)
                        Text(
                          customer.position!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          _buildStatusChip(customer.status),
                          SizedBox(width: AppTheme.spacingS),
                          _buildSegmentChip(customer.segment),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Kontak',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            _buildInfoRow(Icons.email, 'Email', customer.email),
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.phone, 'Telepon', customer.phone),
            if (customer.company != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.business, 'Perusahaan', customer.company!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alamat',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Text(
              customer.fullAddress,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Status', _getStatusLabel(customer.status)),
                ),
                Expanded(
                  child: _buildInfoItem('Segmen', _getSegmentLabel(customer.segment)),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            _buildInfoItem('Sumber', _getSourceLabel(customer.source)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Total Pembelian',
                      'Rp ${customer.totalPurchases.toStringAsFixed(0)}',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Total Order',
                      customer.totalOrders.toString(),
                      Icons.shopping_cart,
                      AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Rata-rata Order',
                      'Rp ${customer.averageOrderValue.toStringAsFixed(0)}',
                      Icons.trending_up,
                      AppTheme.accentPurple,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Status Risiko',
                      customer.isAtRisk ? 'Berisiko' : 'Aman',
                      Icons.warning,
                      customer.isAtRisk ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            if (customer.lastPurchaseDate != null) ...[
              SizedBox(height: AppTheme.spacingL),
              _buildInfoItem(
                'Pembelian Terakhir',
                _formatDate(customer.lastPurchaseDate!),
              ),
            ],
            if (customer.lastContactDate != null) ...[
              SizedBox(height: AppTheme.spacingS),
              _buildInfoItem(
                'Kontak Terakhir',
                _formatDate(customer.lastContactDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: customer.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Text(
              customer.notes!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
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
        color = AppTheme.textSecondaryLight;
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

    return Chip(
      label: Text(
        label,
        style: AppTheme.labelSmall.copyWith(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildSegmentChip(CustomerSegment segment) {
    Color color;
    String label;
    
    switch (segment) {
      case CustomerSegment.vip:
        color = AppTheme.accentOrange;
        label = 'VIP';
        break;
      case CustomerSegment.premium:
        color = AppTheme.accentPurple;
        label = 'Premium';
        break;
      case CustomerSegment.standard:
        color = AppTheme.infoColor;
        label = 'Standard';
        break;
      case CustomerSegment.basic:
        color = AppTheme.textSecondaryLight;
        label = 'Basic';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: AppTheme.labelSmall.copyWith(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryLight),
        SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          SizedBox(height: AppTheme.spacingXS),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(CustomerStatus status) {
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

  String _getSourceLabel(CustomerSource source) {
    switch (source) {
      case CustomerSource.website:
        return 'Website';
      case CustomerSource.referral:
        return 'Referral';
      case CustomerSource.social_media:
        return 'Media Sosial';
      case CustomerSource.advertisement:
        return 'Iklan';
      case CustomerSource.cold_call:
        return 'Cold Call';
      case CustomerSource.trade_show:
        return 'Pameran';
      case CustomerSource.other:
        return 'Lainnya';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editCustomer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerFormPage(
          customer: customer,
          isEdit: true,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Customer'),
        content: Text('Apakah Anda yakin ingin menghapus ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteCustomer(context, ref);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    try {
      final customerNotifier = ref.read(customerProvider.notifier);
      await customerNotifier.deleteCustomer(customer.id);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.name} berhasil dihapus'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}