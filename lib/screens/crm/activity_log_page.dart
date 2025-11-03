import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/theme.dart';
import '../../providers/crm/customer_provider.dart';
import '../../providers/crm/lead_provider.dart';
import '../../providers/crm/opportunity_provider.dart';
import '../../providers/crm/contact_provider.dart';
import 'customer_detail_page.dart';
import 'lead_detail_page.dart';
import 'opportunity_detail_page.dart';
import 'contact_detail_page.dart';

class ActivityLogPage extends ConsumerStatefulWidget {
  const ActivityLogPage({super.key});

  @override
  ConsumerState<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends ConsumerState<ActivityLogPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Log Aktivitas',
          style: AppTheme.heading3,
        ),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accentBlue,
          tabs: const [
            Tab(text: 'Pelanggan'),
            Tab(text: 'Leads'),
            Tab(text: 'Peluang'),
            Tab(text: 'Kontak'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerActivity(),
          _buildLeadActivity(),
          _buildOpportunityActivity(),
          _buildContactActivity(),
        ],
      ),
    );
  }

  Widget _buildCustomerActivity() {
    return Consumer(
      builder: (context, ref, child) {
        final customerState = ref.watch(customerProvider);
        
        if (customerState.isLoading && customerState.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedCustomers = customerState.customers
            .where((customer) => customer.createdAt != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: sortedCustomers.length,
          itemBuilder: (context, index) {
            final customer = sortedCustomers[index];
            return _buildActivityCard(
              title: customer.name,
              subtitle: customer.email,
              time: _formatDate(customer.createdAt),
              icon: Icons.people,
              color: AppTheme.accentBlue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerDetailPage(customer: customer),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeadActivity() {
    return Consumer(
      builder: (context, ref, child) {
        final leadState = ref.watch(leadProvider);
        
        if (leadState.isLoading && leadState.leads.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedLeads = leadState.leads
            .where((lead) => lead.createdAt != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: sortedLeads.length,
          itemBuilder: (context, index) {
            final lead = sortedLeads[index];
            return _buildActivityCard(
              title: lead.name,
              subtitle: lead.email,
              time: _formatDate(lead.createdAt),
              icon: Icons.trending_up,
              color: AppTheme.accentGreen,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeadDetailPage(lead: lead),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOpportunityActivity() {
    return Consumer(
      builder: (context, ref, child) {
        final opportunityState = ref.watch(opportunityProvider);
        
        if (opportunityState.isLoading && opportunityState.opportunities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedOpportunities = opportunityState.opportunities
            .where((opportunity) => opportunity.createdAt != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: sortedOpportunities.length,
          itemBuilder: (context, index) {
            final opportunity = sortedOpportunities[index];
            return _buildActivityCard(
              title: opportunity.name,
              subtitle: 'Rp ${opportunity.amount.toStringAsFixed(0)}',
              time: _formatDate(opportunity.createdAt),
              icon: Icons.business_center,
              color: AppTheme.accentOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OpportunityDetailPage(opportunity: opportunity),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactActivity() {
    return Consumer(
      builder: (context, ref, child) {
        final contactState = ref.watch(contactProvider);
        
        if (contactState.isLoading && contactState.contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedContacts = contactState.contacts
            .where((contact) => contact.createdAt != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: sortedContacts.length,
          itemBuilder: (context, index) {
            final contact = sortedContacts[index];
            return _buildActivityCard(
              title: contact.fullName,
              subtitle: contact.email,
              time: _formatDate(contact.createdAt),
              icon: Icons.contact_phone,
              color: AppTheme.accentPurple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactDetailPage(contact: contact),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.surfaceDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}