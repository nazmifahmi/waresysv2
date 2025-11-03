import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/contact_model.dart';
import '../../providers/crm/contact_provider.dart';
import '../../constants/theme.dart';

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
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        title: Text(
          widget.contact != null ? 'Edit Contact' : 'Add Contact',
          style: AppTheme.heading4.copyWith(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            onPressed: _saveContact,
            child: Text(
              'Save',
              style: AppTheme.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
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
              // Basic Information
              _buildSectionHeader('Basic Information'),
              SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.smartphone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingXL),

              // Professional Information
              _buildSectionHeader('Professional Information'),
              SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingL),
              DropdownButtonFormField<ContactType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Contact Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ContactType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getContactTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              SizedBox(height: AppTheme.spacingXL),

              // Contact Preferences
              _buildSectionHeader('Contact Preferences'),
              SizedBox(height: AppTheme.spacingL),
              DropdownButtonFormField<ContactStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                items: ContactStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getContactStatusLabel(status)),
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
                decoration: const InputDecoration(
                  labelText: 'Preferred Contact Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.contact_phone),
                ),
                items: PreferredContactMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(_getContactMethodLabel(method)),
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
                title: const Text('Decision Maker'),
                subtitle: const Text('This contact can make purchasing decisions'),
                value: _isDecisionMaker,
                onChanged: (value) {
                  setState(() {
                    _isDecisionMaker = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Can Receive Marketing'),
                subtitle: const Text('Allow marketing communications'),
                value: _canReceiveMarketing,
                onChanged: (value) {
                  setState(() {
                    _canReceiveMarketing = value;
                  });
                },
              ),
              SizedBox(height: AppTheme.spacingXL),

              // Additional Information
              _buildSectionHeader('Additional Information'),
              SizedBox(height: AppTheme.spacingL),
              ListTile(
                title: const Text('Birthday'),
                subtitle: Text(_selectedBirthday != null 
                    ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                    : 'Not set'),
                leading: const Icon(Icons.cake),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectBirthday,
              ),
              SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _linkedinController,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn Profile',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _twitterController,
                decoration: const InputDecoration(
                  labelText: 'Twitter Handle',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  helperText: 'e.g., VIP, Technical, Influencer',
                ),
              ),
              SizedBox(height: AppTheme.spacingL),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.heading4.copyWith(
        color: AppTheme.primaryGreen,
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