import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Import Provider baru kita
import 'package:waresys_fix1/providers/ai_provider.dart';
import 'package:waresys_fix1/providers/chat_provider.dart';

import 'package:waresys_fix1/providers/auth_provider.dart';
import 'package:waresys_fix1/providers/transaction_provider.dart';
import 'package:waresys_fix1/providers/inventory_provider.dart';
import 'package:waresys_fix1/providers/news_provider.dart';
import 'package:waresys_fix1/providers/theme_provider.dart';
import 'package:waresys_fix1/screens/welcome_screen.dart';
import 'package:waresys_fix1/screens/login_screen.dart';
import 'package:waresys_fix1/screens/login_options_screen.dart';
import 'package:waresys_fix1/screens/register_screen.dart';
import 'package:waresys_fix1/screens/home_screen.dart';
import 'package:waresys_fix1/screens/admin_home_screen.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_screen.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_notifications_page.dart';
import 'package:waresys_fix1/screens/monitoring/monitor_activity_page.dart';
import 'package:waresys_fix1/screens/finances/finance_screen.dart';
import 'package:waresys_fix1/screens/inventory/inventory_screen.dart';
import 'package:waresys_fix1/screens/chat/chat_screen.dart';
import 'package:waresys_fix1/constants/theme.dart';
import 'package:waresys_fix1/services/ai/ai_service_test.dart';
import 'package:waresys_fix1/services/firestore_connection_service.dart';
import 'package:waresys_fix1/utils/performance_optimizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase dengan timeout dan error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
    
    // Inisialisasi FirestoreConnectionService setelah Firebase berhasil
     await FirestoreConnectionService().initialize();
     debugPrint('✅ FirestoreConnectionService initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('📱 Continuing with offline mode...');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        // Daftarkan AIProvider kita di sini
        ChangeNotifierProvider(create: (_) => AIProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'WareSys',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          // Kita tidak lagi pakai initialRoute, tapi langsung menunjuk ke SplashScreen
          home: const SplashScreen(),
          // Routes tetap ada untuk navigasi setelah aplikasi berjalan
          routes: {
            '/welcome': (context) => const WelcomeScreen(), // Ganti rute '/' menjadi '/welcome'
            '/login': (context) => const LoginScreen(),
            '/login-options': (context) => const LoginOptionsScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/admin': (context) => const AdminHomeScreen(),
            '/monitor': (context) => const MonitorScreen(),
            '/monitor/notifications': (context) => const MonitorNotificationsPage(),
            '/monitor/activity': (context) => const MonitorActivityPage(),
            '/finances': (context) => const FinanceScreen(),
            '/inventory': (context) => const InventoryScreen(),
            '/chat': (context) => const ChatScreen(),
          },
        );
      },
    );
  }
}

// --- LAYAR BARU: "Dapur" untuk Inisialisasi ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Start performance monitoring
      PerformanceMetrics.startTimer('app_initialization');
      if (kDebugMode) {
        PerformanceOptimizer.monitorFrameRate();
      }
      
      // Panggil inisialisasi AI dari AIProvider dengan timeout
      try {
        await Provider.of<AIProvider>(context, listen: false).initialize()
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('⚠️ AI initialization failed: $e');
      }
      
      // Run AI Service tests in debug mode dengan timeout
      if (kDebugMode) {
        try {
          await compute(aiTester, null)
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('⚠️ AI testing failed: $e');
        }
      }
      
      PerformanceMetrics.stopTimer('app_initialization');

      // Setelah selesai, arahkan ke halaman selamat datang
      // 'pushReplacementNamed' agar pengguna tidak bisa kembali ke splash screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    } catch (e) {
      PerformanceMetrics.stopTimer('app_initialization');
      // Jika GAGAL, tampilkan dialog error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Initialization Failed'),
            content: Text('Could not initialize application services: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selama inisialisasi, tampilkan logo dan loading indicator
    return const Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kamu bisa ganti dengan logo Waresys di sini
            Icon(Icons.warehouse_rounded, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Waresys',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Top-level function to run AI tests in a separate isolate
Future<void> aiTester(_) async {
  await AIServiceTest.runTests();
  await AIServiceTest.performanceTest();
}
