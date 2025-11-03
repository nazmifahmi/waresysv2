import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/theme_selector.dart';
import '../providers/theme_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            backgroundColor: themeProvider.isDarkMode 
                ? AppTheme.backgroundDark 
                : AppTheme.backgroundLight,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeProvider.isDarkMode
                      ? [
                          AppTheme.backgroundDark,
                          AppTheme.surfaceDark,
                          AppTheme.accentBlue.withOpacity(0.1),
                        ]
                      : [
                          AppTheme.backgroundLight,
                          AppTheme.surfaceLight,
                          AppTheme.accentBlue.withOpacity(0.05),
                        ],
                ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingM,
                              vertical: AppTheme.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode 
                                  ? AppTheme.surfaceDark 
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: themeProvider.isDarkMode 
                                    ? AppTheme.borderDark 
                                    : AppTheme.borderLight,
                              ),
                            ),
                            child: Text(
                              'WARESYS',
                              style: AppTheme.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: themeProvider.isDarkMode 
                                    ? AppTheme.textPrimary 
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.palette_outlined,
                              color: themeProvider.isDarkMode 
                                  ? AppTheme.textSecondary 
                                  : AppTheme.textSecondaryLight,
                            ),
                            onPressed: () {
                              _showThemeSelector(context);
                            },
                            tooltip: 'Pilih Tema',
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Welcome Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang di',
                            style: AppTheme.heading1.copyWith(
                              fontSize: 28,
                              color: themeProvider.isDarkMode 
                                  ? AppTheme.textPrimary 
                                  : AppTheme.textPrimaryLight,
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
                                  AppTheme.accentBlue,
                                  AppTheme.accentGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                            child: Text(
                              'WareSys',
                              style: AppTheme.heading1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Action Buttons Card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingXXL),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode 
                              ? AppTheme.cardDark 
                              : AppTheme.cardLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: themeProvider.isDarkMode 
                                ? AppTheme.borderDark 
                                : AppTheme.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Mulai Perjalanan Bisnis Anda',
                              style: AppTheme.heading2.copyWith(
                                color: AppTheme.accentBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            Text(
                              'Kelola inventori, keuangan, dan operasional bisnis UMKM Anda dengan mudah dan efisien',
                              style: AppTheme.bodyMedium.copyWith(
                                color: themeProvider.isDarkMode 
                                    ? AppTheme.textSecondary 
                                    : AppTheme.textSecondaryLight,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacingXXXL),
                            
                            // Login Button
                            CommonWidgets.buildPrimaryButton(
                              text: 'Masuk',
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              width: double.infinity,
                              icon: Icons.login,
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            
                            // Register Button
                            CommonWidgets.buildSecondaryButton(
                              text: 'Daftar',
                              onPressed: () {
                                // Navigate to register
                                Navigator.pushNamed(context, '/register');
                              },
                              width: double.infinity,
                              icon: Icons.person_add,
                            ),
                            const SizedBox(height: AppTheme.spacingXXL),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: themeProvider.isDarkMode 
                                        ? AppTheme.borderDark 
                                        : AppTheme.borderLight,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingL,
                                  ),
                                  child: Text(
                                    'atau',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: themeProvider.isDarkMode 
                                          ? AppTheme.textTertiary 
                                          : AppTheme.textTertiaryLight,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: themeProvider.isDarkMode 
                                        ? AppTheme.borderDark 
                                        : AppTheme.borderLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingXXL),
                            
                            // Login Options Button
                            CommonWidgets.buildSecondaryButton(
                              text: 'Opsi Login Lainnya',
                              onPressed: () {
                                Navigator.pushNamed(context, '/login-options');
                              },
                              width: double.infinity,
                              icon: Icons.more_horiz,
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            
                            // Terms & Privacy
                            Text.rich(
                              TextSpan(
                                text: 'Dengan melanjutkan, Anda menyetujui ',
                                style: AppTheme.bodySmall.copyWith(
                                  color: themeProvider.isDarkMode 
                                      ? AppTheme.textTertiary 
                                      : AppTheme.textTertiaryLight,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Syarat & Ketentuan',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentBlue,
                                    ),
                                  ),
                                  const TextSpan(text: ' dan '),
                                  TextSpan(
                                    text: 'Kebijakan Privasi',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentBlue,
                                    ),
                                  ),
                                  const TextSpan(text: ' kami.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: const ThemeSelector(),
        );
      },
    );
  }
}