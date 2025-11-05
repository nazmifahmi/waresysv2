import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/contact_model.dart';
import '../../providers/crm/contact_provider.dart';
import '../../constants/theme.dart';
import '../../widgets/common_widgets.dart';

class ContactFormPage extends ConsumerStatefulWidget {
  final ContactModel? contact;
  final String? customerId;

  const ContactFormPage({
    Key? key,
    this.contact,
    this.customerId,
  }) : super(key: key);

  @override
  ConsumerState<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends ConsumerState<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _notesController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _tagsController = TextEditingController();

  ContactType _selectedType = ContactType.primary;
  ContactStatus _selectedStatus = ContactStatus.active;
  PreferredContactMethod _selectedContactMethod = PreferredContactMethod.email;
  bool _isDecisionMaker = false;
  bool _canReceiveMarketing = true;
  DateTime? _selectedBirthday;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final contact = widget.contact!;
    _firstNameController.text = contact.firstName;
    _lastNameController.text = contact.lastName;
    _emailController.text = contact.email;
    _phoneController.text = contact.phone;
    _mobileController.text = contact.mobile ?? '';
    _positionController.text = contact.position ?? '';
    _departmentController.text = contact.department ?? '';
    _notesController.text = contact.notes ?? '';
    _linkedinController.text = contact.linkedinProfile ?? '';
    _twitterController.text = contact.twitterHandle ?? '';
    _tagsController.text = contact.tags.join(', ');
    
