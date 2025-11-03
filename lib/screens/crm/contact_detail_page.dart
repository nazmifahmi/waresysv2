import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/contact_model.dart';
import '../../providers/crm/contact_provider.dart';
import '../../constants/theme.dart';
import 'contact_form_page.dart';

class ContactDetailPage extends ConsumerWidget {
  final ContactModel contact;

  const ContactDetailPage({
    Key? key,
    required this.contact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          contact.fullName,
          style: AppTheme.heading4.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ContactFormPage(contact: contact),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Contact'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),
            SizedBox(height: AppTheme.spacingL),

            // Contact Information
            _buildContactInfoCard(),
            SizedBox(height: AppTheme.spacingL),

            // Professional Information
            _buildProfessionalInfoCard(),
            SizedBox(height: AppTheme.spacingL),

            // Contact Preferences
            _buildPreferencesCard(),
            SizedBox(height: AppTheme.spacingL),

            // Additional Information
            _buildAdditionalInfoCard(),
            SizedBox(height: AppTheme.spacingL),

            // Tags
            if (contact.tags.isNotEmpty) _buildTagsCard(),
            if (contact.tags.isNotEmpty) SizedBox(height: AppTheme.spacingL),

            // Notes
            if (contact.notes != null && contact.notes!.isNotEmpty)
              _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                '${contact.firstName[0]}${contact.lastName[0]}',
                style: AppTheme.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.fullName,
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  if (contact.position != null)
                    Text(
                      contact.position!,
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      _buildStatusChip(contact.status),
                      SizedBox(width: AppTheme.spacingS),
                      _buildTypeChip(contact.type),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            _buildInfoRow(Icons.email, 'Email', contact.email),
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.phone, 'Phone', contact.phone),
            if (contact.mobile != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.smartphone, 'Mobile', contact.mobile!),
            ],
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(
              Icons.contact_phone,
              'Preferred Method',
              _getContactMethodLabel(contact.preferredContactMethod),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Information',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            if (contact.position != null)
              _buildInfoRow(Icons.work, 'Position', contact.position!),
            if (contact.department != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.business, 'Department', contact.department!),
            ],
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.category, 'Type', _getContactTypeLabel(contact.type)),
            SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.primaryGreen),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  'Decision Maker: ${contact.isDecisionMaker ? "Yes" : "No"}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Preferences',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                const Icon(Icons.campaign, color: AppTheme.primaryGreen),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  'Marketing: ${contact.canReceiveMarketing ? "Allowed" : "Not Allowed"}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppTheme.primaryGreen),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  'Engagement Score: ${contact.engagementScore}%',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
            if (contact.lastContactDate != null) ...[
              SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppTheme.primaryGreen),
                  SizedBox(width: AppTheme.spacingM),
                  Text(
                    'Last Contact: ${_formatDate(contact.lastContactDate!)}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Information',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            if (contact.birthday != null) ...[
              _buildInfoRow(
                Icons.cake,
                'Birthday',
                '${contact.birthday!.day}/${contact.birthday!.month}/${contact.birthday!.year}',
              ),
              if (contact.age != null) ...[
                SizedBox(height: AppTheme.spacingM),
                _buildInfoRow(Icons.person, 'Age', '${contact.age} years old'),
              ],
              SizedBox(height: AppTheme.spacingM),
            ],
            if (contact.linkedinProfile != null) ...[
              _buildInfoRow(Icons.link, 'LinkedIn', contact.linkedinProfile!),
              SizedBox(height: AppTheme.spacingM),
            ],
            if (contact.twitterHandle != null) ...[
              _buildInfoRow(Icons.alternate_email, 'Twitter', contact.twitterHandle!),
              SizedBox(height: AppTheme.spacingM),
            ],
            _buildInfoRow(Icons.schedule, 'Created', _formatDate(contact.createdAt)),
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.update, 'Updated', _formatDate(contact.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
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
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: contact.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  labelStyle: AppTheme.labelSmall.copyWith(
                    color: AppTheme.primaryGreen,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: AppTheme.heading4.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            Text(
              contact.notes!,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimaryLight),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ContactStatus status) {
    Color color;
    switch (status) {
      case ContactStatus.active:
        color = AppTheme.successColor;
        break;
      case ContactStatus.inactive:
        color = AppTheme.warningColor;
        break;
      case ContactStatus.do_not_contact:
        color = AppTheme.errorColor;
        break;
      case ContactStatus.bounced:
        color = AppTheme.infoColor;
        break;
    }

    return Chip(
      label: Text(_getContactStatusLabel(status)),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: AppTheme.labelSmall.copyWith(color: color),
    );
  }

  Widget _buildTypeChip(ContactType type) {
    return Chip(
      label: Text(_getContactTypeLabel(type)),
      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
      labelStyle: AppTheme.labelSmall.copyWith(color: AppTheme.primaryGreen),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text('Are you sure you want to delete ${contact.fullName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(contactProvider.notifier).deleteContact(contact.id);
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting contact: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}