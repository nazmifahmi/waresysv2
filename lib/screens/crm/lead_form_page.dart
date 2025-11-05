import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/lead_model.dart';
import '../../providers/crm/lead_provider.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class LeadFormPage extends ConsumerStatefulWidget {
  final LeadModel? lead;
  final bool isEdit;

  const LeadFormPage({
    Key? key,
    this.lead,
    this.isEdit = false,
  }) : super(key: key);

  @override
  ConsumerState<LeadFormPage> createState() => _LeadFormPageState();
}

class _LeadFormPageState extends ConsumerState<LeadFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _industryController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _probabilityController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  LeadStatus _selectedStatus = LeadStatus.new_lead;
  LeadSource _selectedSource = LeadSource.website;
  LeadPriority _selectedPriority = LeadPriority.medium;
  LeadQuality _selectedQuality = LeadQuality.cold;
  DateTime? _expectedCloseDate;
  DateTime? _nextFollowUpDate;
  List<String> _tags = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.lead != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final lead = widget.lead!;
    _nameController.text = lead.name;
    _emailController.text = lead.email;
    _phoneController.text = lead.phone;
    _companyController.text = lead.company ?? '';
    _positionController.text = lead.position ?? '';
    _industryController.text = lead.industry ?? '';
    _estimatedValueController.text = lead.estimatedValue.toString();
    _probabilityController.text = lead.probabilityPercent.toString();
    _notesController.text = lead.notes ?? '';
    _selectedStatus = lead.status;
    _selectedSource = lead.source;
    _selectedPriority = lead.priority;
    _selectedQuality = lead.quality;
    _expectedCloseDate = lead.expectedCloseDate;
    _nextFollowUpDate = lead.nextFollowUpDate;
    _tags = List.from(lead.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _industryController.dispose();
    _estimatedValueController.dispose();
    _probabilityController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: widget.isEdit ? 'Edit Lead' : 'Tambah Lead',
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          CommonWidgets.buildAppBarAction(
            text: 'Simpan',
            icon: Icons.save,
            isLoading: _isLoading,
            onPressed: _saveLead,
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
              _buildLeadDetailsSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildValueSection(),
              SizedBox(height: AppTheme.spacingXL),
              _buildDatesSection(),
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
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Perusahaan',
            controller: _companyController,
            prefixIcon: Icons.business,
          ),
          const SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Posisi/Jabatan',
            controller: _positionController,
            prefixIcon: Icons.badge,
          ),
          const SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Industri',
            controller: _industryController,
            prefixIcon: Icons.category,
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

  Widget _buildLeadDetailsSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Detail Lead',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<LeadStatus>(
            value: _selectedStatus,
            decoration: AppTheme.inputDecoration('Status'),
            items: LeadStatus.values.map((status) {
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
          DropdownButtonFormField<LeadSource>(
            value: _selectedSource,
            decoration: AppTheme.inputDecoration('Sumber'),
            items: LeadSource.values.map((source) {
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
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<LeadPriority>(
                  value: _selectedPriority,
                  decoration: AppTheme.inputDecoration('Prioritas'),
                  items: LeadPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(_getPriorityLabel(priority)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: DropdownButtonFormField<LeadQuality>(
                  value: _selectedQuality,
                  decoration: AppTheme.inputDecoration('Kualitas'),
                  items: LeadQuality.values.map((quality) {
                    return DropdownMenuItem(
                      value: quality,
                      child: Text(_getQualityLabel(quality)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedQuality = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Nilai & Probabilitas',
      child: Row(
        children: [
          Expanded(
            child: CommonWidgets.buildTextField(
              label: 'Estimasi Nilai (Rp)',
              controller: _estimatedValueController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final number = double.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Nilai harus berupa angka positif';
                  }
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: CommonWidgets.buildTextField(
              label: 'Probabilitas (%)',
              controller: _probabilityController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.percent,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final number = int.tryParse(value);
                  if (number == null || number < 0 || number > 100) {
                    return 'Probabilitas harus 0-100';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Tanggal Penting',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _selectDate(context, true),
            child: InputDecorator(
              decoration: AppTheme.inputDecoration('Perkiraan Tanggal Closing'),
              child: Text(
                _expectedCloseDate != null
                    ? _formatDate(_expectedCloseDate!)
                    : 'Pilih tanggal',
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: AppTheme.inputDecoration('Follow-up Berikutnya'),
              child: Text(
                _nextFollowUpDate != null
                    ? _formatDate(_nextFollowUpDate!)
                    : 'Pilih tanggal',
              ),
            ),
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
          CommonWidgets.buildTextField(
            label: 'Tags (pisahkan dengan koma)',
            hint: 'hot lead, enterprise, urgent',
            controller: _tagsController,
            prefixIcon: Icons.sell,
            onChanged: (value) {
              _tags = value
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
            },
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: _tags.map((tag) {
                return CommonWidgets.buildChip(
                  text: tag,
                  color: AppTheme.primaryGreen,
                );
              }).toList(),
            ),
          ],
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
        prefixIcon: Icons.note,
        maxLines: 4,
      ),
    );
  }

  String _getStatusLabel(LeadStatus status) {
    switch (status) {
      case LeadStatus.new_lead:
        return 'Lead Baru';
      case LeadStatus.contacted:
        return 'Sudah Dihubungi';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.proposal:
        return 'Proposal';
      case LeadStatus.negotiation:
        return 'Negosiasi';
      case LeadStatus.closed_won:
        return 'Berhasil';
      case LeadStatus.closed_lost:
        return 'Gagal';
      case LeadStatus.on_hold:
        return 'Ditunda';
    }
  }

  String _getSourceLabel(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.referral:
        return 'Referral';
      case LeadSource.social_media:
        return 'Media Sosial';
      case LeadSource.advertisement:
        return 'Iklan';
      case LeadSource.cold_call:
        return 'Cold Call';
      case LeadSource.trade_show:
        return 'Pameran';
      case LeadSource.email_campaign:
        return 'Email Campaign';
      case LeadSource.content_marketing:
        return 'Content Marketing';
      case LeadSource.other:
        return 'Lainnya';
    }
  }

  String _getPriorityLabel(LeadPriority priority) {
    switch (priority) {
      case LeadPriority.low:
        return 'Rendah';
      case LeadPriority.medium:
        return 'Sedang';
      case LeadPriority.high:
        return 'Tinggi';
      case LeadPriority.urgent:
        return 'Urgent';
    }
  }

  String _getQualityLabel(LeadQuality quality) {
    switch (quality) {
      case LeadQuality.cold:
        return 'Cold';
      case LeadQuality.warm:
        return 'Warm';
      case LeadQuality.hot:
        return 'Hot';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isExpectedClose) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isExpectedClose) {
          _expectedCloseDate = picked;
        } else {
          _nextFollowUpDate = picked;
        }
      });
    }
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final leadNotifier = ref.read(leadProvider.notifier);
      
      final leadData = LeadModel(
        id: widget.isEdit ? widget.lead!.id : '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        industry: _industryController.text.trim().isEmpty ? null : _industryController.text.trim(),
        status: _selectedStatus,
        source: _selectedSource,
        priority: _selectedPriority,
        quality: _selectedQuality,
        estimatedValue: double.tryParse(_estimatedValueController.text) ?? 0.0,
        probabilityPercent: int.tryParse(_probabilityController.text) ?? 10,
        expectedCloseDate: _expectedCloseDate,
        nextFollowUpDate: _nextFollowUpDate,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.isEdit ? widget.lead!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.isEdit ? widget.lead!.createdBy : 'current_user', // TODO: Get from auth
      );

      if (widget.isEdit) {
        await leadNotifier.updateLead(leadData.id, leadData);
      } else {
        await leadNotifier.createLead(leadData);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Lead berhasil diperbarui' : 'Lead berhasil ditambahkan'),
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