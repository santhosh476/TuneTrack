import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class NetworkOrAssetImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;

  const NetworkOrAssetImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(radius);
    }

    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(radius),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AppColors.surface,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryAccent),
                ),
              ),
            );
          },
        ),
      );
    }

    // Local asset image
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(radius),
      ),
    );
  }

  Widget _buildPlaceholder(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [AppColors.surfaceLight, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: (width != null && width! > 0)
              ? (width! * 0.4).clamp(16.0, 48.0)
              : 24.0,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
