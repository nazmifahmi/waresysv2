import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/lead_model.dart';
import '../../providers/crm/lead_provider.dart';
import '../../constants/theme.dart';
import 'lead_detail_page.dart';
import 'lead_form_page.dart';

class LeadListPage extends ConsumerStatefulWidget {
  const LeadListPage({super.key});

  @override
  ConsumerState<LeadListPage> createState() => _LeadListPageState();
}

class _LeadListPageState extends ConsumerState<LeadListPage> {
  final TextEditingController _searchController = TextEditingController();
  LeadStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadState = ref.watch(leadProvider);
    final leadNotifier = ref.read(leadProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Daftar Lead',
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
                  builder: (context) => const LeadFormPage(),
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
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: AppTheme.surfaceDecoration,
            margin: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: AppTheme.inputDecoration('Cari lead...').copyWith(
                    prefixIcon: const Icon(Icons.search),
                  ),
                  style: AppTheme.bodyMedium,
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
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<LeadStatus?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceDark,
                        style: AppTheme.bodyMedium,
                        hint: Text(
                          'Semua Status',
                          style: AppTheme.bodyMedium,
                        ),
                        items: [
                          DropdownMenuItem<LeadStatus?>(
                            value: null,
                            child: Text(
                              'Semua Status',
                              style: AppTheme.bodyMedium,
                            ),
                          ),
                          ...LeadStatus.values.map((status) {
                            return DropdownMenuItem<LeadStatus>(
                              value: status,
                              child: Text(
                                _getStatusText(status),
                                style: AppTheme.bodyMedium,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          leadNotifier.refreshLeads(status: value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lead List
          Expanded(
            child: _buildLeadList(leadState, leadNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadList(LeadState leadState, LeadNotifier leadNotifier) {
    if (leadState.isLoading && leadState.leads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leadState.error != null && leadState.leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Terjadi kesalahan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              leadState.error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton(
              onPressed: () => leadNotifier.refreshLeads(
                status: _selectedStatus,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (leadState.leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Belum ada lead',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => leadNotifier.refreshLeads(
        status: _selectedStatus,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        itemCount: leadState.leads.length + (leadState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == leadState.leads.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final lead = leadState.leads[index];
          return _buildLeadCard(lead);
        },
        // Add caching for better performance
        cacheExtent: 500.0,
      ),
    );
  }

  Widget _buildLeadCard(LeadModel lead) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.surfaceDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LeadDetailPage(lead: lead),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accentBlue,
                    child: Text(
                      lead.name.isNotEmpty ? lead.name[0].toUpperCase() : 'L',
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
                          lead.name,
                          style: AppTheme.heading4,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (lead.company != null)
                          Text(
                            lead.company!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(lead.status),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Contact Info
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
                      lead.email,
                      style: AppTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (lead.phone != null) ...[
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
                      lead.phone!,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.spacingM),
              // Value and Source
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nilai: Rp ${lead.estimatedValue.toStringAsFixed(0)}',
                    style: AppTheme.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  _buildSourceChip(lead.source),
                ],
              ),
            ],
          ),
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
        color = AppTheme.warningColor;
        label = 'Dihubungi';
        break;
      case LeadStatus.qualified:
        color = AppTheme.successColor;
        label = 'Qualified';
        break;
      case LeadStatus.proposal:
        color = AppTheme.accentPurple;
        label = 'Proposal';
        break;
      case LeadStatus.negotiation:
        color = AppTheme.accentOrange;
        label = 'Negosiasi';
        break;
      case LeadStatus.closed_won:
        color = AppTheme.successColor;
        label = 'Menang';
        break;
      case LeadStatus.closed_lost:
        color = AppTheme.errorColor;
        label = 'Kalah';
        break;
      case LeadStatus.on_hold:
        color = AppTheme.warningColor;
        label = 'Ditahan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
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

  Widget _buildSourceChip(LeadSource source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Text(
        _getSourceLabel(source),
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getStatusText(LeadStatus status) {
    switch (status) {
      case LeadStatus.new_lead:
        return 'Lead Baru';
      case LeadStatus.contacted:
        return 'Dihubungi';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.proposal:
        return 'Proposal';
      case LeadStatus.negotiation:
        return 'Negosiasi';
      case LeadStatus.closed_won:
        return 'Menang';
      case LeadStatus.closed_lost:
        return 'Kalah';
      case LeadStatus.on_hold:
        return 'Ditahan';
    }
  }

  String _getSourceLabel(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.social_media:
        return 'Sosial Media';
      case LeadSource.referral:
        return 'Referral';
      case LeadSource.email_campaign:
        return 'Email Campaign';
      case LeadSource.cold_call:
        return 'Cold Call';
      case LeadSource.trade_show:
        return 'Trade Show';
      case LeadSource.advertisement:
        return 'Iklan';
      case LeadSource.content_marketing:
        return 'Content Marketing';
      case LeadSource.other:
        return 'Lainnya';
    }
  }

  void _showLeadDetails(LeadModel lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Lead: ${lead.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nama', lead.name),
              if (lead.company != null)
                _buildDetailRow('Perusahaan', lead.company!),
              _buildDetailRow('Email', lead.email),
              if (lead.phone != null)
                _buildDetailRow('Telepon', lead.phone!),
              _buildDetailRow('Status', _getStatusText(lead.status)),
              _buildDetailRow('Sumber', _getSourceLabel(lead.source)),
              _buildDetailRow('Nilai Estimasi', 'Rp ${lead.estimatedValue.toStringAsFixed(0)}'),
              if (lead.notes != null)
                _buildDetailRow('Catatan', lead.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}