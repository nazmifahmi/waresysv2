import 'package:flutter/material.dart';

class CRMHomePage extends StatelessWidget {
  const CRMHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRM')),
      body: const Center(
        child: Text('CRM Module Home - Leads, Contacts, Activities, Tickets, Campaigns'),
      ),
    );
  }
}


