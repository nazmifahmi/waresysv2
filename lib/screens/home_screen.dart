import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'monitoring/monitor_screen.dart';
import 'shared/profile_screen.dart';
import 'finances/finance_screen.dart';
import 'inventory/inventory_screen.dart';
import 'transaction/transaction_screen.dart';
import '../services/auth_service.dart';
import '../widgets/news_section.dart';
import '../providers/news_provider.dart';
import '../constants/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize news when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().initialize();
    });
  }

  void _navigateToMonitoring(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonitorScreen()),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          moduleName: 'Dashboard',
          moduleColor: const Color(0xFF2E8B57),
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _navigateToFinance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FinanceScreen()),
    );
  }

  void _navigateToInventory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InventoryScreen()),
    );
  }

  void _navigateToTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionScreen()),
    );
  }

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<NewsProvider>().refreshNews();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildWelcomeSection(context),
                const SizedBox(height: 32),
                RepaintBoundary(
                  child: _buildCoreFeatures(context),
                ),
                const SizedBox(height: 40),
                RepaintBoundary(
                  child: const NewsSection(
                    title: 'Berita Digitalisasi UMKM',
                  ),
                ),
                const SizedBox(height: 32),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.textSecondary),
            onPressed: () => _logout(context),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: AppTheme.surfaceDecoration,
                child: Text(
                  'WARESYS',
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                onPressed: () => _navigateToProfile(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang',
            style: AppTheme.heading1,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Kelola bisnis UMKM Anda dengan mudah',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitur Utama',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXL),
            decoration: AppTheme.surfaceDecoration,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTheme.buildFeatureCard(
                        icon: Icons.account_balance,
                        title: 'Finance',
                        subtitle: 'Kelola keuangan',
                        color: AppTheme.accentGreen,
                        onTap: () => _navigateToFinance(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: AppTheme.buildFeatureCard(
                        icon: Icons.warehouse,
                        title: 'Inventory',
                        subtitle: 'Stok barang',
                        color: AppTheme.accentOrange,
                        onTap: () => _navigateToInventory(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: AppTheme.buildFeatureCard(
                        icon: Icons.swap_horiz,
                        title: 'Sales',
                        subtitle: 'Transaksi',
                        color: AppTheme.accentBlue,
                        onTap: () => _navigateToTransaction(context),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: AppTheme.buildFeatureCard(
                        icon: Icons.monitor_heart,
                        title: 'Monitor',
                        subtitle: 'Pantau bisnis',
                        color: AppTheme.accentPurple,
                        onTap: () => _navigateToMonitoring(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
                vertical: AppTheme.spacingM,
              ),
              decoration: AppTheme.surfaceDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    'Powered by WARESYS',
                    style: AppTheme.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'v1.0.0',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}