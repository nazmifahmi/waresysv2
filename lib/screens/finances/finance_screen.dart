import 'package:flutter/material.dart';
import '../shared/profile_screen.dart';
import 'finance_overview_page.dart';
import 'finance_transactions_page.dart';
import 'finance_budgets_page.dart';
import 'finance_reports_page.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    FinanceOverviewPage(),
    FinanceTransactionsPage(),
    FinanceBudgetsPage(),
    FinanceReportsPage(),
  ];

  static const List<String> _titles = <String>[
    'Overview',
    'Transactions',
    'Budgets',
    'Reports',
  ];

  static final List<Color> _colors = <Color>[
    AppTheme.accentGreen,   // Overview
    AppTheme.accentBlue,    // Transactions
    AppTheme.accentOrange,  // Budgets
    AppTheme.accentPurple,  // Reports
    AppTheme.accentGreen,   // Profile
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      // Show profile screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            moduleName: 'Finances',
            moduleColor: _colors[4],
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
         title: Text(
           _titles[_selectedIndex],
           style: AppTheme.heading3.copyWith(
             color: AppTheme.textPrimary,
           ),
         ),
         backgroundColor: _colors[_selectedIndex],
         centerTitle: true,
         elevation: 0,
         actions: [
           IconButton(
             icon: Icon(
               Icons.notifications_outlined,
               color: AppTheme.textPrimary,
             ),
             onPressed: () {},
           ),
         ],
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
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: _colors[_selectedIndex],
          unselectedItemColor: AppTheme.textTertiary,
          selectedLabelStyle: AppTheme.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: AppTheme.labelSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert_outlined),
              activeIcon: Icon(Icons.swap_vert),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}