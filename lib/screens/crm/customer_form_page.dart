import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/customer_model.dart';
import '../../providers/crm/customer_provider.dart';
import '../../constants/theme.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  final bool isEdit;

  const CustomerFormPage({
    Key? key,
    this.customer,
    this.isEdit = false,
  }) : super(key: key);

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();

  CustomerStatus _selectedStatus = CustomerStatus.prospect;
  CustomerSegment _selectedSegment = CustomerSegment.standard;
  CustomerSource _selectedSource = CustomerSource.website;
  List<String> _tags = [];
  final _tagController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.customer != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final customer = widget.customer!;
    _nameController.text = customer.name;
    _emailController.text = customer.email;
    _phoneController.text = customer.phone;
    _companyController.text = customer.company ?? '';
    _positionController.text = customer.position ?? '';
    _addressController.text = customer.address;
    _cityController.text = customer.city;
    _provinceController.text = customer.province ?? '';
    _postalCodeController.text = customer.postalCode ?? '';
    _notesController.text = customer.notes ?? '';
    _selectedStatus = customer.status;
    _selectedSegment = customer.segment;
    _selectedSource = customer.source;
    _tags = List.from(customer.tags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(
          widget.isEdit ? 'Edit Customer' : 'Tambah Customer',
          style: AppTheme.heading4.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveCustomer,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Simpan',
                style: AppTheme.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildContactInfoSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildAddressSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildCategorySection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildTagsSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildNotesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Dasar',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama harus diisi';
                }
                return null;
              },
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Perusahaan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: TextFormField(
                    controller: _positionController,
                    decoration: const InputDecoration(
                      labelText: 'Posisi/Jabatan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Kontak',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email harus diisi';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            SizedBox(height: AppTheme.spacingL),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor telepon harus diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alamat',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Lengkap *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat harus diisi';
                }
                return null;
              },
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Kota *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kota harus diisi';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: TextFormField(
                    controller: _provinceController,
                    decoration: const InputDecoration(
                      labelText: 'Provinsi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Kode Pos',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Customer',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            DropdownButtonFormField<CustomerStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: CustomerStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusLabel(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            SizedBox(height: AppTheme.spacingL),
            DropdownButtonFormField<CustomerSegment>(
              value: _selectedSegment,
              decoration: const InputDecoration(
                labelText: 'Segmen',
                border: OutlineInputBorder(),
              ),
              items: CustomerSegment.values.map((segment) {
                return DropdownMenuItem(
                  value: segment,
                  child: Text(_getSegmentLabel(segment)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSegment = value!;
                });
              },
            ),
            SizedBox(height: AppTheme.spacingL),
            DropdownButtonFormField<CustomerSource>(
              value: _selectedSource,
              decoration: const InputDecoration(
                labelText: 'Sumber',
                border: OutlineInputBorder(),
              ),
              items: CustomerSource.values.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Text(_getSourceLabel(source)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSource = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tags',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Tambah Tag',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTag(_tagController.text),
                  child: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Catatan tambahan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Aktif';
      case CustomerStatus.inactive:
        return 'Tidak Aktif';
      case CustomerStatus.prospect:
        return 'Prospek';
      case CustomerStatus.churned:
        return 'Churn';
    }
  }

  String _getSegmentLabel(CustomerSegment segment) {
    switch (segment) {
      case CustomerSegment.vip:
        return 'VIP';
      case CustomerSegment.premium:
        return 'Premium';
      case CustomerSegment.standard:
        return 'Standard';
      case CustomerSegment.basic:
        return 'Basic';
    }
  }

  String _getSourceLabel(CustomerSource source) {
    switch (source) {
      case CustomerSource.website:
        return 'Website';
      case CustomerSource.referral:
        return 'Referral';
      case CustomerSource.social_media:
        return 'Media Sosial';
      case CustomerSource.advertisement:
        return 'Iklan';
      case CustomerSource.cold_call:
        return 'Cold Call';
      case CustomerSource.trade_show:
        return 'Pameran';
      case CustomerSource.other:
        return 'Lainnya';
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerNotifier = ref.read(customerProvider.notifier);
      
      if (widget.isEdit && widget.customer != null) {
        // Update existing customer
        final updatedCustomer = widget.customer!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
          postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
          status: _selectedStatus,
          segment: _selectedSegment,
          source: _selectedSource,
          tags: _tags,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        await customerNotifier.updateCustomer(widget.customer!.id, updatedCustomer);
      } else {
        // Create new customer
        final newCustomer = CustomerModel(
          id: '', // Will be generated by Firestore
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
          position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
          postalCode: _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
          status: _selectedStatus,
          segment: _selectedSegment,
          source: _selectedSource,
          tags: _tags,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'current_user', // TODO: Get from auth
        );
        
        await customerNotifier.createCustomer(newCustomer);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Customer berhasil diupdate' : 'Customer berhasil ditambahkan'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
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
}