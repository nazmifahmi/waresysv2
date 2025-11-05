import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/logistics/forecast_model.dart';
import '../../services/logistics/forecast_repository.dart';
import 'forecast_form_page.dart';

class ForecastDashboardPage extends StatefulWidget {
  const ForecastDashboardPage({super.key});

  @override
  State<ForecastDashboardPage> createState() => _ForecastDashboardPageState();
}

class _ForecastDashboardPageState extends State<ForecastDashboardPage> {
  final ForecastRepository _repository = ForecastRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  final List<String> _categories = ['All', 'Sales', 'Stock', 'Financial', 'Demand'];

  void _openForm([ForecastModel? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForecastFormPage(existing: existing),
      ),
    );
  }

  Future<void> _deleteForecast(ForecastModel forecast) async {
    final confirmed = await CommonWidgets.showConfirmDialog(
      context: context,
      title: 'Konfirmasi Hapus',
      content: 'Apakah Anda yakin ingin menghapus forecast "${forecast.category}"?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _repository.delete(forecast.forecastId);
        if (mounted) {
          CommonWidgets.showSnackBar(
            context: context,
            message: 'Forecast berhasil dihapus',
            type: SnackBarType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          CommonWidgets.showSnackBar(
            context: context,
            message: 'Error: $e',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return AppTheme.successColor;
    if (accuracy >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sales':
        return Icons.trending_up;
      case 'stock':
        return Icons.inventory;
      case 'financial':
        return Icons.attach_money;
      case 'demand':
        return Icons.analytics;
      default:
        return Icons.bar_chart;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sales':
        return AppTheme.accentBlue;
      case 'stock':
        return AppTheme.accentOrange;
      case 'financial':
        return AppTheme.accentPurple;
      case 'demand':
        return AppTheme.accentGreen;
      default:
        return AppTheme.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: 'Dashboard Peramalan',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              children: [
                CommonWidgets.buildTextField(
                  label: 'Cari forecast',
                  hint: 'Kategori atau kata kunci...',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingL),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: AppTheme.inputDecoration('Filter Kategori'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category == 'All' ? null : category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ForecastModel>>(
              stream: _repository.watchAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CommonWidgets.buildLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return CommonWidgets.buildErrorState(
                    title: 'Terjadi kesalahan',
                    subtitle: '${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                final forecasts = snapshot.data ?? [];
                final filteredForecasts = forecasts.where((forecast) {
                  final matchesSearch = forecast.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || forecast.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredForecasts.isEmpty) {
                  return CommonWidgets.buildEmptyState(
                    title: 'Tidak ada data forecast',
                    subtitle: 'Tambahkan prediksi baru untuk mulai memantau akurasi',
                    icon: Icons.bar_chart,
                    action: CommonWidgets.buildPrimaryButton(
                      text: 'Tambah Forecast',
                      icon: Icons.add,
                      onPressed: () => _openForm(),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  itemCount: filteredForecasts.length,
                  itemBuilder: (context, index) {
                    final forecast = filteredForecasts[index];

                    return CommonWidgets.buildCard(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(forecast.category),
                          child: Icon(
                            _getCategoryIcon(forecast.category),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          forecast.category,
                          style: AppTheme.heading4,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingXS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prediksi Demand: ${forecast.predictedDemand.toStringAsFixed(2)}',
                                  style: AppTheme.bodyMedium),
                              const SizedBox(height: AppTheme.spacingS),
                              Row(
                                children: [
                                  Text('Akurasi: ${forecast.accuracyRate.toStringAsFixed(1)}%',
                                      style: AppTheme.bodySmall),
                                  const SizedBox(width: AppTheme.spacingM),
                                  CommonWidgets.buildChip(
                                    text: forecast.accuracyRate >= 80
                                        ? 'Tinggi'
                                        : forecast.accuracyRate >= 60
                                            ? 'Sedang'
                                            : 'Rendah',
                                    color: _getAccuracyColor(forecast.accuracyRate),
                                    icon: Icons.speed,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingS),
                              Text(
                                'Diperbarui: ${forecast.updatedAt.day}/${forecast.updatedAt.month}/${forecast.updatedAt.year}',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: AppTheme.surfaceDark,
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _openForm(forecast);
                                break;
                              case 'delete':
                                _deleteForecast(forecast);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: AppTheme.errorColor),
                                title: Text('Hapus'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openForm(forecast),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}