import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/lead_model.dart';
import '../../models/crm/customer_model.dart';
import '../../providers/crm/lead_provider.dart';
import '../../providers/crm/customer_provider.dart';
import '../../constants/theme.dart';
import 'lead_form_page.dart';

class LeadDetailPage extends ConsumerWidget {
  final LeadModel lead;

  const LeadDetailPage({
    Key? key,
    required this.lead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(
          'Detail Lead',
          style: AppTheme.heading4.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editLead(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'convert':
                  _showConvertDialog(context, ref);
                  break;
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (lead.isOpen)
                const PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Konversi ke Customer'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Lead'),
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
            _buildProgressCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildContactInfoCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildLeadDetailsCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildValueCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildDatesCard(),
            SizedBox(height: AppTheme.spacingL),
            if (lead.tags.isNotEmpty) _buildTagsCard(),
            if (lead.tags.isNotEmpty) SizedBox(height: AppTheme.spacingL),
            if (lead.notes != null) _buildNotesCard(),
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
                  backgroundColor: _getQualityColor(lead.quality),
                  child: Text(
                    lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
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
                        lead.displayName,
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (lead.position != null)
                        Text(
                          lead.position!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          _buildStatusChip(lead.status),
                          SizedBox(width: AppTheme.spacingS),
                          _buildPriorityChip(lead.priority),
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

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress Pipeline',
                  style: AppTheme.heading4.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  '${(lead.stageProgress * 100).toInt()}%',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            LinearProgressIndicator(
              value: lead.stageProgress,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Kualitas',
                      _getQualityLabel(lead.quality),
                      Icons.star,
                      _getQualityColor(lead.quality),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Weighted Value',
                      'Rp ${lead.weightedValue.toStringAsFixed(0)}',
                      Icons.trending_up,
                      AppTheme.accentPurple,
                    ),
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
            _buildInfoRow(Icons.email, 'Email', lead.email),
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.phone, 'Telepon', lead.phone),
            if (lead.company != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.business, 'Perusahaan', lead.company!),
            ],
            if (lead.industry != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.category, 'Industri', lead.industry!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDetailsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Lead',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Status', _getStatusLabel(lead.status)),
                ),
                Expanded(
                  child: _buildInfoItem('Sumber', _getSourceLabel(lead.source)),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Prioritas', _getPriorityLabel(lead.priority)),
                ),
                Expanded(
                  child: _buildInfoItem('Kontak Attempts', lead.contactAttempts.toString()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nilai & Probabilitas',
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
                      'Estimasi Nilai',
                      'Rp ${lead.estimatedValue.toStringAsFixed(0)}',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Probabilitas',
                      '${lead.probabilityPercent}%',
                      Icons.percent,
                      AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal Penting',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            if (lead.expectedCloseDate != null)
              _buildInfoItem(
                'Perkiraan Closing',
                _formatDate(lead.expectedCloseDate!),
              ),
            if (lead.nextFollowUpDate != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoItem(
                'Follow-up Berikutnya',
                _formatDate(lead.nextFollowUpDate!),
              ),
            ],
            if (lead.lastContactDate != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoItem(
                'Kontak Terakhir',
                _formatDate(lead.lastContactDate!),
              ),
            ],
            SizedBox(height: AppTheme.spacingM),
            _buildInfoItem(
              'Dibuat',
              _formatDate(lead.createdAt),
            ),
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
              children: lead.tags.map((tag) {
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
              lead.notes!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(LeadStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case LeadStatus.new_lead:
        color = AppTheme.infoColor;
        label = 'Baru';
        break;
      case LeadStatus.contacted:
        color = AppTheme.accentBlue;
        label = 'Dihubungi';
        break;
      case LeadStatus.qualified:
        color = AppTheme.accentPurple;
        label = 'Qualified';
        break;
      case LeadStatus.proposal:
        color = AppTheme.accentOrange;
        label = 'Proposal';
        break;
      case LeadStatus.negotiation:
        color = AppTheme.warningColor;
        label = 'Negosiasi';
        break;
      case LeadStatus.closed_won:
        color = AppTheme.successColor;
        label = 'Berhasil';
        break;
      case LeadStatus.closed_lost:
        color = AppTheme.errorColor;
        label = 'Gagal';
        break;
      case LeadStatus.on_hold:
        color = AppTheme.textSecondaryLight;
        label = 'Ditunda';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildPriorityChip(LeadPriority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case LeadPriority.low:
        color = AppTheme.textSecondaryLight;
        label = 'Rendah';
        break;
      case LeadPriority.medium:
        color = AppTheme.infoColor;
        label = 'Sedang';
        break;
      case LeadPriority.high:
        color = AppTheme.accentOrange;
        label = 'Tinggi';
        break;
      case LeadPriority.urgent:
        color = AppTheme.errorColor;
        label = 'Urgent';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
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

  Color _getQualityColor(LeadQuality quality) {
    switch (quality) {
      case LeadQuality.cold:
        return AppTheme.infoColor;
      case LeadQuality.warm:
        return AppTheme.accentOrange;
      case LeadQuality.hot:
        return AppTheme.errorColor;
    }
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.new_lead:
        return 'Lead Baru';
      case LeadStatus.contacted:
        return 'Sudah Dihubungi';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.proposal:
        return 'Proposal';
      case LeadStatus.negotiation:
        return 'Negosiasi';
      case LeadStatus.closed_won:
        return 'Berhasil';
      case LeadStatus.closed_lost:
        return 'Gagal';
      case LeadStatus.on_hold:
        return 'Ditunda';
    }
  }

  String _getSourceLabel(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.referral:
        return 'Referral';
      case LeadSource.social_media:
        return 'Media Sosial';
      case LeadSource.advertisement:
        return 'Iklan';
      case LeadSource.cold_call:
        return 'Cold Call';
      case LeadSource.trade_show:
        return 'Pameran';
      case LeadSource.email_campaign:
        return 'Email Campaign';
      case LeadSource.content_marketing:
        return 'Content Marketing';
      case LeadSource.other:
        return 'Lainnya';
    }
  }

  String _getPriorityLabel(LeadPriority priority) {
    switch (priority) {
      case LeadPriority.low:
        return 'Rendah';
      case LeadPriority.medium:
        return 'Sedang';
      case LeadPriority.high:
        return 'Tinggi';
      case LeadPriority.urgent:
        return 'Urgent';
    }
  }

  String _getQualityLabel(LeadQuality quality) {
    switch (quality) {
      case LeadQuality.cold:
        return 'Cold';
      case LeadQuality.warm:
        return 'Warm';
      case LeadQuality.hot:
        return 'Hot';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editLead(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LeadFormPage(
          lead: lead,
          isEdit: true,
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konversi ke Customer'),
        content: Text('Apakah Anda yakin ingin mengkonversi ${lead.name} menjadi customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _convertToCustomer(context, ref);
            },
            child: const Text('Konversi', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lead'),
        content: Text('Apakah Anda yakin ingin menghapus ${lead.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteLead(context, ref);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _convertToCustomer(BuildContext context, WidgetRef ref) async {
    try {
      final customerNotifier = ref.read(customerProvider.notifier);
      final leadNotifier = ref.read(leadProvider.notifier);
      
      // Create customer from lead data
      final customer = CustomerModel(
        id: '',
        name: lead.name,
        email: lead.email,
        phone: lead.phone,
        company: lead.company,
        position: lead.position,
        address: '',
        city: '',
        status: CustomerStatus.active,
        segment: CustomerSegment.standard,
        source: _convertLeadSourceToCustomerSource(lead.source),
        tags: lead.tags,
        notes: lead.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: lead.createdBy,
      );
      
      // Create customer
      await customerNotifier.createCustomer(customer);
      
      // Update lead status to closed_won
      final updatedLead = lead.copyWith(
        status: LeadStatus.closed_won,
        updatedAt: DateTime.now(),
      );
      await leadNotifier.updateLead(lead.id, updatedLead);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lead.name} berhasil dikonversi menjadi customer'),
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

  Future<void> _deleteLead(BuildContext context, WidgetRef ref) async {
    try {
      final leadNotifier = ref.read(leadProvider.notifier);
      await leadNotifier.deleteLead(lead.id);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lead.name} berhasil dihapus'),
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

  CustomerSource _convertLeadSourceToCustomerSource(LeadSource leadSource) {
    switch (leadSource) {
      case LeadSource.website:
        return CustomerSource.website;
      case LeadSource.referral:
        return CustomerSource.referral;
      case LeadSource.social_media:
        return CustomerSource.social_media;
      case LeadSource.advertisement:
        return CustomerSource.advertisement;
      case LeadSource.cold_call:
        return CustomerSource.cold_call;
      case LeadSource.trade_show:
        return CustomerSource.trade_show;
      default:
        return CustomerSource.other;
    }
  }
}