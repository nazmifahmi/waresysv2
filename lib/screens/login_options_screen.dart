import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

class LoginOptionsScreen extends StatefulWidget {
  const LoginOptionsScreen({super.key});

  @override
  State<LoginOptionsScreen> createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends State<LoginOptionsScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential.user != null && mounted) {
        final role = await _authService.getUserRole();
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Google Sign In failed: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithApple();
      if (userCredential.user != null && mounted) {
        final role = await _authService.getUserRole();
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        CommonWidgets.showSnackBar(
          context: context,
          message: 'Apple Sign In failed: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
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
                
                const Spacer(),
                
                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Metode',
                      style: AppTheme.heading1.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentOrange,
                            AppTheme.accentRed,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: Text(
                        'LOGIN',
                        style: AppTheme.heading2.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    Text(
                      'Masuk dengan akun sosial media Anda untuk kemudahan akses',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Login Options Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXXL),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      Text(
                        'Opsi Login',
                        style: AppTheme.heading2.copyWith(
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXXL),
                      
                      // Google Sign In Button
                      CommonWidgets.buildPrimaryButton(
                        text: 'Masuk dengan Google',
                        onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                        isLoading: _isLoading,
                        width: double.infinity,
                        icon: Icons.g_mobiledata,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Apple Sign In Button
                      CommonWidgets.buildSecondaryButton(
                        text: 'Masuk dengan Apple',
                        onPressed: _isLoading ? () {} : _handleAppleSignIn,
                        isEnabled: !_isLoading,
                        width: double.infinity,
                        icon: Icons.apple,
                      ),
                      const SizedBox(height: AppTheme.spacingXXL),
                      
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
                              'atau',
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
                      const SizedBox(height: AppTheme.spacingXXL),
                      
                      // Email Login Button
                      CommonWidgets.buildSecondaryButton(
                        text: 'Masuk dengan Email',
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        width: double.infinity,
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      
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
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
