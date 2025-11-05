import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/crm/customer_provider.dart';
import '../../providers/crm/lead_provider.dart';
import '../../providers/crm/opportunity_provider.dart';
import '../../providers/crm/contact_provider.dart';
import 'customer_list_page.dart';
import 'lead_list_page.dart';
import 'opportunity_list_page.dart';
import 'contact_list_page.dart';
import 'activity_log_page.dart';

class CRMHomePage extends ConsumerStatefulWidget {
  const CRMHomePage({super.key});

  @override
  ConsumerState<CRMHomePage> createState() => _CRMHomePageState();
}

class _CRMHomePageState extends ConsumerState<CRMHomePage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize CRM data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _initializeCRMData();
        _isInitialized = true;
      }
    });
  }

  // Proper initialization to prevent data duplication
  Future<void> _initializeCRMData() async {
    try {
      // Initialize all providers without refresh to prevent data clearing
      final customerNotifier = ref.read(customerProvider.notifier);
      final leadNotifier = ref.read(leadProvider.notifier);
      final opportunityNotifier = ref.read(opportunityProvider.notifier);
      final contactNotifier = ref.read(contactProvider.notifier);

      // Only load if not already loaded to prevent duplication
      if (ref.read(customerProvider).customers.isEmpty) {
        customerNotifier.loadCustomers();
      }
      if (ref.read(leadProvider).leads.isEmpty) {
        leadNotifier.loadLeads();
      }
      if (ref.read(opportunityProvider).opportunities.isEmpty) {
        opportunityNotifier.loadOpportunities();
      }
      if (ref.read(contactProvider).contacts.isEmpty) {
        contactNotifier.loadContacts();
      }
    } catch (e) {
      print('Error initializing CRM data: $e');
    }
  }

  // Staggered initialization to prevent all providers from loading simultaneously
  Future<void> _initializeCRMDataStaggered() async {
    // Load customers first
    ref.read(customerProvider.notifier).refreshCustomers();
    
    // Wait a bit before loading leads
    await Future.delayed(const Duration(milliseconds: 100));
    ref.read(leadProvider.notifier).refreshLeads();
    
    // Wait a bit before loading opportunities
    await Future.delayed(const Duration(milliseconds: 100));
    ref.read(opportunityProvider.notifier).refreshOpportunities();
    
    // Wait a bit before loading contacts
    await Future.delayed(const Duration(milliseconds: 100));
    ref.read(contactProvider.notifier).refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('CRM Dashboard'),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAllData(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildStatisticsCards(),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 32),
              _buildRecentActivity(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRM Dashboard',
            style: AppTheme.heading1,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Kelola pelanggan, leads, dan peluang bisnis',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Customers',
                  provider: customerStatisticsProvider,
                  icon: Icons.people,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  title: 'Leads',
                  provider: leadStatisticsProvider,
                  icon: Icons.trending_up,
                  color: AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Opportunities',
                  provider: opportunityStatisticsProvider,
                  icon: Icons.business_center,
                  color: AppTheme.accentOrange,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildStatCard(
                  title: 'Contacts',
                  provider: contactStatisticsProvider,
                  icon: Icons.contact_phone,
                  color: AppTheme.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required FutureProvider<Map<String, dynamic>> provider,
    required IconData icon,
    required Color color,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(provider);
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              statsAsync.when(
                data: (stats) {
                  // Get the total count directly from the 'total' key
                  final total = stats['total'] ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total.toString(),
                        style: AppTheme.heading2.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Total $title',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text(
                  'Error',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: AppTheme.surfaceDecoration,
            child: Consumer(
              builder: (context, ref, _) {
                final customersStats = ref.watch(customerStatisticsProvider);
                final leadsStats = ref.watch(leadStatisticsProvider);
                final opportunitiesStats = ref.watch(opportunityStatisticsProvider);
                final contactsStats = ref.watch(contactStatisticsProvider);

                // Helper to extract total safely
                int _getTotal(AsyncValue<Map<String, dynamic>> stats) {
                  return stats.when(
                    data: (map) => (map['total'] as int?) ?? 0,
                    loading: () => 0,
                    error: (_, __) => 0,
                  );
                }

                final int customersTotal = _getTotal(customersStats);
                final int leadsTotal = _getTotal(leadsStats);
                final int opportunitiesTotal = opportunitiesStats.when(
                  data: (map) => (map['total'] as int?) ?? 0,
                  loading: () => 0,
                  error: (_, __) => 0,
                );
                final int contactsTotal = contactsStats.when(
                  data: (map) => (map['total'] as int?) ?? 0,
                  loading: () => 0,
                  error: (_, __) => 0,
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTheme.buildFeatureCard(
                            icon: Icons.people,
                            title: 'Customers',
                            subtitle: 'Kelola data pelanggan • Total: $customersTotal',
                            color: AppTheme.accentBlue,
                            onTap: () => _navigateToCustomers(),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: AppTheme.buildFeatureCard(
                            icon: Icons.trending_up,
                            title: 'Leads',
                            subtitle: 'Kelola prospek • Total: $leadsTotal',
                            color: AppTheme.accentGreen,
                            onTap: () => _navigateToLeads(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: AppTheme.buildFeatureCard(
                            icon: Icons.business_center,
                            title: 'Opportunities',
                            subtitle: 'Peluang bisnis • Total: $opportunitiesTotal',
                            color: AppTheme.accentOrange,
                            onTap: () => _navigateToOpportunities(),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: AppTheme.buildFeatureCard(
                            icon: Icons.contact_phone,
                            title: 'Contacts',
                            subtitle: 'Kontak bisnis • Total: $contactsTotal',
                            color: AppTheme.accentPurple,
                            onTap: () => _navigateToContacts(),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terbaru',
                style: AppTheme.heading3,
              ),
              TextButton(
                onPressed: () => _showAllActivity(),
                child: Text(
                  'Lihat Semua',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                _buildRecentCustomers(),
                const SizedBox(height: AppTheme.spacingL),
                _buildRecentLeads(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCustomers() {
    return Consumer(
      builder: (context, ref, child) {
        final customersAsync = ref.watch(customerProvider);
        
        // Sort by creation date and take the most recent ones
        final recentCustomers = customersAsync.customers
            .where((customer) => customer.createdAt != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return _buildActivitySection(
          'Pelanggan Terbaru',
          Icons.people,
          AppTheme.accentBlue,
          recentCustomers.take(3).map((customer) => {
            'title': customer.name,
            'subtitle': customer.email,
            'time': _formatDate(customer.createdAt),
          }).toList(),
          () => _navigateToCustomers(),
        );
      },
    );
  }

  Widget _buildRecentLeads() {
    return Consumer(
      builder: (context, ref, child) {
        final leadsAsync = ref.watch(leadProvider);
        
        // Sort by creation date and take the most recent ones
        final recentLeads = leadsAsync.leads
            .where((lead) => lead.createdAt != null)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return _buildActivitySection(
          'Leads Terbaru',
          Icons.trending_up,
          AppTheme.accentGreen,
          recentLeads.take(3).map((lead) => {
            'title': lead.name,
            'subtitle': lead.email,
            'time': _formatDate(lead.createdAt),
          }).toList(),
          () => _navigateToLeads(),
        );
      },
    );
  }

  Widget _buildActivitySection(
    String title,
    IconData icon,
    Color color,
    List<Map<String, String>> items,
    VoidCallback onViewAll,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              title,
              style: AppTheme.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'Lihat',
                style: AppTheme.labelSmall.copyWith(
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        // Optimize by limiting items to prevent excessive rendering
        ...items.take(3).map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['subtitle'] ?? '',
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
                item['time'] ?? '',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          'Error loading data',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToCustomers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerListPage()),
    );
  }

  void _navigateToLeads() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeadListPage()),
    );
  }

  void _navigateToOpportunities() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OpportunityListPage()),
    );
  }

  void _navigateToContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactListPage()),
    );
  }

  // Utility methods
  Future<void> _refreshAllData() async {
    try {
      // Refresh all providers to get latest data
      await Future.wait([
        ref.read(customerProvider.notifier).refreshCustomers(),
        ref.read(leadProvider.notifier).refreshLeads(),
        ref.read(opportunityProvider.notifier).refreshOpportunities(),
        ref.read(contactProvider.notifier).refreshContacts(),
      ]);
      
      // Invalidate statistics providers to refresh dashboard data
      ref.invalidate(customerStatisticsProvider);
      ref.invalidate(leadStatisticsProvider);
      ref.invalidate(opportunityStatisticsProvider);
      ref.invalidate(contactStatisticsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search CRM'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Search customers, leads, opportunities...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement search functionality
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAllActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActivityLogPage(),
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