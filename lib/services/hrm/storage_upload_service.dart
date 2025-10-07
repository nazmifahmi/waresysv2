import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadEmployeeContract({
    required String employeeId,
    required File file,
  }) async {
    final ref = _storage.ref().child('contracts').child('$employeeId-${DateTime.now().millisecondsSinceEpoch}');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadClaimReceipt({
    required String employeeId,
    required File file,
  }) async {
    final ref = _storage.ref().child('claim_receipts').child('$employeeId-${DateTime.now().millisecondsSinceEpoch}');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadPayslip({
    required String employeeId,
    required File file,
  }) async {
    final ref = _storage.ref().child('payslips').child('$employeeId-${DateTime.now().millisecondsSinceEpoch}.pdf');
    final task = await ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));
    return await task.ref.getDownloadURL();
  }
}