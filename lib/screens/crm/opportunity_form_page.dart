import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/opportunity_model.dart';
import '../../providers/crm/opportunity_provider.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class OpportunityFormPage extends ConsumerStatefulWidget {
  final OpportunityModel? opportunity;
  final bool isEdit;

  const OpportunityFormPage({
    Key? key,
    this.opportunity,
    this.isEdit = false,
  }) : super(key: key);

  @override
  ConsumerState<OpportunityFormPage> createState() => _OpportunityFormPageState();
}

class _OpportunityFormPageState extends ConsumerState<OpportunityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _probabilityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerIdController = TextEditingController();
  final _contactIdController = TextEditingController();
  final _productsController = TextEditingController();
  final _competitorsController = TextEditingController();
  final _stakeholdersController = TextEditingController();

  OpportunityStage _selectedStage = OpportunityStage.prospecting;
  OpportunityType _selectedType = OpportunityType.new_business;
  OpportunityPriority _selectedPriority = OpportunityPriority.medium;
  DateTime _expectedCloseDate = DateTime.now().add(const Duration(days: 30));
  String _currency = 'IDR';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.opportunity != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final opportunity = widget.opportunity!;
    _nameController.text = opportunity.name;
    _amountController.text = opportunity.amount.toString();
    _probabilityController.text = opportunity.probability.toString();
    _descriptionController.text = opportunity.description ?? '';
    _notesController.text = opportunity.notes ?? '';
    _customerIdController.text = opportunity.customerId ?? '';
    _contactIdController.text = opportunity.contactId ?? '';
    _productsController.text = opportunity.products.join(', ');
    _competitorsController.text = opportunity.competitors.join(', ');
    _stakeholdersController.text = opportunity.stakeholders.join(', ');
    
    _selectedStage = opportunity.stage;
    _selectedType = opportunity.type;
    _selectedPriority = opportunity.priority;
    _expectedCloseDate = opportunity.expectedCloseDate;
    _currency = opportunity.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _probabilityController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _customerIdController.dispose();
    _contactIdController.dispose();
    _productsController.dispose();
    _competitorsController.dispose();
    _stakeholdersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: widget.isEdit ? 'Edit Opportunity' : 'Tambah Opportunity',
        actions: [
          CommonWidgets.buildAppBarAction(
            text: 'Simpan',
            onPressed: _saveOpportunity,
            isLoading: _isLoading,
            icon: Icons.check,
          ),
        ],
      ),
      body: _isLoading
          ? CommonWidgets.buildLoadingIndicator(message: 'Menyimpan opportunity...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    SizedBox(height: AppTheme.spacingXL),
                    _buildAmountSection(),
                    SizedBox(height: AppTheme.spacingXL),
                    _buildStageSection(),
                    SizedBox(height: AppTheme.spacingXL),
                    _buildDetailsSection(),
                    SizedBox(height: AppTheme.spacingXL),
                    _buildRelationshipsSection(),
                    SizedBox(height: AppTheme.spacingXL),
                    _buildNotesSection(),
                    SizedBox(height: AppTheme.spacingXXL),
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
        children: [
          CommonWidgets.buildTextField(
            label: 'Nama Opportunity *',
            hint: 'Masukkan nama opportunity',
            controller: _nameController,
            prefixIcon: Icons.business_center,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama opportunity harus diisi';
              }
              return null;
            },
          ),
          SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Deskripsi',
            hint: 'Deskripsi opportunity',
            controller: _descriptionController,
            prefixIcon: Icons.description,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Nilai & Probabilitas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonWidgets.buildTextField(
                  label: 'Nilai (IDR) *',
                  hint: '0',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nilai harus diisi';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 0) {
                      return 'Nilai harus berupa angka positif';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: AppTheme.spacingL),
              Expanded(
                flex: 2,
                child: CommonWidgets.buildTextField(
                  label: 'Probabilitas (%)',
                  hint: '0-100',
                  controller: _probabilityController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.percent,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final prob = int.tryParse(value);
                      if (prob == null || prob < 0 || prob > 100) {
                        return 'Probabilitas 0-100';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingL),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: AppTheme.inputDecoration('Perkiraan Closing *').copyWith(
                prefixIcon: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
              ),
              child: Text(
                '${_expectedCloseDate.day}/${_expectedCloseDate.month}/${_expectedCloseDate.year}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Stage & Kategori',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<OpportunityStage>(
            value: _selectedStage,
            isExpanded: true,
            decoration: AppTheme.inputDecoration('Stage').copyWith(
              prefixIcon: Icon(Icons.timeline, color: AppTheme.textSecondary),
            ),
            style: AppTheme.bodyMedium,
            dropdownColor: AppTheme.surfaceDark,
            iconEnabledColor: AppTheme.textSecondary,
            iconDisabledColor: AppTheme.textTertiary,
            items: OpportunityStage.values.map((stage) {
              return DropdownMenuItem(
                value: stage,
                child: Text(
                  _getStageLabel(stage),
                  style: AppTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStage = value;
                  _probabilityController.text = _getStageProbability(value).toString();
                });
              }
            },
          ),
          SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<OpportunityType>(
                  value: _selectedType,
                  isExpanded: true,
              decoration: AppTheme.inputDecoration('Tipe').copyWith(
                    prefixIcon: Icon(Icons.category, color: AppTheme.textSecondary),
                  ),
                  style: AppTheme.bodyMedium,
                  dropdownColor: AppTheme.surfaceDark,
                  iconEnabledColor: AppTheme.textSecondary,
                  iconDisabledColor: AppTheme.textTertiary,
                  items: OpportunityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getTypeLabel(type),
                        style: AppTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: DropdownButtonFormField<OpportunityPriority>(
                  value: _selectedPriority,
                  isExpanded: true,
              decoration: AppTheme.inputDecoration('Prioritas').copyWith(
                    prefixIcon: Icon(Icons.priority_high, color: AppTheme.textSecondary),
                  ),
                  style: AppTheme.bodyMedium,
                  dropdownColor: AppTheme.surfaceDark,
                  iconEnabledColor: AppTheme.textSecondary,
                  iconDisabledColor: AppTheme.textTertiary,
                  items: OpportunityPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(
                        _getPriorityLabel(priority),
                        style: AppTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Detail Tambahan',
      child: Column(
        children: [
          CommonWidgets.buildTextField(
            label: 'Produk/Layanan',
            hint: 'Pisahkan dengan koma',
            controller: _productsController,
            prefixIcon: Icons.inventory,
          ),
          SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Kompetitor',
            hint: 'Pisahkan dengan koma',
            controller: _competitorsController,
            prefixIcon: Icons.compare_arrows,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipsSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Relasi',
      child: Column(
        children: [
          CommonWidgets.buildTextField(
            label: 'Customer ID',
            hint: 'ID customer terkait',
            controller: _customerIdController,
            prefixIcon: Icons.person,
          ),
          SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Contact ID',
            hint: 'ID kontak utama',
            controller: _contactIdController,
            prefixIcon: Icons.contact_phone,
          ),
          SizedBox(height: AppTheme.spacingL),
          CommonWidgets.buildTextField(
            label: 'Stakeholders',
            hint: 'ID stakeholders, pisahkan dengan koma',
            controller: _stakeholdersController,
            prefixIcon: Icons.group,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return CommonWidgets.buildSectionCard(
      title: 'Catatan',
      child: CommonWidgets.buildTextField(
        label: 'Catatan',
        hint: 'Catatan tambahan tentang opportunity',
        controller: _notesController,
        prefixIcon: Icons.note,
        maxLines: 4,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedCloseDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _expectedCloseDate) {
      setState(() {
        _expectedCloseDate = picked;
      });
    }
  }

  Future<void> _saveOpportunity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final opportunityNotifier = ref.read(opportunityProvider.notifier);
      
      final opportunity = OpportunityModel(
        id: widget.isEdit ? widget.opportunity!.id : '',
        name: _nameController.text.trim(),
        customerId: _customerIdController.text.trim().isEmpty ? null : _customerIdController.text.trim(),
        contactId: _contactIdController.text.trim().isEmpty ? null : _contactIdController.text.trim(),
        stage: _selectedStage,
        type: _selectedType,
        priority: _selectedPriority,
        amount: double.parse(_amountController.text),
        currency: _currency,
        probability: int.tryParse(_probabilityController.text) ?? _getStageProbability(_selectedStage),
        expectedCloseDate: _expectedCloseDate,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        products: _productsController.text.trim().isEmpty 
            ? [] 
            : _productsController.text.split(',').map((e) => e.trim()).toList(),
        competitors: _competitorsController.text.trim().isEmpty 
            ? [] 
            : _competitorsController.text.split(',').map((e) => e.trim()).toList(),
        stakeholders: _stakeholdersController.text.trim().isEmpty 
            ? [] 
            : _stakeholdersController.text.split(',').map((e) => e.trim()).toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        assignedTo: 'current_user', // TODO: Get from auth
        createdAt: widget.isEdit ? widget.opportunity!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.isEdit ? widget.opportunity!.createdBy : 'current_user',
        updatedBy: widget.isEdit ? 'current_user' : null,
      );

      if (widget.isEdit) {
        await opportunityNotifier.updateOpportunity(opportunity.id, opportunity);
      } else {
        await opportunityNotifier.createOpportunity(opportunity);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit 
                  ? 'Opportunity berhasil diupdate' 
                  : 'Opportunity berhasil ditambahkan',
            ),
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

  String _getStageLabel(OpportunityStage stage) {
    switch (stage) {
      case OpportunityStage.prospecting:
        return 'Prospecting';
      case OpportunityStage.qualification:
        return 'Qualification';
      case OpportunityStage.needs_analysis:
        return 'Needs Analysis';
      case OpportunityStage.value_proposition:
        return 'Value Proposition';
      case OpportunityStage.proposal:
        return 'Proposal';
      case OpportunityStage.negotiation:
        return 'Negotiation';
      case OpportunityStage.closed_won:
        return 'Closed Won';
      case OpportunityStage.closed_lost:
        return 'Closed Lost';
    }
  }

  String _getTypeLabel(OpportunityType type) {
    switch (type) {
      case OpportunityType.new_business:
        return 'New Business';
      case OpportunityType.existing_business:
        return 'Existing Business';
      case OpportunityType.renewal:
        return 'Renewal';
      case OpportunityType.upsell:
        return 'Upsell';
      case OpportunityType.cross_sell:
        return 'Cross Sell';
    }
  }

  String _getPriorityLabel(OpportunityPriority priority) {
    switch (priority) {
      case OpportunityPriority.low:
        return 'Rendah';
      case OpportunityPriority.medium:
        return 'Sedang';
      case OpportunityPriority.high:
        return 'Tinggi';
      case OpportunityPriority.critical:
        return 'Kritis';
    }
  }

  int _getStageProbability(OpportunityStage stage) {
    switch (stage) {
      case OpportunityStage.prospecting:
        return 10;
      case OpportunityStage.qualification:
        return 20;
      case OpportunityStage.needs_analysis:
        return 40;
      case OpportunityStage.value_proposition:
        return 60;
      case OpportunityStage.proposal:
        return 75;
      case OpportunityStage.negotiation:
        return 90;
      case OpportunityStage.closed_won:
        return 100;
      case OpportunityStage.closed_lost:
        return 0;
    }
  }
}