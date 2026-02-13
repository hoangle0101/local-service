import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

/// Reusable widget for avatar/profile picture selection
class AvatarPickerWidget extends StatefulWidget {
  /// Initial image URL (for existing profile pictures)
  final String? imageUrl;

  /// Size of the avatar
  final double size;

  /// Callback when image is selected
  final void Function(File image)? onImageSelected;

  /// Placeholder icon when no image
  final IconData placeholderIcon;

  /// Primary color for styling
  final Color? primaryColor;

  /// Whether editing is enabled
  final bool editable;

  const AvatarPickerWidget({
    super.key,
    this.imageUrl,
    this.size = 120,
    this.onImageSelected,
    this.placeholderIcon = Icons.person,
    this.primaryColor,
    this.editable = true,
  });

  @override
  State<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends State<AvatarPickerWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  Color get _primaryColor => widget.primaryColor ?? AppColors.primary;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final file = File(image.path);
        setState(() {
          _selectedImage = file;
        });
        widget.onImageSelected?.call(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    if (!widget.editable) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: _primaryColor),
              ),
              title: const Text('Chụp ảnh'),
              subtitle: const Text('Sử dụng camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: const Text('Chọn từ thư viện'),
              subtitle: const Text('Chọn ảnh có sẵn'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.editable ? _showImageSourceDialog : null,
          child: Stack(
            children: [
              // Avatar image
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryColor.withOpacity(0.8),
                      _primaryColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildAvatarContent(),
              ),
              // Edit button
              if (widget.editable)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: widget.size * 0.33,
                    height: widget.size * 0.33,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: _primaryColor,
                      size: widget.size * 0.18,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.editable) ...[
          const SizedBox(height: 12),
          Text(
            'Nhấn để thay đổi ảnh đại diện',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarContent() {
    // Show selected image file
    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
        ),
      );
    }

    // Show existing network image
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (_, __, ___) => Icon(
            widget.placeholderIcon,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      );
    }

    // Show placeholder icon
    return Icon(
      widget.placeholderIcon,
      color: Colors.white,
      size: widget.size * 0.5,
    );
  }
}
