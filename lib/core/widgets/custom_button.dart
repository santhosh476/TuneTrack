import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (isOutlined ? Colors.transparent : AppColors.primaryAccent);
    final effectiveFg =
        textColor ?? (isOutlined ? AppColors.primaryText : Colors.black);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          elevation: 0,
          side: isOutlined
              ? const BorderSide(color: AppColors.border, width: 1.2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: effectiveFg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTypography.labelLarge.copyWith(
                      color: effectiveFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
