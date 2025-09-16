import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import '../constants/theme.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        // Fetch user role after successful login
        final role = await _authService.getUserRole();
      if (mounted) {
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppTheme.textPrimary,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingXS,
                        ),
                        decoration: AppTheme.surfaceDecoration,
                        child: Text(
                          'WARESYS',
                          style: AppTheme.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXXXL),
                  
                  // Welcome Text
                  Text(
                    'Selamat Datang',
                    style: AppTheme.heading1,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Masuk ke akun Anda untuk melanjutkan',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXXL),
                  
                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingXXL),
                    decoration: AppTheme.cardDecoration,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masuk',
                            style: AppTheme.heading2.copyWith(
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXXL),
                           
                           // Email Field
                           CommonWidgets.buildTextField(
                             label: 'Email',
                             hint: 'Masukkan email Anda',
                             controller: _emailController,
                             keyboardType: TextInputType.emailAddress,
                             prefixIcon: Icons.email_outlined,
                             validator: (value) {
                               if (value == null || value.isEmpty) {
                                 return 'Silakan masukkan email Anda';
                               }
                               if (!value.contains('@')) {
                                 return 'Silakan masukkan email yang valid';
                               }
                               return null;
                             },
                           ),
                           const SizedBox(height: AppTheme.spacingL),
                           
                           // Password Field
                           CommonWidgets.buildTextField(
                             label: 'Password',
                             hint: 'Masukkan password Anda',
                             controller: _passwordController,
                             obscureText: true,
                             prefixIcon: Icons.lock_outlined,
                             validator: (value) {
                               if (value == null || value.isEmpty) {
                                 return 'Silakan masukkan password Anda';
                               }
                               return null;
                             },
                           ),
                           const SizedBox(height: AppTheme.spacingL),
                           
                           // Remember Me & Forgot Password
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Row(
                                 children: [
                                   Checkbox(
                                     value: _rememberMe,
                                     activeColor: AppTheme.accentBlue,
                                     onChanged: (val) {
                                       setState(() {
                                         _rememberMe = val ?? false;
                                       });
                                     },
                                   ),
                                   Text(
                                     'Ingat saya',
                                     style: AppTheme.bodySmall.copyWith(
                                       color: AppTheme.accentBlue,
                                     ),
                                   ),
                                 ],
                               ),
                               TextButton(
                                 onPressed: () {},
                                 child: Text(
                                   'Lupa Password?',
                                   style: AppTheme.bodySmall.copyWith(
                                     color: AppTheme.textSecondary,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           
                           // Error Message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: AppTheme.spacingS),
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(
                                    color: AppTheme.errorColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppTheme.errorColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppTheme.spacingS),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.errorColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                           
                           const SizedBox(height: AppTheme.spacingXXL),
                           
                           // Login Button
                           CommonWidgets.buildPrimaryButton(
                             text: 'Masuk',
                             onPressed: _login,
                             isLoading: _isLoading,
                             width: double.infinity,
                             icon: Icons.login,
                           ),
                           
                           const SizedBox(height: AppTheme.spacingXXL),
                           
                           // Register Link
                           Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text(
                                 'Belum punya akun? ',
                                 style: AppTheme.bodyMedium,
                               ),
                               TextButton(
                                 onPressed: () {
                                   Navigator.pushNamed(context, '/register');
                                 },
                                 child: Text(
                                   'Daftar',
                                   style: AppTheme.bodyMedium.copyWith(
                                     color: AppTheme.accentBlue,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           
                           const SizedBox(height: AppTheme.spacingXL),
                           
                           // Divider
                           Row(
                             children: [
                               Expanded(
                                 child: Divider(color: AppTheme.borderDark),
                               ),
                               Padding(
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: AppTheme.spacingL,
                                 ),
                                 child: Text(
                                   'ATAU',
                                   style: AppTheme.bodySmall.copyWith(
                                     color: AppTheme.textTertiary,
                                   ),
                                 ),
                               ),
                               Expanded(
                                 child: Divider(color: AppTheme.borderDark),
                               ),
                             ],
                           ),
                           
                           const SizedBox(height: AppTheme.spacingXL),
                           
                           // Social Login Buttons
                           Row(
                             children: [
                               Expanded(
                                 child: CommonWidgets.buildSecondaryButton(
                                   text: 'Google',
                                   onPressed: _signInWithGoogle,
                                   icon: Icons.g_mobiledata,
                                 ),
                               ),
                               const SizedBox(width: AppTheme.spacingM),
                               Expanded(
                                 child: CommonWidgets.buildSecondaryButton(
                                   text: 'Apple',
                                   onPressed: _signInWithApple,
                                   icon: Icons.apple,
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           ),
         ),
       ),
     );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Google sign in failed: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithApple();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Apple sign in failed: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
