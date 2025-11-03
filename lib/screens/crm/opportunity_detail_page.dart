import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/opportunity_model.dart';
import '../../providers/crm/opportunity_provider.dart';
import '../../constants/theme.dart';
import 'opportunity_form_page.dart';

class OpportunityDetailPage extends ConsumerWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailPage({
    Key? key,
    required this.opportunity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(
          'Detail Opportunity',
          style: AppTheme.heading4.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editOpportunity(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'move_stage':
                  _showStageDialog(context, ref);
                  break;
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (opportunity.isOpen)
                const PopupMenuItem(
                  value: 'move_stage',
                  child: Row(
                    children: [
                      Icon(Icons.timeline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Pindah Stage'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Opportunity'),
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
            _buildValueCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildDetailsCard(),
            SizedBox(height: AppTheme.spacingL),
            _buildRelationshipsCard(),
            SizedBox(height: AppTheme.spacingL),
            if (opportunity.products.isNotEmpty) _buildProductsCard(),
            if (opportunity.products.isNotEmpty) SizedBox(height: AppTheme.spacingL),
            if (opportunity.competitors.isNotEmpty) _buildCompetitorsCard(),
            if (opportunity.competitors.isNotEmpty) SizedBox(height: AppTheme.spacingL),
            if (opportunity.notes != null) _buildNotesCard(),
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
                  backgroundColor: _getPriorityColor(opportunity.priority),
                  child: Text(
                    opportunity.name.isNotEmpty ? opportunity.name[0].toUpperCase() : 'O',
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
                        opportunity.name,
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (opportunity.description != null)
                        Text(
                          opportunity.description!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          _buildStageChip(opportunity.stage),
                          SizedBox(width: AppTheme.spacingS),
                          _buildPriorityChip(opportunity.priority),
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
        padding: EdgeInsets.all(AppTheme.spacingL),
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
                  '${(opportunity.stageProgress * 100).toInt()}%',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            LinearProgressIndicator(
              value: opportunity.stageProgress,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                opportunity.isClosed 
                    ? (opportunity.isWon ? AppTheme.successColor : AppTheme.errorColor)
                    : AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Tipe', _getTypeLabel(opportunity.type)),
                ),
                Expanded(
                  child: _buildInfoItem('Prioritas', _getPriorityLabel(opportunity.priority)),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Currency', opportunity.currency),
                ),
                Expanded(
                  child: _buildInfoItem('Sales Cycle', '${opportunity.salesCycle} hari'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            _buildInfoItem(
              'Dibuat',
              _formatDate(opportunity.createdAt),
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
              'Nilai & Estimasi',
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
                      'Nilai Opportunity',
                      'Rp ${opportunity.amount.toStringAsFixed(0)}',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: AppTheme.spacingS),
                    child: _buildStatItem(
                      'Weighted Value',
                      'Rp ${opportunity.weightedValue.toStringAsFixed(0)}',
                      Icons.trending_up,
                      AppTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Perkiraan Closing',
                    _formatDate(opportunity.expectedCloseDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Hari ke Closing',
                    opportunity.daysToClose > 0 
                        ? '${opportunity.daysToClose} hari'
                        : (opportunity.isOverdue ? 'Overdue' : 'Hari ini'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Opportunity',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Tipe', _getTypeLabel(opportunity.type)),
                ),
                Expanded(
                  child: _buildInfoItem('Prioritas', _getPriorityLabel(opportunity.priority)),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Currency', opportunity.currency),
                ),
                Expanded(
                  child: _buildInfoItem('Sales Cycle', '${opportunity.salesCycle} hari'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            _buildInfoItem(
              'Dibuat',
              _formatDate(opportunity.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relasi',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            if (opportunity.customerId != null)
              _buildInfoRow(Icons.person, 'Customer ID', opportunity.customerId!),
            if (opportunity.contactId != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.contact_phone, 'Contact ID', opportunity.contactId!),
            ],
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.person_outline, 'Assigned To', opportunity.assignedTo),
            if (opportunity.stakeholders.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(
                Icons.group, 
                'Stakeholders', 
                '${opportunity.stakeholders.length} orang',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produk/Layanan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: opportunity.products.map((product) {
                return Chip(
                  label: Text(product),
                  backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kompetitor',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: opportunity.competitors.map((competitor) {
                return Chip(
                  label: Text(competitor),
                  backgroundColor: AppTheme.errorColor.withOpacity(0.1),
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
              opportunity.notes!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageChip(OpportunityStage stage) {
    return Chip(
      label: Text(
        _getStageLabel(stage),
        style: AppTheme.labelSmall.copyWith(color: Colors.white),
      ),
      backgroundColor: _getStageColor(stage),
    );
  }

  Widget _buildPriorityChip(OpportunityPriority priority) {
    return Chip(
      label: Text(
        _getPriorityLabel(priority),
        style: AppTheme.labelSmall.copyWith(color: Colors.white),
      ),
      backgroundColor: _getPriorityColor(priority),
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

  Color _getStageColor(OpportunityStage stage) {
    switch (stage) {
      case OpportunityStage.prospecting:
        return AppTheme.infoColor;
      case OpportunityStage.qualification:
        return AppTheme.accentBlue;
      case OpportunityStage.needs_analysis:
        return AppTheme.accentPurple;
      case OpportunityStage.value_proposition:
        return AppTheme.accentOrange;
      case OpportunityStage.proposal:
        return AppTheme.warningColor;
      case OpportunityStage.negotiation:
        return AppTheme.primaryGreen;
      case OpportunityStage.closed_won:
        return AppTheme.successColor;
      case OpportunityStage.closed_lost:
        return AppTheme.errorColor;
    }
  }

  Color _getPriorityColor(OpportunityPriority priority) {
    switch (priority) {
      case OpportunityPriority.low:
        return AppTheme.textSecondaryLight;
      case OpportunityPriority.medium:
        return AppTheme.infoColor;
      case OpportunityPriority.high:
        return AppTheme.accentOrange;
      case OpportunityPriority.critical:
        return AppTheme.errorColor;
    }
  }

  String _getStageLabel(OpportunityStage stage) {
    switch (stage) {
      case OpportunityStage.prospecting:
        return 'Prospecting';
      case OpportunityStage.qualification:
        return 'Qualification';
      case OpportunityStage.needs_analysis:
        return 'Needs Analysis';
      case OpportunityStage.value_proposition:
        return 'Value Proposition';
      case OpportunityStage.proposal:
        return 'Proposal';
      case OpportunityStage.negotiation:
        return 'Negotiation';
      case OpportunityStage.closed_won:
        return 'Closed Won';
      case OpportunityStage.closed_lost:
        return 'Closed Lost';
    }
  }

  String _getTypeLabel(OpportunityType type) {
    switch (type) {
      case OpportunityType.new_business:
        return 'New Business';
      case OpportunityType.existing_business:
        return 'Existing Business';
      case OpportunityType.renewal:
        return 'Renewal';
      case OpportunityType.upsell:
        return 'Upsell';
      case OpportunityType.cross_sell:
        return 'Cross Sell';
    }
  }

  String _getPriorityLabel(OpportunityPriority priority) {
    switch (priority) {
      case OpportunityPriority.low:
        return 'Rendah';
      case OpportunityPriority.medium:
        return 'Sedang';
      case OpportunityPriority.high:
        return 'Tinggi';
      case OpportunityPriority.critical:
        return 'Kritis';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editOpportunity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpportunityFormPage(
          opportunity: opportunity,
          isEdit: true,
        ),
      ),
    );
  }

  void _showStageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindah Stage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OpportunityStage.values.map((stage) {
            return ListTile(
              title: Text(_getStageLabel(stage)),
              leading: CircleAvatar(
                backgroundColor: _getStageColor(stage),
                radius: 12,
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _moveToStage(context, ref, stage);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Opportunity'),
        content: Text('Apakah Anda yakin ingin menghapus ${opportunity.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteOpportunity(context, ref);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToStage(BuildContext context, WidgetRef ref, OpportunityStage newStage) async {
    try {
      final opportunityNotifier = ref.read(opportunityProvider.notifier);
      
      final updatedOpportunity = opportunity.copyWith(
        stage: newStage,
        probability: _getStageProbability(newStage),
        updatedAt: DateTime.now(),
        actualCloseDate: (newStage == OpportunityStage.closed_won || newStage == OpportunityStage.closed_lost) 
            ? DateTime.now() 
            : null,
      );
      
      await opportunityNotifier.updateOpportunity(opportunity.id, updatedOpportunity);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${opportunity.name} dipindah ke ${_getStageLabel(newStage)}'),
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

  Future<void> _deleteOpportunity(BuildContext context, WidgetRef ref) async {
    try {
      final opportunityNotifier = ref.read(opportunityProvider.notifier);
      await opportunityNotifier.deleteOpportunity(opportunity.id);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${opportunity.name} berhasil dihapus'),
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

  int _getStageProbability(OpportunityStage stage) {
    switch (stage) {
      case OpportunityStage.prospecting:
        return 10;
      case OpportunityStage.qualification:
        return 20;
      case OpportunityStage.needs_analysis:
        return 40;
      case OpportunityStage.value_proposition:
        return 60;
      case OpportunityStage.proposal:
        return 75;
      case OpportunityStage.negotiation:
        return 90;
      case OpportunityStage.closed_won:
        return 100;
      case OpportunityStage.closed_lost:
        return 0;
    }
  }
}