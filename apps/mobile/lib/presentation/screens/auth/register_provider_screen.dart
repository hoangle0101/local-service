import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/provider_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/track_asia_repository.dart';
import '../../../data/storage/secure_storage.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/minimalist_widgets.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 0: Tài khoản
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Step 1: Xác thực OTP
  final _otpController = TextEditingController();

  // Step 2: Hồ sơ đối tác
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceYearsController = TextEditingController();

  // Location & Service
  double _latitude = 21.0285;
  double _longitude = 105.8542;
  double _serviceRadius = 10; // km
  bool _isCreatingProvider = false;
  bool _acceptsTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _addressController.dispose();
    _experienceYearsController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đang lấy vị trí hiện tại...'),
              behavior: SnackBarBehavior.floating),
        );

        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        // Reverse geocode to get address text
        final trackAsia = TrackAsiaRepository();
        final address = await trackAsia.reverseGeocode(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          if (address != null) {
            setState(() {
              _addressController.text = address.displayText;
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Đã lấy vị trí: ${address.shortText}'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating),
            );
          } else {
            // Fallback: show coordinates
            setState(() {
              _addressController.text =
                  'Vị trí: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Đã cập nhật vị trí GPS'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng cấp quyền vị trí'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi lấy vị trí: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        String phone = _phoneController.text.trim();
        if (!phone.startsWith('+')) {
          if (phone.startsWith('0')) {
            phone = '+84${phone.substring(1)}';
          } else if (phone.startsWith('84')) {
            phone = '+$phone';
          } else {
            phone = '+84$phone';
          }
        }
        if (_displayNameController.text.isEmpty) {
          _displayNameController.text = _fullNameController.text;
        }
        context.read<AuthBloc>().add(
              RegisterRequested(
                phone: phone,
                password: _passwordController.text,
                fullName: _fullNameController.text,
                role: 'provider', // Register as provider, not customer
              ),
            );
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        context.read<AuthBloc>().add(
              OtpVerifyRequested(
                phone: _phoneController.text,
                code: _otpController.text,
                purpose: 'verify_phone',
              ),
            );
      }
    }
  }

  Future<void> _createProviderProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptsTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chấp nhận Điều khoản dịch vụ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreatingProvider = true);

    try {
      final providerRepository = ProviderRepository();
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Always login with new credentials to get the correct token for this user
      // Don't use cached token - it may belong to a different user
      final authRepository = AuthRepository();
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+'))
        phone = '+84${phone.substring(phone.startsWith('0') ? 1 : 0)}';

      final tokens = await authRepository.login(
          phone: phone, password: _passwordController.text);
      await SecureStorage.saveAuthData(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          userPhone: phone);

      await providerRepository.createProviderProfile(
        displayName: _displayNameController.text,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        skills: skillsList,
        serviceRadiusM: (_serviceRadius * 1000).toInt(),
        latitude: _latitude,
        longitude: _longitude,
        address:
            _addressController.text.isNotEmpty ? _addressController.text : null,
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi khi tạo hồ sơ: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingProvider = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: AppColors.info, size: 64),
            ),
            const SizedBox(height: 24),
            Text('Đang chờ xét duyệt',
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            const Text(
              'Hồ sơ của bạn đã được gửi thành công. Vui lòng chờ quản trị viên xét duyệt trước khi có thể bắt đầu nhận việc.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            MinButton(
              text: 'Quay về Trang chủ',
              isFullWidth: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Clear auth state and go back to guest page
                context.read<AuthBloc>().add(LogoutRequested());
                context.go('/');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () =>
              _currentStep > 0 ? setState(() => _currentStep--) : context.pop(),
        ),
        title: Text(
          'Đăng ký Đối tác',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            setState(() => _currentStep = 1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating),
            );
          } else if (state is OtpVerified) {
            setState(() => _currentStep = 2);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Form(key: _formKey, child: _buildStepContent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          _buildStepNode(0, 'Tài khoản'),
          _buildStepLink(0),
          _buildStepNode(1, 'Xác thực'),
          _buildStepLink(1),
          _buildStepNode(2, 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primary
                : isActive
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.shelf,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted
                  ? AppColors.primary
                  : AppColors.divider.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded,
                    color: AppColors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color:
                          isActive ? AppColors.primary : AppColors.textTertiary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.5,
            fontWeight:
                isActive || isCompleted ? FontWeight.w900 : FontWeight.w600,
            color: isActive || isCompleted
                ? AppColors.primary
                : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLink(int step) {
    bool isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.primary
              : AppColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildDetailsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            const Text(
              'Thiết lập tài khoản',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Vui lòng điền đầy đủ thông tin để trở thành đối tác tin cậy của chúng tôi.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
        MinTextField(
          label: 'Họ và tên',
          hint: 'Vd: Nguyễn Văn A',
          controller: _fullNameController,
          prefixIcon: const Icon(Icons.person_3_rounded, size: 20),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Vui lòng nhập họ tên' : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Số điện thoại',
          hint: 'Vd: 0912345678',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
          validator: (v) => (v == null || v.length < 10)
              ? 'Số điện thoại không hợp lệ'
              : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Mật khẩu',
          hint: 'Tối thiểu 6 ký tự',
          obscureText: true,
          controller: _passwordController,
          prefixIcon: const Icon(Icons.lock_rounded, size: 20),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Mật khẩu quá ngắn' : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Xác nhận mật khẩu',
          hint: 'Nhập lại mật khẩu',
          obscureText: true,
          controller: _confirmPasswordController,
          prefixIcon: const Icon(Icons.shield_rounded, size: 20),
          validator: (v) =>
              (v != _passwordController.text) ? 'Mật khẩu không khớp' : null,
        ),
        const SizedBox(height: 48),
        MinButton(
          text: 'Tiếp tục bước xác thực',
          isFullWidth: true,
          onPressed: _handleNext,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            const Text(
              'Xác thực số điện thoại',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(
                  text: 'Chúng tôi đã gửi mã xác thực gồm 6 chữ số đến '),
              TextSpan(
                text: _phoneController.text,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        MinTextField(
          label: 'Mã xác thực (OTP)',
          hint: '123 456',
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
          prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
          validator: (v) => (v?.length != 6) ? 'Mã OTP phải có 6 chữ số' : null,
        ),
        const SizedBox(height: 48),
        MinButton(
            text: 'Xác nhận & Tiếp tục',
            isFullWidth: true,
            onPressed: _handleNext),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const Text('Chưa nhận được mã?',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.read<AuthBloc>().add(OtpSendRequested(
                    phone: _phoneController.text, purpose: 'verify_phone')),
                child: const Text('Gửi lại mã ngay',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business_center_rounded,
                  color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 16),
            const Text(
              'Hồ sơ của bạn',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Hãy tạo ấn tượng tốt với khách hàng bằng thông tin đầy đủ và chuyên nghiệp.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
        MinTextField(
          label: 'Tên hiển thị (Tên cửa hàng/cá nhân) *',
          hint: 'Vd: Điện lạnh Bách Khoa',
          controller: _displayNameController,
          prefixIcon: const Icon(Icons.store_rounded, size: 20),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Vui lòng nhập tên hiển thị' : null,
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Giới thiệu ngắn gọn',
          hint: 'Vd: Chuyên sửa chữa điều hòa, tủ lạnh tại nhà...',
          controller: _bioController,
          maxLines: 3,
          prefixIcon: const Icon(Icons.notes_rounded, size: 20),
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Kỹ năng / Dịch vụ *',
          hint: 'Vd: Sửa điện, Sửa nước, Vệ sinh...',
          controller: _skillsController,
          prefixIcon: const Icon(Icons.auto_awesome_rounded, size: 20),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Vui lòng nhập ít nhất một kỹ năng'
              : null,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.shelf.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 14, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Text('Mẹo: Dùng dấu phẩy (,) để ngăn cách các kỹ năng',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            const Text(
              'Phạm vi hoạt động',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        MinTextField(
          label: 'Địa chỉ hoạt động',
          hint: 'Nhập địa chỉ chính của bạn',
          controller: _addressController,
          prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: _getCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bán kính phục vụ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_serviceRadius.toInt()} km',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.shelf,
            thumbColor: AppColors.white,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10, elevation: 4),
          ),
          child: Slider(
            value: _serviceRadius,
            min: 1,
            max: 50,
            onChanged: (v) => setState(() => _serviceRadius = v),
          ),
        ),
        const SizedBox(height: 48),
        InkWell(
          onTap: () => setState(() => _acceptsTerms = !_acceptsTerms),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptsTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    onChanged: (v) =>
                        setState(() => _acceptsTerms = v ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tôi chấp nhận Điều khoản và Quy định của nền tảng dành cho đối tác.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        MinButton(
          text: 'Hoàn tất đăng ký ngay',
          isLoading: _isCreatingProvider,
          isFullWidth: true,
          onPressed: _createProviderProfile,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
