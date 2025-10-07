import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/hrm/claim_model.dart';
import '../../providers/hrm/claim_bloc.dart';
import '../../services/hrm/claim_repository.dart';
import '../../services/hrm/storage_upload_service.dart';

class ClaimFormPage extends StatefulWidget {
  final String employeeId;
  const ClaimFormPage({super.key, required this.employeeId});

  @override
  State<ClaimFormPage> createState() => _ClaimFormPageState();
}

class _ClaimFormPageState extends State<ClaimFormPage> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _receipt;
  bool _saving = false;

  late final ClaimBloc _bloc;
  final StorageUploadService _uploader = StorageUploadService();

  @override
  void initState() {
    super.initState();
    _bloc = ClaimBloc(repository: ClaimRepository());
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _receipt = File(x.path));
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty || (double.tryParse(_amountCtrl.text.trim()) ?? -1) < 0) return;
    setState(() => _saving = true);
    String? url;
    if (_receipt != null) {
      url = await _uploader.uploadClaimReceipt(employeeId: widget.employeeId, file: _receipt!);
    }
    final model = ClaimModel(
      claimId: '',
      employeeId: widget.employeeId,
      submissionDate: DateTime.now(),
      description: _descCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text.trim()) ?? 0,
      receiptImageUrl: url,
    );
    await _bloc.submit(model);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Klaim')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(labelText: 'Jumlah'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(_receipt?.path.split('/').last ?? 'Belum ada bukti terunggah')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Pilih Gambar')),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Mengirim...' : 'Kirim'),
            ),
          ),
        ]),
      ),
    );
  }
}