import 'package:flutter/material.dart';

class AppTheme {
  // ===== COLOR PALETTE =====
  // Primary Colors
  static const Color primaryGreen = Color(0xFF00875A);
  static const Color secondaryGreen = Color(0xFF006C46);
  
  // Dark Theme Colors (Enhanced Contrast)
  static const Color backgroundDark = Color(0xFF0F0F0F); // Slightly lighter than pure black
  static const Color surfaceDark = Color(0xFF1F1F1F); // Better contrast from background
  static const Color cardDark = Color(0xFF2D2D2D); // More distinct from surface
  static const Color borderDark = Color(0xFF404040); // More visible borders
  
  // Light Theme Colors (Enhanced Contrast)
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Color(0xFFFFFFF);
  static const Color borderLight = Color(0xFFD1D5DB);
  
  // Dark Theme Text Colors (Enhanced Contrast)
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for maximum contrast
  static const Color textSecondary = Color(0xFFD1D5DB); // Lighter gray for better readability
  static const Color textTertiary = Color(0xFF9CA3AF); // Medium gray with good contrast
  
  // Light Theme Text Colors (Enhanced Contrast)
  static const Color textPrimaryLight = Color(0xFF111827); // Darker for better contrast
  static const Color textSecondaryLight = Color(0xFF374151); // Darker secondary text
  static const Color textTertiaryLight = Color(0xFF6B7280); // Improved tertiary contrast
  
  // Accent Colors (Enhanced Contrast)
  static const Color accentBlue = Color(0xFF2563EB); // Darker blue for better contrast
  static const Color accentGreen = Color(0xFF059669); // Darker green for better contrast
  static const Color accentOrange = Color(0xFFD97706); // Darker orange for better contrast
  static const Color accentPurple = Color(0xFF7C3AED); // Darker purple for better contrast
  static const Color accentRed = Color(0xFFDC2626); // Darker red for better contrast
  
  // Status Colors (Enhanced Contrast)
  static const Color successColor = Color(0xFF059669); // Darker green for better visibility
  static const Color warningColor = Color(0xFFD97706); // Darker orange for better visibility
  static const Color errorColor = Color(0xFFDC2626); // Darker red for better visibility
  static const Color infoColor = Color(0xFF2563EB); // Darker blue for better visibility
  
  // ===== GRADIENTS =====
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, secondaryGreen],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDark, surfaceDark],
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, surfaceLight],
  );
  
  // ===== TYPOGRAPHY =====
  static const String fontFamily = 'Poppins';
  
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );
  
  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );
  
  // Labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );
  
  // ===== SPACING =====
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;
  
  // ===== BORDER RADIUS =====
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  
  // ===== SHADOWS =====
  static const List<BoxShadow> shadowLight = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> shadowHeavy = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  // ===== COMPONENT STYLES =====
  
  // Cards
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardDark,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: borderDark),
    boxShadow: shadowMedium,
  );
  
  static BoxDecoration get surfaceDecoration => BoxDecoration(
    color: surfaceDark,
    borderRadius: BorderRadius.circular(radiusXL),
    border: Border.all(color: borderDark),
  );
  
  // Buttons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accentBlue,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
    ),
    elevation: 0,
    textStyle: labelLarge,
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXL,
      vertical: spacingM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusM),
      side: const BorderSide(color: borderDark),
    ),
    elevation: 0,
    textStyle: labelLarge,
  );
  
  // Input Fields
  static InputDecoration inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: surfaceDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: const BorderSide(color: borderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: const BorderSide(color: borderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusM),
      borderSide: const BorderSide(color: accentBlue),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
    hintStyle: bodyMedium.copyWith(color: textTertiary),
  );
  
  // Feature Cards (for main menu)
  static Widget buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(spacingL),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(radiusM),
          border: Border.all(color: borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(radiusS),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: spacingM),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: heading4,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: spacingXS),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // App Bar
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: backgroundDark,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: heading3,
  );
  
  // Bottom Navigation
  static BottomNavigationBarThemeData get bottomNavTheme => BottomNavigationBarThemeData(
    backgroundColor: surfaceDark,
    selectedItemColor: accentBlue,
    unselectedItemColor: textTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );
  
  // Theme Data
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentGreen,
      surface: surfaceDark,
      background: backgroundDark,
      error: errorColor,
    ),
    appBarTheme: appBarTheme,
    bottomNavigationBarTheme: bottomNavTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderDark),
      ),
    ),
  );
  
  // Light Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentGreen,
      surface: surfaceLight,
      background: backgroundLight,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        fontFamily: fontFamily,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: accentBlue,
      unselectedItemColor: textTertiaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingXL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: accentBlue),
      ),
    ),
  );
  
  // ===== LEGACY SUPPORT =====
  // Keep old properties for backward compatibility
  static const TextStyle headingStyle = heading1;
  static const TextStyle subheadingStyle = heading3;
  static const TextStyle bodyTextStyle = bodyLarge;
  static const TextStyle buttonTextStyle = labelLarge;
  static const TextStyle cardTitleStyle = heading2;
  static const TextStyle cardSubtitleStyle = bodySmall;
  
  static InputDecoration textFieldDecoration(String hint) => inputDecoration(hint);
}