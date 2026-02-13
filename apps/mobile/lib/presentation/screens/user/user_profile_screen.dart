import 'package:flutter/material.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/minimalist_widgets.dart';
import '../../widgets/phone_verification_card.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  String? _defaultAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await _userRepository.getAddresses();
      if (addresses.isNotEmpty && mounted) {
        final defaultAddr = addresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => addresses.first,
        );
        setState(() {
          _defaultAddress = defaultAddr['addressText'] as String?;
        });
      }
    } catch (e) {
      debugPrint('[UserProfile] Error loading addresses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/');
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated && state.user != null) {
              return _buildContent(context, state.user!);
            }
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user) {
    final profile = user.profile;
    final avatarUrl = profile?.avatarUrl;

    String? fullAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      fullAvatarUrl = avatarUrl.startsWith('http')
          ? avatarUrl
          : 'http://10.0.2.2:3000${avatarUrl.startsWith('/') ? '' : '/'}$avatarUrl';
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<AuthBloc>().add(ProfileFetchRequested());
        await _loadDefaultAddress();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildProfileHeader(context, user, fullAvatarUrl),
                  const SizedBox(height: 32),
                  _buildVerificationBanner(user),
                  const SizedBox(height: 32),
                  _buildSectionLabel('DỊCH VỤ CỦA TÔI'),
                  const SizedBox(height: 16),
                  _buildServiceActionsCard(context),
                  const SizedBox(height: 32),
                  _buildSectionLabel('TÀI KHOẢN'),
                  const SizedBox(height: 16),
                  _buildAccountCard(context),
                  const SizedBox(height: 32),
                  _buildSectionLabel('TIỆN ÍCH'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(context),
                  const SizedBox(height: 48),
                  _buildLogoutButton(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (context.canPop())
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
            GestureDetector(
              onTap: () async {
                await context.push('/user/profile/edit');
                if (mounted) _loadDefaultAddress();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Sửa hồ sơ',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, dynamic user, String? avatarUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.1), width: 6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: UserAvatar(
                avatarUrl: avatarUrl,
                fullName: user.fullName,
                size: 90,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.shelf,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_iphone_rounded,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_defaultAddress != null) ...[
          const SizedBox(height: 32),
          MinCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐỊA CHỈ MẶC ĐỊNH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _defaultAddress!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(dynamic user) {
    if (user.isVerified) return const SizedBox.shrink();
    return PhoneVerificationCard(
      isVerified: false,
      verifiedAt: null,
    );
  }

  Widget _buildServiceActionsCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.calendar_today_rounded,
            title: 'Lịch sử đặt của tôi',
            onTap: () => context.push('/user/bookings'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.favorite_rounded,
            title: 'Danh sách yêu thích',
            onTap: () => context.push('/user/favorites'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.location_on_rounded,
            title: 'Địa chỉ đã lưu',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.payment_rounded,
            title: 'Phương thức thanh toán',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.security_rounded,
            title: 'Bảo mật tài khoản',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.notifications_rounded,
            title: 'Thông báo',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.language_rounded,
            title: 'Ngôn ngữ (Tiếng Việt)',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.help_center_rounded,
            title: 'Trung tâm trợ giúp',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.shelf.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.textTertiary, size: 14),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: AppColors.divider.withOpacity(0.3)),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return MinButton(
      text: 'Đăng xuất tài khoản',
      isPrimary: false,
      onPressed: () => _showLogoutDialog(context),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    MinDialog.show(
      context: context,
      title: 'Đăng xuất',
      message:
          'Bạn có chắc chắn muốn thoát khỏi phiên đăng nhập hiện tại không?',
      primaryLabel: 'Đăng xuất',
      isDestructive: true,
      icon: Icons.logout_rounded,
      secondaryLabel: 'Quay lại',
      onPrimaryPressed: () {
        context.read<AuthBloc>().add(LogoutRequested());
        context.go('/');
      },
    );
  }
}
