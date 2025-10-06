import 'package:flutter/material.dart';
import '../constants/theme.dart';

/// Common reusable widgets untuk konsistensi UI di seluruh aplikasi
class CommonWidgets {
  
  // ===== APP BAR =====
  static AppBar buildAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      title: Text(title, style: AppTheme.heading3),
      centerTitle: centerTitle,
      backgroundColor: AppTheme.backgroundDark,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: leading ?? (onBackPressed != null 
        ? IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: onBackPressed,
          )
        : null),
      actions: actions,
    );
  }
  
  // ===== CARDS =====
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingS),
      child: Material(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingL),
            decoration: AppTheme.cardDecoration,
            child: child,
          ),
        ),
      ),
    );
  }
  
  static Widget buildInfoCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return buildCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.accentBlue).withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.accentBlue,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
          Text(title, style: AppTheme.labelMedium),
          const SizedBox(height: AppTheme.spacingXS),
          Text(value, style: AppTheme.heading4),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(subtitle, style: AppTheme.bodySmall),
          ],
        ],
      ),
    );
  }
  
  // ===== BUTTONS =====
  static Widget buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isEnabled = true,
    IconData? icon,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: AppTheme.primaryButtonStyle,
        child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppTheme.spacingS),
                ],
                Text(text),
              ],
            ),
      ),
    );
  }
  
  static Widget buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isEnabled = true,
    IconData? icon,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: AppTheme.secondaryButtonStyle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacingS),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }
  
  // ===== INPUT FIELDS =====
  static Widget buildTextField({
    required String label,
    String? hint,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    IconData? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelMedium),
        const SizedBox(height: AppTheme.spacingXS),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          style: AppTheme.bodyMedium,
          decoration: AppTheme.inputDecoration(hint ?? label).copyWith(
            prefixIcon: prefixIcon != null 
              ? Icon(prefixIcon, color: AppTheme.textSecondary)
              : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
  
  // ===== LOADING STATES =====
  static Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
  
  static Widget buildEmptyState({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
            Text(
              title,
              style: AppTheme.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                subtitle,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingXL),
              action,
            ],
          ],
        ),
      ),
    );
  }
  
  static Widget buildErrorState({
    required String title,
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: AppTheme.heading4.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                subtitle,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingXL),
              buildPrimaryButton(
                text: 'Coba Lagi',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // ===== LISTS =====
  static Widget buildListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return buildCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: AppTheme.spacingM),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spacingM),
            trailing,
          ],
        ],
      ),
    );
  }
  
  // ===== DIALOGS =====
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(title, style: AppTheme.heading4),
        content: Text(content, style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmText,
              style: AppTheme.labelMedium.copyWith(
                color: isDestructive ? AppTheme.errorColor : AppTheme.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ===== SNACKBARS =====
  static void showSnackBar({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    Color backgroundColor;
    Color textColor = AppTheme.textPrimary;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        backgroundColor = AppTheme.errorColor;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        backgroundColor = AppTheme.warningColor;
        icon = Icons.warning;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = AppTheme.infoColor;
        icon = Icons.info;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium.copyWith(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: textColor,
              onPressed: onAction,
            )
          : null,
      ),
    );
  }
  
  // ===== SECTIONS =====
  static Widget buildSection({
    required String title,
    required Widget child,
    Widget? trailing,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTheme.heading3),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          child,
        ],
      ),
    );
  }
}

// ===== ENUMS =====
enum SnackBarType {
  success,
  error,
  warning,
  info,
}