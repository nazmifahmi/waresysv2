import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/crm/contact_model.dart';
import '../../providers/crm/contact_provider.dart';
import '../../constants/theme.dart';
import 'contact_form_page.dart';
import '../../widgets/common_widgets.dart';

class ContactDetailPage extends ConsumerWidget {
  final ContactModel contact;

  const ContactDetailPage({
    Key? key,
    required this.contact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CommonWidgets.buildAppBar(
        title: contact.fullName,
        actions: [
          CommonWidgets.buildAppBarAction(
            text: 'Edit',
            icon: Icons.edit,
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
            itemBuilder: (context) => const [
              PopupMenuItem(
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
    return CommonWidgets.buildDetailHeader(
      title: contact.fullName,
      subtitle: contact.position,
      avatarColor: AppTheme.primaryGreen,
      chips: [
        CommonWidgets.buildChip(
          text: _getContactStatusLabel(contact.status),
          color: _getStatusColor(contact.status),
          icon: Icons.info,
        ),
        CommonWidgets.buildChip(
          text: _getContactTypeLabel(contact.type),
          color: AppTheme.primaryGreen,
          icon: Icons.category,
        ),
      ],
    );
  }

  Widget _buildContactInfoCard() {
    return CommonWidgets.buildSectionCard(
      title: 'Informasi Kontak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.email, 'Email', contact.email),
          SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.phone, 'Telepon', contact.phone),
          if (contact.mobile != null) ...[
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.smartphone, 'HP', contact.mobile!),
          ],
          SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(
            Icons.contact_phone,
            'Metode Favorit',
            _getContactMethodLabel(contact.preferredContactMethod),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard() {
    return CommonWidgets.buildSectionCard(
      title: 'Informasi Profesional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contact.position != null)
            _buildInfoRow(Icons.work, 'Posisi', contact.position!),
          if (contact.department != null) ...[
            SizedBox(height: AppTheme.spacingM),
            _buildInfoRow(Icons.business, 'Departemen', contact.department!),
          ],
          SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.category, 'Tipe', _getContactTypeLabel(contact.type)),
          SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.primaryGreen),
              SizedBox(width: AppTheme.spacingM),
              Text(
                'Decision Maker: ${contact.isDecisionMaker ? "Ya" : "Tidak"}',
                style: AppTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return CommonWidgets.buildSectionCard(
      title: 'Preferensi Kontak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppTheme.primaryGreen),
              SizedBox(width: AppTheme.spacingM),
              Text('Marketing: ${contact.canReceiveMarketing ? "Diizinkan" : "Tidak Diizinkan"}',
                  style: AppTheme.bodyLarge),
            ],
          ),
          SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.primaryGreen),
              SizedBox(width: AppTheme.spacingM),
              Text('Engagement Score: ${contact.engagementScore}%', style: AppTheme.bodyLarge),
            ],
          ),
          if (contact.lastContactDate != null) ...[
            SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.primaryGreen),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  'Kontak Terakhir: ${_formatDate(contact.lastContactDate!)}',
                  style: AppTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return CommonWidgets.buildSectionCard(
      title: 'Informasi Tambahan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contact.birthday != null) ...[
            _buildInfoRow(
              Icons.cake,
              'Ulang Tahun',
              '${contact.birthday!.day}/${contact.birthday!.month}/${contact.birthday!.year}',
            ),
            if (contact.age != null) ...[
              SizedBox(height: AppTheme.spacingM),
              _buildInfoRow(Icons.person, 'Usia', '${contact.age} tahun'),
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
          _buildInfoRow(Icons.schedule, 'Dibuat', _formatDate(contact.createdAt)),
          SizedBox(height: AppTheme.spacingM),
          _buildInfoRow(Icons.update, 'Diperbarui', _formatDate(contact.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return CommonWidgets.buildSectionCard(
      title: 'Tags',
      child: Wrap(
        spacing: AppTheme.spacingS,
        runSpacing: AppTheme.spacingS,
        children: contact.tags.map((tag) {
          return CommonWidgets.buildChip(
            text: tag,
            color: AppTheme.primaryGreen,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesCard() {
    return CommonWidgets.buildSectionCard(
      title: 'Catatan',
      child: Text(contact.notes!, style: AppTheme.bodyLarge),
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
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
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
    // Tidak digunakan lagi, diganti dengan CommonWidgets.buildChip
    return const SizedBox.shrink();
  }

  Widget _buildTypeChip(ContactType type) {
    // Tidak digunakan lagi, diganti dengan CommonWidgets.buildChip
    return const SizedBox.shrink();
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

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.active:
        return AppTheme.successColor;
      case ContactStatus.inactive:
        return AppTheme.warningColor;
      case ContactStatus.do_not_contact:
        return AppTheme.errorColor;
      case ContactStatus.bounced:
        return AppTheme.infoColor;
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