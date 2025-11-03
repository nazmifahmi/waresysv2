import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/opportunity_model.dart';
import '../../providers/crm/opportunity_provider.dart';
import '../../constants/theme.dart';
import 'opportunity_detail_page.dart';
import 'opportunity_form_page.dart';

class OpportunityListPage extends ConsumerStatefulWidget {
  const OpportunityListPage({super.key});

  @override
  ConsumerState<OpportunityListPage> createState() => _OpportunityListPageState();
}

class _OpportunityListPageState extends ConsumerState<OpportunityListPage> {
  final TextEditingController _searchController = TextEditingController();
  OpportunityStage? _selectedStage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opportunityState = ref.watch(opportunityProvider);
    final opportunityNotifier = ref.read(opportunityProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Daftar Opportunity',
          style: AppTheme.heading3,
        ),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OpportunityFormPage(),
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
                  decoration: AppTheme.inputDecoration('Cari opportunity...').copyWith(
                    prefixIcon: const Icon(Icons.search),
                  ),
                  style: AppTheme.bodyMedium,
                  onChanged: (value) {
                    // TODO: Implement search functionality
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                // Stage Filter
                Row(
                  children: [
                    Text(
                      'Stage: ',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<OpportunityStage?>(
                        value: _selectedStage,
                        isExpanded: true,
                        hint: Text('Semua Stage', style: AppTheme.bodyMedium),
                        dropdownColor: AppTheme.surfaceDark,
                        items: [
                          DropdownMenuItem<OpportunityStage?>(
                            value: null,
                            child: Text('Semua Stage', style: AppTheme.bodyMedium),
                          ),
                          ...OpportunityStage.values.map((stage) {
                            return DropdownMenuItem<OpportunityStage>(
                              value: stage,
                              child: Text(_getStageText(stage), style: AppTheme.bodyMedium),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStage = value;
                          });
                          opportunityNotifier.refreshOpportunities(stage: value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Opportunity List
          Expanded(
            child: _buildOpportunityList(opportunityState, opportunityNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityList(OpportunityState opportunityState, OpportunityNotifier opportunityNotifier) {
    if (opportunityState.isLoading && opportunityState.opportunities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (opportunityState.error != null && opportunityState.opportunities.isEmpty) {
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
              opportunityState.error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton(
              onPressed: () => opportunityNotifier.refreshOpportunities(
                stage: _selectedStage,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (opportunityState.opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Belum ada opportunity',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => opportunityNotifier.refreshOpportunities(
        stage: _selectedStage,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        itemCount: opportunityState.opportunities.length + (opportunityState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == opportunityState.opportunities.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final opportunity = opportunityState.opportunities[index];
          return _buildOpportunityCard(opportunity);
        },
        // Add caching for better performance
        cacheExtent: 500.0,
      ),
    );
  }

  Widget _buildOpportunityCard(OpportunityModel opportunity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.surfaceDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OpportunityDetailPage(opportunity: opportunity),
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
                      opportunity.name.isNotEmpty ? opportunity.name[0].toUpperCase() : 'O',
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
                          opportunity.name,
                          style: AppTheme.heading4,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (opportunity.customerId != null)
                          Text(
                            'Customer ID: ${opportunity.customerId!}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  _buildStageChip(opportunity.stage),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Value and Probability
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nilai',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                          'Rp ${opportunity.amount.toStringAsFixed(0)}',
                          style: AppTheme.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Probabilitas',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${opportunity.probability}%',
                        style: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getProbabilityColor(opportunity.probability),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Close Date
              if (opportunity.expectedCloseDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Target Close: ${_formatDate(opportunity.expectedCloseDate!)}',
                      style: AppTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageChip(OpportunityStage stage) {
    Color color;
    String label;

    switch (stage) {
      case OpportunityStage.prospecting:
        color = AppTheme.infoColor;
        label = 'Prospecting';
        break;
      case OpportunityStage.qualification:
        color = AppTheme.warningColor;
        label = 'Qualification';
        break;
      case OpportunityStage.needs_analysis:
        color = AppTheme.accentPurple;
        label = 'Needs Analysis';
        break;
      case OpportunityStage.value_proposition:
        color = AppTheme.accentOrange;
        label = 'Value Proposition';
        break;
      case OpportunityStage.proposal:
        color = AppTheme.warningColor;
        label = 'Proposal';
        break;
      case OpportunityStage.negotiation:
        color = AppTheme.accentOrange;
        label = 'Negotiation';
        break;
      case OpportunityStage.closed_won:
        color = AppTheme.successColor;
        label = 'Won';
        break;
      case OpportunityStage.closed_lost:
        color = AppTheme.errorColor;
        label = 'Lost';
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

  Color _getProbabilityColor(int probability) {
    if (probability >= 80) return AppTheme.successColor;
    if (probability >= 60) return AppTheme.warningColor;
    if (probability >= 40) return AppTheme.accentOrange;
    return AppTheme.errorColor;
  }

  String _getStageText(OpportunityStage stage) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showOpportunityDetails(OpportunityModel opportunity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Opportunity: ${opportunity.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nama', opportunity.name),
              if (opportunity.customerId != null)
                _buildDetailRow('Customer ID', opportunity.customerId!),
              _buildDetailRow('Stage', _getStageText(opportunity.stage)),
              _buildDetailRow('Nilai', 'Rp ${opportunity.amount.toStringAsFixed(0)}'),
              _buildDetailRow('Probabilitas', '${opportunity.probability}%'),
              if (opportunity.expectedCloseDate != null)
                _buildDetailRow('Target Close', _formatDate(opportunity.expectedCloseDate!)),
              if (opportunity.description != null)
                _buildDetailRow('Deskripsi', opportunity.description!),
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