import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock platform interface setup
  const channel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'test-api-key',
            'appId': 'test-app-id',
            'messagingSenderId': 'test-sender-id',
            'projectId': 'test-project',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (methodCall.method == 'Firebase#initializeApp') {
      return {
        'name': '[DEFAULT]',
        'options': {
          'apiKey': 'test-api-key',
          'appId': 'test-app-id',
          'messagingSenderId': 'test-sender-id',
          'projectId': 'test-project',
        },
        'pluginConstants': {},
      };
    }
    return null;
  });
}

Future<void> setupFirebaseForTesting() async {
  setupFirebaseMocks();
}

// Get a fake Firestore instance
FakeFirebaseFirestore getFakeFirestore() {
  return FakeFirebaseFirestore();
} 