    _selectedType = contact.type;
    _selectedStatus = contact.status;
    _selectedContactMethod = contact.preferredContactMethod;
    _isDecisionMaker = contact.isDecisionMaker;
    _canReceiveMarketing = contact.canReceiveMarketing;
    _selectedBirthday = contact.birthday;
    _tags = List.from(contact.tags);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    _notesController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _updateTags() {
    final tagsText = _tagsController.text;
    _tags = tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    _updateTags();

    final now = DateTime.now();
    final contactData = ContactModel(
      id: widget.contact?.id ?? '',
      customerId: widget.customerId ?? widget.contact?.customerId ?? '',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
      department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      type: _selectedType,
      status: _selectedStatus,
      preferredContactMethod: _selectedContactMethod,
      isDecisionMaker: _isDecisionMaker,
      canReceiveMarketing: _canReceiveMarketing,
      tags: _tags,
      customFields: widget.contact?.customFields ?? {},
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      lastContactDate: widget.contact?.lastContactDate,
      birthday: _selectedBirthday,
      linkedinProfile: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
      twitterHandle: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
      interactionHistory: widget.contact?.interactionHistory ?? [],
      createdAt: widget.contact?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.contact?.createdBy ?? 'current_user',
      updatedBy: 'current_user',
    );

    try {
      if (widget.contact != null) {
        await ref.read(contactProvider.notifier).updateContact(widget.contact!.id, contactData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact updated successfully')),
          );
        }
      } else {
        await ref.read(contactProvider.notifier).createContact(contactData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact created successfully')),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving contact: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: widget.contact != null ? 'Edit Kontak' : 'Tambah Kontak',
        actions: [
          CommonWidgets.buildAppBarAction(
            text: 'Simpan',
            icon: Icons.save,
            onPressed: _saveContact,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi Dasar
              CommonWidgets.buildSectionCard(
                title: 'Informasi Dasar',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CommonWidgets.buildTextField(
                            label: 'Nama Depan *',
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama depan harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingL),
                        Expanded(
                          child: CommonWidgets.buildTextField(
                            label: 'Nama Belakang *',
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama belakang harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    CommonWidgets.buildTextField(
                      label: 'Email *',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email harus diisi';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    Row(
                      children: [
                        Expanded(
                          child: CommonWidgets.buildTextField(
                            label: 'Nomor Telepon *',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nomor telepon harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingL),
                        Expanded(
                          child: CommonWidgets.buildTextField(
                            label: 'HP',
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.smartphone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingXL),

              // Informasi Profesional
              CommonWidgets.buildSectionCard(
                title: 'Informasi Profesional',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CommonWidgets.buildTextField(
                            label: 'Posisi',
                            controller: _positionController,
                            prefixIcon: Icons.work,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingL),
                        Expanded(
                          child: CommonWidgets.buildTextField(
                            label: 'Departemen',
                            controller: _departmentController,
                            prefixIcon: Icons.business,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    DropdownButtonFormField<ContactType>(
                      value: _selectedType,
                      decoration: AppTheme.inputDecoration('Tipe Kontak').copyWith(
                        prefixIcon: Icon(Icons.category, color: AppTheme.textSecondary),
                      ),
                      style: AppTheme.bodyMedium,
                      dropdownColor: AppTheme.surfaceDark,
                      iconEnabledColor: AppTheme.textSecondary,
                      iconDisabledColor: AppTheme.textTertiary,
                      items: ContactType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            _getContactTypeLabel(type),
                            style: AppTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingXL),

              // Preferensi Kontak
              CommonWidgets.buildSectionCard(
                title: 'Preferensi Kontak',
                child: Column(
                  children: [
                    DropdownButtonFormField<ContactStatus>(
                      value: _selectedStatus,
                      decoration: AppTheme.inputDecoration('Status').copyWith(
                        prefixIcon: Icon(Icons.info, color: AppTheme.textSecondary),
                      ),
                      style: AppTheme.bodyMedium,
                      dropdownColor: AppTheme.surfaceDark,
                      iconEnabledColor: AppTheme.textSecondary,
                      iconDisabledColor: AppTheme.textTertiary,
                      items: ContactStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            _getContactStatusLabel(status),
                            style: AppTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    DropdownButtonFormField<PreferredContactMethod>(
                      value: _selectedContactMethod,
                      decoration: AppTheme.inputDecoration('Metode Kontak Favorit').copyWith(
                        prefixIcon: Icon(Icons.contact_phone, color: AppTheme.textSecondary),
                      ),
                      style: AppTheme.bodyMedium,
                      dropdownColor: AppTheme.surfaceDark,
                      iconEnabledColor: AppTheme.textSecondary,
                      iconDisabledColor: AppTheme.textTertiary,
                      items: PreferredContactMethod.values.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(
                            _getContactMethodLabel(method),
                            style: AppTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedContactMethod = value!;
                        });
                      },
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    SwitchListTile(
                      title: Text(
                        'Pengambil Keputusan',
                        style: AppTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        'Kontak ini dapat membuat keputusan pembelian',
                        style: AppTheme.bodySmall,
                      ),
                      value: _isDecisionMaker,
                      onChanged: (value) {
                        setState(() {
                          _isDecisionMaker = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Boleh Terima Marketing',
                        style: AppTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        'Izinkan komunikasi marketing',
                        style: AppTheme.bodySmall,
                      ),
                      value: _canReceiveMarketing,
                      onChanged: (value) {
                        setState(() {
                          _canReceiveMarketing = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingXL),

              // Informasi Tambahan
              CommonWidgets.buildSectionCard(
                title: 'Informasi Tambahan',
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _selectBirthday,
                      child: InputDecorator(
                        decoration: AppTheme.inputDecoration('Tanggal Lahir').copyWith(
                          prefixIcon: Icon(Icons.cake, color: AppTheme.textSecondary),
                          suffixIcon: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedBirthday != null
                                    ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                                    : 'Belum diatur',
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    CommonWidgets.buildTextField(
                      label: 'Profil LinkedIn',
                      controller: _linkedinController,
                      prefixIcon: Icons.link,
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    CommonWidgets.buildTextField(
                      label: 'Akun Twitter',
                      controller: _twitterController,
                      prefixIcon: Icons.alternate_email,
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    CommonWidgets.buildTextField(
                      label: 'Tag (pisahkan dengan koma)',
                      hint: 'Contoh: VIP, Technical, Influencer',
                      controller: _tagsController,
                      prefixIcon: Icons.tag,
                    ),
                    SizedBox(height: AppTheme.spacingL),
                    CommonWidgets.buildTextField(
                      label: 'Catatan',
                      controller: _notesController,
                      prefixIcon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }


  String _getContactTypeLabel(ContactType type) {
    switch (type) {
      case ContactType.primary:
        return 'Primary';
      case ContactType.secondary:
        return 'Secondary';
      case ContactType.billing:
        return 'Billing';
      case ContactType.technical:
        return 'Technical';
      case ContactType.decision_maker:
        return 'Decision Maker';
      case ContactType.influencer:
        return 'Influencer';
    }
  }

  String _getContactStatusLabel(ContactStatus status) {
    switch (status) {
      case ContactStatus.active:
        return 'Active';
      case ContactStatus.inactive:
        return 'Inactive';
      case ContactStatus.do_not_contact:
        return 'Do Not Contact';
      case ContactStatus.bounced:
        return 'Bounced';
    }
  }

  String _getContactMethodLabel(PreferredContactMethod method) {
    switch (method) {
      case PreferredContactMethod.email:
        return 'Email';
      case PreferredContactMethod.phone:
        return 'Phone';
      case PreferredContactMethod.sms:
        return 'SMS';
      case PreferredContactMethod.whatsapp:
        return 'WhatsApp';
      case PreferredContactMethod.linkedin:
        return 'LinkedIn';
    }
  }
}