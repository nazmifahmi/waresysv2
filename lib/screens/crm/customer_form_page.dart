import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/customer_model.dart';
import '../../providers/crm/customer_provider.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

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
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: widget.isEdit ? 'Edit Customer' : 'Tambah Customer',
        actions: [
          CommonWidgets.buildAppBarAction(
            text: 'Simpan',
            onPressed: _saveCustomer,
            isLoading: _isLoading,
            icon: Icons.save,
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
    return CommonWidgets.buildSectionCard(
      title: 'Informasi Dasar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonWidgets.buildTextField(
            label: 'Nama Lengkap *',
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama harus diisi';
              }
              return null;
            },
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: CommonWidgets.buildTextField(
                  label: 'Perusahaan',
                  controller: _companyController,
                  prefixIcon: Icons.business,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: CommonWidgets.buildTextField(
                  label: 'Posisi/Jabatan',
                  controller: _positionController,
                  prefixIcon: Icons.badge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Informasi Kontak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonWidgets.buildTextField(
            label: 'Email *',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
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
          const SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Nomor Telepon *',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor telepon harus diisi';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Alamat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonWidgets.buildTextField(
            label: 'Alamat Lengkap *',
            controller: _addressController,
            maxLines: 2,
            prefixIcon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: CommonWidgets.buildTextField(
                  label: 'Kota *',
                  controller: _cityController,
                  prefixIcon: Icons.location_city,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kota harus diisi';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: CommonWidgets.buildTextField(
                  label: 'Provinsi',
                  controller: _provinceController,
                  prefixIcon: Icons.map,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Kode Pos',
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.local_post_office,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return CommonWidgets.buildSectionCard(
      title: 'Kategori Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<CustomerStatus>(
            value: _selectedStatus,
            decoration: AppTheme.inputDecoration('Status'),
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
          const SizedBox(height: AppTheme.spacingL),
          DropdownButtonFormField<CustomerSegment>(
            value: _selectedSegment,
            decoration: AppTheme.inputDecoration('Segmen'),
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
          const SizedBox(height: AppTheme.spacingL),
          DropdownButtonFormField<CustomerSource>(
            value: _selectedSource,
            decoration: AppTheme.inputDecoration('Sumber'),
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
    );
  }

  Widget _buildTagsSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Tags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  decoration: AppTheme.inputDecoration('Tambah Tag'),
                  onFieldSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              CommonWidgets.buildPrimaryButton(
                text: 'Tambah',
                onPressed: () => _addTag(_tagController.text),
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
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
    );
  }

  Widget _buildNotesSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Catatan',
      child: CommonWidgets.buildTextField(
        label: 'Catatan tambahan',
        controller: _notesController,
        maxLines: 4,
        prefixIcon: Icons.notes,
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