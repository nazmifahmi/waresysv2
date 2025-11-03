// CRM Providers - Central export file for all CRM state management
export 'customer_provider.dart';
export 'lead_provider.dart' hide crmServiceProvider;
export 'opportunity_provider.dart' hide crmServiceProvider;
export 'contact_provider.dart' hide crmServiceProvider;

// Re-export commonly used Riverpod classes
export 'package:flutter_riverpod/flutter_riverpod.dart';