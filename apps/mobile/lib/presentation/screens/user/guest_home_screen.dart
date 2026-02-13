import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/presentation/bloc/categories/categories_bloc.dart';
import 'package:mobile/presentation/bloc/categories/categories_event_state.dart';
import 'package:mobile/presentation/bloc/services/services_bloc.dart';
import 'package:mobile/presentation/bloc/services/services_event_state.dart';
import 'package:mobile/presentation/bloc/auth/auth_bloc.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/presentation/widgets/service_card.dart';
import 'package:mobile/presentation/widgets/minimalist_widgets.dart';
import 'package:mobile/presentation/widgets/animations/fade_in_animation.dart';
import 'package:mobile/presentation/widgets/animations/slide_in_animation.dart';
import 'package:mobile/presentation/widgets/loading/shimmer_loading.dart';

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => CategoriesBloc()..add(LoadCategories())),
        BlocProvider(
            create: (context) =>
                ServicesBloc()..add(const LoadServices(limit: 10))),
        BlocProvider(
            create: (context) => AuthBloc()..add(AuthCheckRequested())),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildDiscoveryHeader(context),
                      const SizedBox(height: 40),
                      _buildSearchSection(context),
                      const SizedBox(height: 48),
                      _buildSectionHeader(context, 'Danh mục phổ biến',
                          () => context.push('/login')),
                      const SizedBox(height: 20),
                      _buildCategoriesGrid(context),
                      const SizedBox(height: 48),
                      _buildSectionHeader(context, 'Dịch vụ nổi bật',
                          () => context.push('/login')),
                      const SizedBox(height: 20),
                      _buildFeaturedServices(context),
                      const SizedBox(height: 48),
                      _buildProcessSection(context),
                      const SizedBox(height: 48),
                      _buildProviderCTA(context),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'ServiceHub',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
          MinButton(
            text: 'Đăng nhập',
            onPressed: () => context.push('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryHeader(BuildContext context) {
    return FadeInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khám phá',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  letterSpacing: -1.5,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tìm kiếm các dịch vụ tốt nhất xung quanh bạn ngay hôm nay.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return SlideInAnimation(
      delay: const Duration(milliseconds: 200),
      begin: const Offset(0, 0.2),
      child: MinTextField(
        hint: 'Bạn cần hỗ trợ điều gì?',
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textTertiary),
        suffixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onSeeAll) {
    return FadeInAnimation(
      delay: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Tất cả',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const ShimmerCategoryCard(),
          );
        } else if (state is CategoriesLoaded) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: state.categories.take(6).length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return SlideInAnimation(
                delay: Duration(milliseconds: 400 + (index * 50)),
                begin: const Offset(0, 0.2),
                child: GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.shelf,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: Icon(
                          _getCategoryIcon(index),
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFeaturedServices(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return Column(
            children: List.generate(
                3,
                (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ShimmerServiceCard(),
                    )),
          );
        } else if (state is ServicesLoaded) {
          return Column(
            children: state.services.take(4).map((service) {
              return SlideInAnimation(
                delay: const Duration(milliseconds: 600),
                begin: const Offset(0, 0.1),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ServiceCardWidget(service: service),
                ),
              );
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProcessSection(BuildContext context) {
    return MinCard(
      padding: const EdgeInsets.all(28),
      border: const BorderSide(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quy trình hoạt động',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 28),
          _buildProcessStep(
              context, '01', 'Tìm kiếm', 'Tìm dịch vụ bạn cần ngay tại nhà.'),
          _buildProcessDivider(),
          _buildProcessStep(context, '02', 'Chọn lựa',
              'Chọn đối tác uy tín dựa trên đánh giá.'),
          _buildProcessDivider(),
          _buildProcessStep(context, '03', 'Đặt lịch',
              'Lên lịch hẹn và trải nghiệm dịch vụ.'),
        ],
      ),
    );
  }

  Widget _buildProcessStep(
      BuildContext context, String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(num,
            style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -1)),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(desc, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 12, bottom: 12),
      child: Container(width: 1, height: 24, color: AppColors.divider),
    );
  }

  Widget _buildProviderCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Icon(Icons.business_center_rounded,
              color: Colors.white, size: 48),
          const SizedBox(height: 24),
          const Text(
            'Trở thành đối tác',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tham gia cùng chúng tôi để phát triển kinh doanh và tiếp cận hàng ngàn khách hàng tiềm năng.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.push('/role-selection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Tham gia ngay',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int index) {
    const icons = [
      Icons.plumbing,
      Icons.electrical_services,
      Icons.cleaning_services,
      Icons.carpenter,
      Icons.handyman,
      Icons.build
    ];
    return icons[index % icons.length];
  }
}
