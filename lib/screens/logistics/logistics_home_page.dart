import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import 'shipping_dashboard_page.dart';
import 'fleet_map_page.dart';
import 'warehouse_management_page.dart';
import 'forecast_dashboard_page.dart';

class LogisticsHomePage extends StatelessWidget {
  const LogisticsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Logistics Management'),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen Logistik',
                style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Kelola pengiriman, armada, gudang, dan prediksi logistik',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Logistics Modules Grid
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: AppTheme.surfaceDecoration,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildLogisticsCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'Pengiriman',
                            subtitle: 'Dashboard pengiriman',
                            color: AppTheme.accentBlue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShippingDashboardPage(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildLogisticsCard(
                            context,
                            icon: Icons.directions_car,
                            title: 'Armada',
                            subtitle: 'Peta & rute armada',
                            color: AppTheme.accentGreen,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FleetMapPage(routeId: 'default_route'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLogisticsCard(
                            context,
                            icon: Icons.warehouse,
                            title: 'Gudang',
                            subtitle: 'Manajemen gudang',
                            color: AppTheme.accentOrange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WarehouseManagementPage(warehouseId: 'main_warehouse'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildLogisticsCard(
                            context,
                            icon: Icons.analytics,
                            title: 'Prediksi',
                            subtitle: 'Forecast logistik',
                            color: AppTheme.accentPurple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForecastDashboardPage(productId: 'default'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Quick Stats Section
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: AppTheme.surfaceDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistik Cepat',
                      style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pengiriman Aktif',
                            '12',
                            Icons.local_shipping,
                            AppTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildStatCard(
                            'Armada Tersedia',
                            '8',
                            Icons.directions_car,
                            AppTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Lokasi Gudang',
                            '5',
                            Icons.warehouse,
                            AppTheme.accentOrange,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildStatCard(
                            'Prediksi Akurat',
                            '94%',
                            Icons.analytics,
                            AppTheme.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogisticsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}