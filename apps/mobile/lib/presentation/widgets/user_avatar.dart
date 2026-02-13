import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable user avatar widget with network image or placeholder
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  final double size;
  final bool showShadow;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.fullName,
    this.size = 100,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[UserAvatar] Building with URL: $avatarUrl');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      debugPrint('[UserAvatar] No URL, showing placeholder');
      return _buildPlaceholder();
    }

    return Image.network(
      avatarUrl!,
      fit: BoxFit.cover,
      width: size,
      height: size,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('[UserAvatar] Image loaded successfully');
          return child;
        }
        debugPrint(
            '[UserAvatar] Loading: ${loadingProgress.cumulativeBytesLoaded}');
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[UserAvatar] Error loading image: $error');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
