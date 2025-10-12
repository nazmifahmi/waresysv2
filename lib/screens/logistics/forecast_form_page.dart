import 'package:flutter/material.dart';
import '../../models/logistics/forecast_model.dart';
import '../../services/logistics/forecast_repository.dart';

class ForecastFormPage extends StatefulWidget {
  final ForecastModel? existing;

  const ForecastFormPage({super.key, this.existing});

  @override
  State<ForecastFormPage> createState() => _ForecastFormPageState();
}

class _ForecastFormPageState extends State<ForecastFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ForecastRepository _repository = ForecastRepository();

  late final TextEditingController _categoryController;
  late final TextEditingController _predictedDemandController;
  late final TextEditingController _accuracyRateController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.existing?.category ?? '');
    _predictedDemandController = TextEditingController(
      text: widget.existing?.predictedDemand.toString() ?? '',
    );
    _accuracyRateController = TextEditingController(
      text: widget.existing?.accuracyRate.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _predictedDemandController.dispose();
    _accuracyRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final forecast = ForecastModel(
        forecastId: widget.existing?.forecastId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        category: _categoryController.text.trim(),
        predictedDemand: double.parse(_predictedDemandController.text),
        accuracyRate: double.parse(_accuracyRateController.text),
        updatedAt: DateTime.now(),
      );

      if (widget.existing != null) {
        await _repository.update(forecast);
      } else {
        await _repository.create(forecast);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing != null
                  ? 'Forecast berhasil diperbarui'
                  : 'Forecast berhasil ditambahkan',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Forecast' : 'Tambah Forecast'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Simpan'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori Forecast *',
                hintText: 'Contoh: Sales, Stock, Financial, Demand',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kategori harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _predictedDemandController,
              decoration: const InputDecoration(
                labelText: 'Prediksi Demand *',
                hintText: 'Masukkan nilai prediksi demand',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Prediksi demand harus diisi';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0) {
                  return 'Masukkan nilai yang valid (≥ 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accuracyRateController,
              decoration: const InputDecoration(
                labelText: 'Tingkat Akurasi (%) *',
                hintText: 'Masukkan persentase akurasi (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tingkat akurasi harus diisi';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0 || parsed > 100) {
                  return 'Masukkan nilai antara 0-100';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan Kategori:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('• Sales: Prediksi penjualan produk'),
                    const Text('• Stock: Prediksi kebutuhan stok'),
                    const Text('• Financial: Prediksi keuangan'),
                    const Text('• Demand: Prediksi permintaan pasar'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}