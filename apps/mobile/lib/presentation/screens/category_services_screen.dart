import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/entities/entities.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/services/services_bloc.dart';
import '../bloc/services/services_event_state.dart';
import '../widgets/service_card.dart';
import '../widgets/loading/shimmer_loading.dart';

class CategoryServicesScreen extends StatefulWidget {
  final int categoryId;
  final Category? category;

  const CategoryServicesScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  late ServicesBloc _servicesBloc;
  List<ProviderService> _providerServices = [];
  List<Service> _genericServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _servicesBloc = ServicesBloc();
    _servicesBloc
        .add(LoadServicesByCategory(categoryId: widget.categoryId, limit: 20));
    _servicesBloc.add(LoadGenericServices(categoryId: widget.categoryId));
  }

  @override
  void dispose() {
    _servicesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _servicesBloc,
      child: BlocConsumer<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is ServicesLoading) {
            setState(() => _isLoading = true);
          } else if (state is ServicesLoaded) {
            setState(() {
              _providerServices = state.services;
              _isLoading = false;
            });
          } else if (state is GenericServicesLoaded) {
            setState(() {
              _genericServices = state.services;
              _isLoading = false;
            });
          } else if (state is ServicesError) {
            setState(() => _isLoading = false);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                _servicesBloc.add(LoadServicesByCategory(
                    categoryId: widget.categoryId, limit: 20));
                _servicesBloc
                    .add(LoadGenericServices(categoryId: widget.categoryId));
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildModernAppBar(context),
                  _buildContent(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DANH MỤC',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              widget.category?.name ?? 'Dịch vụ',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            if (widget.category?.description != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.category!.description!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _providerServices.isEmpty && _genericServices.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            List.generate(
                3,
                (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: ShimmerServiceCard())),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGenericServicesSection(context),
            const SizedBox(height: 32),
            _buildProviderServicesSection(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericServicesSection(BuildContext context) {
    if (_genericServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'YÊU CẦU NHANH',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.5,
                color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đăng yêu cầu công khai để các thợ tìm đến bạn và báo giá tốt nhất.',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _genericServices.length,
            itemBuilder: (context, index) {
              final svc = _genericServices[index];
              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.divider.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => context.push(
                    '/booking/create',
                    extra: {
                      'serviceId': svc.id,
                      'service': null,
                      'providerId': null,
                      'genericServiceName': svc.name,
                    },
                  ),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          svc.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Text(
                              'ĐĂNG TIN',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 12, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderServicesSection(BuildContext context) {
    if (_providerServices.isEmpty) {
      if (!_isLoading) return _buildEmptyState();
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.shelf,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'THỢ ĐANG ONLINE (${_providerServices.length})',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.5,
                color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(height: 24),
        ..._providerServices.map((svc) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ServiceCardWidget(service: svc),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppColors.shelf,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Chưa có thợ nào online',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hiện tại chưa có thợ nào cung cấp dịch vụ trực tiếp. Bạn hãy thử đăng yêu cầu công khai ở trên nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
