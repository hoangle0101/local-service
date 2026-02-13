import 'package:go_router/go_router.dart';
import '../../../core/entities/entities.dart';
import '../screens/user/guest_home_screen.dart';
import '../screens/services/service_details_screen.dart';
import '../screens/booking/create_booking_screen.dart';
import '../screens/booking/complete_booking_screen.dart';
import '../screens/services/category_services_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/register_user_screen.dart';
import '../screens/auth/register_provider_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/user/user_home_screen.dart';
import '../screens/user/user_shell_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/user/user_bookings_screen.dart';
import '../screens/user/user_favorites_screen.dart';
import '../screens/user/user_edit_profile_screen.dart';
import '../screens/provider/provider_home_screen.dart';
import '../screens/provider/provider_profile_screen.dart';
import '../screens/provider/provider_bookings_screen.dart';
import '../screens/provider/provider_edit_profile_screen.dart';
import '../screens/provider/provider_my_reviews_screen.dart';
import '../screens/provider/provider_wallet_screen.dart';
import '../screens/provider/provider_withdraw_screen.dart';
import '../screens/provider/provider_complete_job_screen.dart';
import '../screens/booking/invoice_screen.dart';
import '../screens/provider/provider_shell_screen.dart';
import '../screens/provider/provider_earnings_screen.dart';
import '../screens/provider/provider_services_screen.dart';
import '../screens/provider/job_market_screen.dart';
import '../screens/provider/navigation_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/wallet/wallet_deposit_screen.dart';
import '../screens/booking/booking_detail_screen.dart';
import '../screens/booking/booking_dispute_screen.dart';
import '../bloc/bookings/bookings_event_state.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GuestHomeScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Authentication Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/register/user',
      builder: (context, state) => const RegisterUserScreen(),
    ),
    GoRoute(
      path: '/register/provider',
      builder: (context, state) => const RegisterProviderScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpVerificationScreen(
          phone: extra?['phone'] as String? ?? '',
          purpose: extra?['purpose'] as String? ?? 'verify_phone',
          devCode: extra?['code'] as String?,
        );
      },
    ),

    // User Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return UserShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/user/home',
              builder: (context, state) => const UserHomeScreen(),
              routes: [
                // Nested routes in home
                GoRoute(
                  path: 'category/:id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    final category = state.extra as Category?;
                    return CategoryServicesScreen(
                      categoryId: id,
                      category: category,
                    );
                  },
                ),
                GoRoute(
                  path: 'service/:id',
                  builder: (context, state) {
                    final id = int.parse(state.pathParameters['id']!);
                    final service = state.extra as ProviderService?;
                    return ServiceDetailsScreen(
                      serviceId: id,
                      service: service,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Bookings Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/user/bookings',
              builder: (context, state) => const UserBookingsScreen(),
            ),
          ],
        ),
        // Favorites Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/user/favorites',
              builder: (context, state) => const UserFavoritesScreen(),
            ),
          ],
        ),
        // Profile Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/user/profile',
              builder: (context, state) => const UserProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const UserEditProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Provider Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ProviderShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Home Branch (Map)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/provider/home',
              builder: (context, state) => const ProviderHomeScreen(),
            ),
          ],
        ),
        // Earnings Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/provider/earnings',
              builder: (context, state) => const ProviderEarningsScreen(),
            ),
          ],
        ),
        // Bookings/Activity Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/provider/bookings',
              builder: (context, state) => const ProviderBookingsScreen(),
            ),
          ],
        ),
        // Profile/Account Branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/provider/profile',
              builder: (context, state) => const ProviderProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) =>
                      const ProviderEditProfileScreen(),
                ),
                GoRoute(
                  path: 'reviews',
                  builder: (context, state) => const ProviderMyReviewsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/provider/wallet',
      builder: (context, state) => const ProviderWalletScreen(),
    ),
    GoRoute(
      path: '/provider/withdraw',
      builder: (context, state) => const ProviderWithdrawScreen(),
    ),
    GoRoute(
      path: '/wallet/deposit',
      builder: (context, state) => const WalletDepositScreen(),
    ),
    GoRoute(
      path: '/provider/services',
      builder: (context, state) => const ProviderServicesScreen(),
    ),
    GoRoute(
      path: '/provider/job-market',
      builder: (context, state) => const JobMarketScreen(),
    ),
    GoRoute(
      path: '/provider/navigation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return NavigationScreen(
          destinationLat: extra['lat'] as double,
          destinationLng: extra['lng'] as double,
          destinationAddress: extra['address'] as String?,
          customerName: extra['customerName'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/provider/complete-job/:id',
      builder: (context, state) {
        final bookingId = state.pathParameters['id']!;
        return ProviderCompleteJobScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/booking/invoice/:id',
      builder: (context, state) {
        final bookingId = state.pathParameters['id']!;
        return InvoiceScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/chat/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        final otherUserName = state.extra as String?;
        return ChatScreen(
          bookingId: bookingId,
          otherUserName: otherUserName,
        );
      },
    ),

    // Service Routes
    GoRoute(
      path: '/service/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final service = state.extra as ProviderService?;
        return ServiceDetailsScreen(
          serviceId: id,
          service: service,
        );
      },
    ),

    // Booking Routes
    GoRoute(
      path: '/booking/new',
      builder: (context, state) => const CompleteBookingScreen(),
    ),
    GoRoute(
      path: '/booking/create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CreateBookingScreen(
          serviceId: extra['serviceId'] as int,
          service: extra['service'] as ProviderService?,
          providerId: extra['providerId'] as int?, // For direct booking
          genericServiceName: extra['genericServiceName'] as String?,
        );
      },
    ),

    // Category Routes
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final category = state.extra as Category?;
        return CategoryServicesScreen(
          categoryId: id,
          category: category,
        );
      },
    ),
    GoRoute(
      path: '/booking/detail/:id',
      builder: (context, state) {
        final isProvider = state.uri.queryParameters['isProvider'] == 'true';
        final booking = state.extra as Booking;
        return BookingDetailScreen(booking: booking, isProvider: isProvider);
      },
    ),
    GoRoute(
      path: '/booking/dispute/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BookingDisputeScreen(bookingId: id);
      },
    ),
  ],
);
