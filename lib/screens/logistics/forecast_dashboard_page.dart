import 'package:flutter/material.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus forecast "${forecast.category}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.delete(forecast.forecastId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Forecast berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Peramalan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Cari forecast...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filter Kategori',
                    border: OutlineInputBorder(),
                  ),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final forecasts = snapshot.data ?? [];
                final filteredForecasts = forecasts.where((forecast) {
                  final matchesSearch = forecast.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || forecast.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredForecasts.isEmpty) {
                  return const Center(child: Text('Tidak ada data forecast'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredForecasts.length,
                  itemBuilder: (context, index) {
                    final forecast = filteredForecasts[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            _getCategoryIcon(forecast.category),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          forecast.category,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prediksi Demand: ${forecast.predictedDemand.toStringAsFixed(2)}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Akurasi: ${forecast.accuracyRate.toStringAsFixed(1)}%'),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getAccuracyColor(forecast.accuracyRate),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    forecast.accuracyRate >= 80 ? 'Tinggi' : 
                                    forecast.accuracyRate >= 60 ? 'Sedang' : 'Rendah',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Diperbarui: ${forecast.updatedAt.day}/${forecast.updatedAt.month}/${forecast.updatedAt.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
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
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Hapus'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
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