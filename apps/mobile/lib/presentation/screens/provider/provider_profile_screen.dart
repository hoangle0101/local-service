import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/minimalist_widgets.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

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
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic user) {
    final profile = user.profile;
    final providerProfile = user.providerProfile;
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
                  _buildStatsSection(context, providerProfile),
                  const SizedBox(height: 32),
                  _buildSectionLabel('CÔNG VIỆC'),
                  const SizedBox(height: 16),
                  _buildWorkCard(context),
                  const SizedBox(height: 32),
                  _buildSectionLabel('CÀI ĐẶT'),
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
              )
            else
              GestureDetector(
                onTap: () => context.push('/provider/profile/edit'),
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
                  child: const Row(
                    children: [
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
    final providerProfile = user.providerProfile;
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
                    providerProfile?.displayName ?? user.fullName,
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
                  Row(
                    children: [
                      MinBadge(
                        label: 'ĐỐI TÁC',
                        color: AppColors.primary.withOpacity(0.1),
                        textColor: AppColors.primary,
                      ),
                      if (providerProfile?.serviceRadiusM != null) ...[
                        const SizedBox(width: 8),
                        MinBadge(
                          label:
                              '${(providerProfile!.serviceRadiusM! / 1000).toStringAsFixed(0)} KM',
                          color: AppColors.accent.withOpacity(0.1),
                          textColor: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, dynamic providerProfile) {
    final rating = providerProfile?.ratingAvg?.toStringAsFixed(1) ?? '0.0';
    final reviews = providerProfile?.ratingCount?.toString() ?? '0';

    return MinCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('0', 'XONG', AppColors.success),
          _buildStatDivider(),
          _buildStatItem(rating, 'ĐÁNH GIÁ', AppColors.warning),
          _buildStatDivider(),
          _buildStatItem(reviews, 'PHẢN HỒI', AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
        width: 1, height: 32, color: AppColors.divider.withOpacity(0.5));
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

  Widget _buildWorkCard(BuildContext context) {
    return MinCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuRow(
            icon: Icons.build_circle_outlined,
            title: 'Dịch vụ của tôi',
            onTap: () => context.push('/provider/services'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.calendar_today_rounded,
            title: 'Lịch công việc',
            onTap: () => context.push('/provider/bookings'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Ví của tôi',
            onTap: () => context.push('/provider/wallet'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.sync_rounded,
            title: 'Chuyển sang Chế độ khách',
            onTap: () => context.go('/user/home'),
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
            icon: Icons.notifications_none_rounded,
            title: 'Thông báo',
            onTap: () {},
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.star_outline_rounded,
            title: 'Đánh giá từ khách',
            onTap: () => context.push('/provider/profile/reviews'),
          ),
          _buildMenuDivider(),
          _buildMenuRow(
            icon: Icons.help_outline_rounded,
            title: 'Trợ giúp & Hỗ trợ',
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
