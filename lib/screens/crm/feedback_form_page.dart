import 'package:flutter/material.dart';
import '../../models/crm/feedback_model.dart';
import '../../services/crm/feedback_repository.dart';

class FeedbackFormPage extends StatefulWidget {
  final FeedbackModel? existing;

  const FeedbackFormPage({super.key, this.existing});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _customerIdCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final FeedbackRepository _repository = FeedbackRepository();
  
  int _rating = 5;
  String _status = 'pending';
  bool _isLoading = false;

  final List<String> _statusOptions = ['pending', 'reviewed', 'resolved', 'closed'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final feedback = widget.existing!;
      _subjectCtrl.text = feedback.subject;
      _customerIdCtrl.text = feedback.customerId;
      _messageCtrl.text = feedback.message;
      _rating = feedback.rating;
      _status = feedback.status;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final feedback = FeedbackModel(
        feedbackId: widget.existing?.feedbackId ?? '',
        customerId: _customerIdCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        rating: _rating,
        status: _status,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existing != null) {
        await _repository.update(feedback);
      } else {
        await _repository.create(feedback);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing != null 
                ? 'Feedback berhasil diperbarui' 
                : 'Feedback berhasil ditambahkan'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = starValue),
              child: Icon(
                starValue <= _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '$_rating dari 5 bintang',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Feedback' : 'Tambah Feedback'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _customerIdCtrl,
              decoration: const InputDecoration(
                labelText: 'ID Customer',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ID Customer harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subjek',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subjek harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Pesan',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pesan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.existing != null ? 'Perbarui' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _customerIdCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }
}