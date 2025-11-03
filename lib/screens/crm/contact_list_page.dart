import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/contact_model.dart';
import '../../providers/crm/contact_provider.dart';
import '../../constants/theme.dart';
import 'contact_detail_page.dart';
import 'contact_form_page.dart';

class ContactListPage extends ConsumerStatefulWidget {
  const ContactListPage({super.key});

  @override
  ConsumerState<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends ConsumerState<ContactListPage> {
  final TextEditingController _searchController = TextEditingController();
  ContactType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactProvider);
    final contactNotifier = ref.read(contactProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Daftar Kontak',
          style: AppTheme.heading3,
        ),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textPrimary,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ContactFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: AppTheme.surfaceDecoration,
            margin: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kontak...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(color: AppTheme.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(color: AppTheme.accentBlue),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                  ),
                  style: AppTheme.bodyMedium,
                  onChanged: (value) {
                    // TODO: Implement search functionality
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                // Type Filter
                Row(
                  children: [
                    Text(
                      'Tipe: ',
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<ContactType?>(
                        value: _selectedType,
                        isExpanded: true,
                        hint: Text('Semua Tipe', style: AppTheme.bodyMedium),
                        style: AppTheme.bodyMedium,
                        dropdownColor: AppTheme.surfaceDark,
                        items: [
                          DropdownMenuItem<ContactType?>(
                            value: null,
                            child: Text('Semua Tipe', style: AppTheme.bodyMedium),
                          ),
                          ...ContactType.values.map((type) {
                            return DropdownMenuItem<ContactType>(
                              value: type,
                              child: Text(_getTypeText(type), style: AppTheme.bodyMedium),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                          contactNotifier.refreshContacts(type: value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contact List
          Expanded(
            child: _buildContactList(contactState, contactNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(ContactState contactState, ContactNotifier contactNotifier) {
    if (contactState.isLoading && contactState.contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (contactState.error != null && contactState.contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Terjadi kesalahan',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              contactState.error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton(
              onPressed: () => contactNotifier.refreshContacts(
                type: _selectedType,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (contactState.contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Belum ada kontak',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => contactNotifier.refreshContacts(
        type: _selectedType,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        itemCount: contactState.contacts.length + (contactState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == contactState.contacts.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final contact = contactState.contacts[index];
          return _buildContactCard(contact);
        },
        // Add caching for better performance
        cacheExtent: 500.0,
      ),
    );
  }

  Widget _buildContactCard(ContactModel contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.surfaceDecoration.copyWith(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ContactDetailPage(contact: contact),
                    ),
                  );
                },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accentBlue,
                    child: Text(
                      contact.firstName.isNotEmpty ? contact.firstName[0].toUpperCase() : 'C',
                      style: AppTheme.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${contact.firstName} ${contact.lastName}',
                          style: AppTheme.heading4,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (contact.position != null)
                          Text(
                            contact.position!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  _buildTypeChip(contact.type),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Contact Info
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      contact.email,
                      style: AppTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              if (contact.phone != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      contact.phone!,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (contact.customerId.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Customer ID: ${contact.customerId}',
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ContactType type) {
    Color color;
    String label;

    switch (type) {
      case ContactType.primary:
        color = AppTheme.successColor;
        label = 'Primary';
        break;
      case ContactType.secondary:
        color = AppTheme.infoColor;
        label = 'Secondary';
        break;
      case ContactType.billing:
        color = AppTheme.warningColor;
        label = 'Billing';
        break;
      case ContactType.technical:
        color = AppTheme.accentPurple;
        label = 'Technical';
        break;
      case ContactType.decision_maker:
        color = AppTheme.accentOrange;
        label = 'Decision Maker';
        break;
      case ContactType.influencer:
        color = Colors.grey;
        label = 'Influencer';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: AppTheme.spacingXS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getTypeText(ContactType type) {
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

  void _showContactDetails(ContactModel contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Detail Kontak: ${contact.firstName} ${contact.lastName}',
          style: AppTheme.heading4.copyWith(color: AppTheme.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nama', '${contact.firstName} ${contact.lastName}'),
              _buildDetailRow('Email', contact.email),
              _buildDetailRow('Telepon', contact.phone),
              if (contact.mobile != null)
                _buildDetailRow('Mobile', contact.mobile!),
              if (contact.position != null)
                _buildDetailRow('Jabatan', contact.position!),
              _buildDetailRow('Tipe', _getTypeText(contact.type)),
              if (contact.notes != null)
                _buildDetailRow('Catatan', contact.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tutup',
              style: AppTheme.labelMedium.copyWith(color: AppTheme.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}