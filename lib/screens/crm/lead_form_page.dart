import 'package:flutter/material.dart';
import '../../models/crm/lead_model.dart';
import '../../services/crm/lead_repository.dart';

class LeadFormPage extends StatefulWidget {
  final LeadModel? existing;
  const LeadFormPage({super.key, this.existing});

  @override
  State<LeadFormPage> createState() => _LeadFormPageState();
}

class _LeadFormPageState extends State<LeadFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _sourceCtrl = TextEditingController();
  final _contactInfoCtrl = TextEditingController();
  final _assignedToCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  
  String _selectedStatus = 'New';
  bool _saving = false;
  
  final LeadRepository _repository = LeadRepository();
  final List<String> _statusOptions = ['New', 'Qualified', 'Converted', 'Lost'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final lead = widget.existing!;
      _sourceCtrl.text = lead.source;
      _contactInfoCtrl.text = lead.contactInfo;
      _assignedToCtrl.text = lead.assignedTo;
      _scoreCtrl.text = lead.score.toString();
      _selectedStatus = lead.status;
    } else {
      _scoreCtrl.text = '50'; // Default score
    }
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _contactInfoCtrl.dispose();
    _assignedToCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      final lead = LeadModel(
        leadId: widget.existing?.leadId ?? '',
        source: _sourceCtrl.text.trim(),
        contactInfo: _contactInfoCtrl.text.trim(),
        status: _selectedStatus,
        score: int.tryParse(_scoreCtrl.text.trim()) ?? 50,
        assignedTo: _assignedToCtrl.text.trim(),
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (widget.existing == null) {
        await _repository.create(lead);
      } else {
        await _repository.update(lead);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Tambah Lead' : 'Edit Lead'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _sourceCtrl,
              decoration: const InputDecoration(
                labelText: 'Sumber Lead',
                border: OutlineInputBorder(),
                hintText: 'Website, Referral, Social Media, dll.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Sumber lead harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactInfoCtrl,
              decoration: const InputDecoration(
                labelText: 'Informasi Kontak',
                border: OutlineInputBorder(),
                hintText: 'Email, telepon, atau informasi kontak lainnya',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informasi kontak harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _assignedToCtrl,
              decoration: const InputDecoration(
                labelText: 'Ditugaskan Kepada',
                border: OutlineInputBorder(),
                hintText: 'Nama sales person (opsional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _scoreCtrl,
              decoration: const InputDecoration(
                labelText: 'Lead Score (0-100)',
                border: OutlineInputBorder(),
                hintText: 'Skor potensi lead',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lead score harus diisi';
                }
                final score = int.tryParse(value.trim());
                if (score == null || score < 0 || score > 100) {
                  return 'Lead score harus antara 0-100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) => 
                DropdownMenuItem(value: status, child: Text(status))
              ).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value ?? 'New'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving 
                  ? const CircularProgressIndicator()
                  : Text(widget.existing == null ? 'Tambah' : 'Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}