import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waresys_fix1/providers/auth_provider.dart';
import 'package:waresys_fix1/providers/transaction_provider.dart';
import 'package:waresys_fix1/providers/inventory_provider.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_overview_page.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_activity_page.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_notifications_page.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_charts_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'package:waresys_fix1/services/finance_service.dart';
import 'package:waresys_fix1/services/monitoring_service.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  final _financeService = FinanceService();
  final _monitoringService = MonitoringService();
  
  final List<Widget> _pages = [
    const MonitorOverviewPage(),
    const MonitorChartsPage(),
    const MonitorActivityPage(),
    const MonitorNotificationsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

      await Future.wait([
        transactionProvider.loadTransactions(),
        inventoryProvider.loadProducts(),
      ]);

      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Data refreshed successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Error refreshing data: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _titles = [
      'Overview',
      'Charts',
      'Activity',
      'Notifications',
    ];
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.accentPurple,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monitoring',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _titles[_selectedIndex],
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(
                Icons.calendar_today,
                color: AppTheme.textPrimary,
              ),
              onPressed: () async {
                // Date picker functionality will be handled in MonitorOverviewPage
              },
            ),
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    color: AppTheme.textPrimary,
                  ),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
          const SizedBox(width: AppTheme.spacingS),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppTheme.borderDark,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark,
            ],
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderDark,
              width: 1,
            ),
          ),
        ),
        child: StreamBuilder<int>(
          stream: _monitoringService.getUnreadNotificationsCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            
            return BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.accentPurple,
              unselectedItemColor: AppTheme.textTertiary,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: AppTheme.labelSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: AppTheme.labelSmall,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Overview',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Charts',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  activeIcon: Icon(Icons.list_alt),
                  label: 'Activity',
                ),
                BottomNavigationBarItem(
                  icon: unreadCount > 0
                    ? badges.Badge(
                        badgeContent: Text(
                          unreadCount.toString(),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        badgeStyle: badges.BadgeStyle(
                          badgeColor: AppTheme.errorColor,
                          padding: const EdgeInsets.all(4),
                        ),
                        child: const Icon(Icons.notifications_outlined),
                      )
                    : const Icon(Icons.notifications_outlined),
                  activeIcon: unreadCount > 0
                    ? badges.Badge(
                        badgeContent: Text(
                          unreadCount.toString(),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      ),
                         badgeStyle: badges.BadgeStyle(
                           badgeColor: AppTheme.errorColor,
                           padding: const EdgeInsets.all(4),
                         ),
                         child: const Icon(Icons.notifications),
                       )
                     : const Icon(Icons.notifications),
                   label: 'Alerts',
                 ),
               ],
             );
           },
         ),
       ),
     );
  }
}
