import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/provider_repository.dart';
import 'package:mobile/data/repositories/track_asia_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/provider_datasource.dart';
import '../../../data/datasources/track_asia_datasource.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/minimalist_widgets.dart';

class ProviderEditProfileScreen extends StatefulWidget {
  const ProviderEditProfileScreen({super.key});

  @override
  State<ProviderEditProfileScreen> createState() =>
      _ProviderEditProfileScreenState();
}

class _ProviderEditProfileScreenState extends State<ProviderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  final ProviderRepository _providerRepository = ProviderRepository();
  final TrackAsiaRepository _trackAsiaRepository = TrackAsiaRepository();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;

  // Profile image
  File? _selectedImage;
  String? _existingImageUrl;

  List<AddressPrediction> _addressSuggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  int _selectedRadius = 5000;
  final List<int> _radiusOptions = [
    1000,
    2000,
    3000,
    5000,
    7000,
    10000,
    15000,
    20000,
    25000,
    30000,
    40000
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadProfile() {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated && state.user?.providerProfile != null) {
      final profile = state.user!.providerProfile!;
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _addressController.text = profile.address ?? '';
      final profileRadius = profile.serviceRadiusM ?? 5000;
      _selectedRadius = profileRadius.clamp(1000, 40000);
      _latitude = profile.latitude;
      _longitude = profile.longitude;
      // Avatar is loaded from UserProfileEntity
      _existingImageUrl = state.user?.profile?.avatarUrl;
    }
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions = await _trackAsiaRepository.searchAddress(query);
        if (mounted) {
          setState(() {
            _addressSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('[EditProfile] Address search error: $e');
      }
    });
  }

  Future<void> _selectAddress(AddressPrediction prediction) async {
    setState(() => _showSuggestions = false);

    try {
      final detail =
          await _trackAsiaRepository.getPlaceDetail(prediction.placeId);
      if (mounted && detail != null) {
        setState(() {
          _addressController.text = prediction.description;
          _latitude = detail.latitude;
          _longitude = detail.longitude;
        });
      } else if (mounted) {
        setState(() => _addressController.text = prediction.description);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: Colors.red.shade400),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
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

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng bật dịch vụ định vị'),
              backgroundColor: Colors.orange.shade400,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quyền vị trí bị từ chối vĩnh viễn'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await _trackAsiaRepository.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        if (address != null) {
          setState(() {
            _addressController.text = address.displayText;
            _latitude = address.latitude;
            _longitude = address.longitude;
            _isGettingLocation = false;
          });
        } else {
          setState(() {
            _addressController.text =
                'Vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            _latitude = position.latitude;
            _longitude = position.longitude;
            _isGettingLocation = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address != null
                        ? 'Đã lấy địa chỉ: ${address.shortText}'
                        : 'Đã lấy vị trí GPS thành công!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade400,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy vị trí: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_selectedImage != null) {
        debugPrint('[EditProfile] Uploading avatar...');
        try {
          final avatarUrl =
              await _providerRepository.uploadAvatar(_selectedImage!.path);
          debugPrint('[EditProfile] Avatar uploaded successfully: $avatarUrl');
        } catch (e) {
          debugPrint('[EditProfile] Avatar upload error: $e');
        }
      }

      await _providerRepository.updateProviderProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        serviceRadiusM: _selectedRadius,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        context.read<AuthBloc>().add(const ProfileFetchRequested());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cập nhật thành công!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildLocationCard(),
                    const SizedBox(height: 20),
                    _buildRadiusCard(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 120,
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.divider.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 20),
              const Text(
                'Sửa hồ sơ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.1), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        )
                      : (_existingImageUrl != null)
                          ? Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildAvatarPlaceholder(),
                            )
                          : _buildAvatarPlaceholder(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Thay đổi ảnh đại diện',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppColors.shelf,
      child: const Icon(Icons.person_rounded,
          size: 60, color: AppColors.textTertiary),
    );
  }

  Widget _buildInfoCard() {
    return MinCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Tên hiển thị'),
          MinTextField(
            controller: _displayNameController,
            hint: 'Nhập tên hiển thị của bạn',
            prefixIcon: const Icon(Icons.badge_outlined,
                size: 20, color: AppColors.primary),
            validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
          ),
          const SizedBox(height: 24),
          _buildLabel('Giới thiệu bản thân'),
          MinTextField(
            controller: _bioController,
            hint: 'Mô tả về kinh nghiệm, chuyên môn...',
            prefixIcon: const Icon(Icons.description_outlined,
                size: 20, color: AppColors.primary),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return MinCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Vị trí hoạt động'),
          MinTextField(
            controller: _addressController,
            hint: 'Nhập địa chỉ để tìm kiếm...',
            prefixIcon:
                const Icon(Icons.search, size: 20, color: AppColors.primary),
            onChanged: _onAddressChanged,
          ),

          // Address suggestions
          if (_showSuggestions && _addressSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _addressSuggestions.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final s = _addressSuggestions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.location_on,
                            color: Colors.green.shade600, size: 20),
                      ),
                      title: Text(s.mainText,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        s.secondaryText,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectAddress(s),
                    );
                  },
                ),
              ),
            ),

          // GPS Location Button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _isGettingLocation ? null : _getCurrentLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isGettingLocation
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green.shade700,
                          ),
                        )
                      : Icon(Icons.my_location,
                          size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _isGettingLocation
                        ? 'Đang lấy vị trí...'
                        : 'Lấy vị trí GPS hiện tại',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coordinates
          if (_latitude != null && _longitude != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadiusCard() {
    return MinCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Phạm vi nhận việc'),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(_selectedRadius / 1000).toStringAsFixed(_selectedRadius % 1000 == 0 ? 0 : 1)}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'km',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.1),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _selectedRadius.toDouble(),
              min: 1000,
              max: 40000,
              divisions: 39,
              onChanged: (v) => setState(() => _selectedRadius = v.round()),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _radiusOptions.map((r) {
              final isSelected = _selectedRadius == r;
              return GestureDetector(
                onTap: () => setState(() => _selectedRadius = r),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.divider.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '${r ~/ 1000}km',
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return MinButton(
      text: 'Lưu thay đổi',
      onPressed: _saveProfile,
      isLoading: _isSaving,
    );
  }
}
