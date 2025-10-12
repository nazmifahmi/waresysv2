import 'package:flutter/material.dart';
import '../../models/crm/sales_model.dart';
import '../../services/crm/sales_repository.dart';

class SalesFormPage extends StatefulWidget {
  final SalesModel? existing;

  const SalesFormPage({super.key, this.existing});

  @override
  State<SalesFormPage> createState() => _SalesFormPageState();
}

class _SalesFormPageState extends State<SalesFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameCtrl = TextEditingController();
  final _customerIdCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final SalesRepository _repository = SalesRepository();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final sale = widget.existing!;
      _productNameCtrl.text = sale.productName;
      _customerIdCtrl.text = sale.customerId;
      _quantityCtrl.text = sale.quantity.toString();
      _amountCtrl.text = sale.amount.toString();
      _selectedDate = sale.saleDate;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sale = SalesModel(
        saleId: widget.existing?.saleId ?? '',
        productName: _productNameCtrl.text.trim(),
        customerId: _customerIdCtrl.text.trim(),
        quantity: int.parse(_quantityCtrl.text.trim()),
        amount: double.parse(_amountCtrl.text.trim()),
        saleDate: _selectedDate,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing != null) {
        await _repository.update(sale);
      } else {
        await _repository.create(sale);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null 
                ? 'Data penjualan berhasil diperbarui' 
                : 'Data penjualan berhasil ditambahkan'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Penjualan' : 'Tambah Penjualan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _productNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama produk harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _customerIdCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Customer',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ID Customer harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityCtrl,
              decoration: const InputDecoration(
                labelText: 'Kuantitas',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kuantitas harus diisi';
                }
                final quantity = int.tryParse(value.trim());
                if (quantity == null || quantity <= 0) {
                  return 'Kuantitas harus berupa angka positif';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah harus diisi';
                }
                final amount = double.tryParse(value.trim());
                if (amount == null || amount <= 0) {
                  return 'Jumlah harus berupa angka positif';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Penjualan',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.existing != null ? 'Perbarui' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _customerIdCtrl.dispose();
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }
}