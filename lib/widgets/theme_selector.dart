import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/theme.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode 
                ? AppTheme.surfaceDark.withOpacity(0.8)
                : AppTheme.surfaceLight.withOpacity(0.9),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Tema Tampilan',
                style: AppTheme.heading3.copyWith(
                  color: themeProvider.isDarkMode 
                      ? AppTheme.textPrimary
                      : AppTheme.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Pilih tema yang nyaman untuk Anda',
                style: AppTheme.bodyMedium.copyWith(
                  color: themeProvider.isDarkMode 
                      ? AppTheme.textSecondary
                      : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXL),
              
              // Theme Options
              Row(
                children: [
                  // Light Theme Option
                  Expanded(
                    child: _buildThemeOption(
                      context: context,
                      title: 'Mode Cerah',
                      subtitle: 'Tampilan terang dan segar',
                      icon: Icons.light_mode,
                      isSelected: themeProvider.isLightMode,
                      onTap: () => themeProvider.setLightTheme(),
                      backgroundColor: AppTheme.backgroundLight,
                      textColor: AppTheme.textPrimaryLight,
                      iconColor: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  
                  // Dark Theme Option
                  Expanded(
                    child: _buildThemeOption(
                      context: context,
                      title: 'Mode Gelap',
                      subtitle: 'Tampilan gelap dan elegan',
                      icon: Icons.dark_mode,
                      isSelected: themeProvider.isDarkMode,
                      onTap: () => themeProvider.setDarkTheme(),
                      backgroundColor: AppTheme.backgroundDark,
                      textColor: AppTheme.textPrimary,
                      iconColor: AppTheme.accentBlue,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingL,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Preview Container
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: backgroundColor == AppTheme.backgroundLight 
                      ? AppTheme.borderLight
                      : AppTheme.borderDark,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Title and Subtitle
            Text(
              title,
              style: AppTheme.labelLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Selection Indicator
            const SizedBox(height: AppTheme.spacingM),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.accentBlue : textColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}