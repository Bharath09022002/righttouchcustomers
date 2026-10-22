import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/otp_screen.dart';
import '../../presentation/screens/auth/complete_profile_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../../presentation/screens/home/search_screen.dart';
import '../../presentation/screens/home/category_screen.dart';
import '../../presentation/screens/home/service_detail_screen.dart';
import '../../presentation/screens/booking/bookings_screen.dart';
import '../../presentation/screens/booking/slot_booking_screen.dart';
import '../../presentation/screens/booking/checkout_screen.dart';
import '../../presentation/screens/booking/booking_success_screen.dart';
import '../../presentation/screens/booking/booking_detail_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/payments/payments_screen.dart';
import '../../presentation/screens/addresses/addresses_screen.dart';
import '../../presentation/screens/addresses/add_address_screen.dart';
import '../../presentation/screens/products/product_quotations_screen.dart';
import '../../presentation/screens/support/notifications_screen.dart';
import '../../presentation/screens/support/reports_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/account_settings_screen.dart';
import '../../presentation/screens/profile/support_legal_screen.dart';
import '../../presentation/screens/profile/warranty_info_screen.dart';
import '../../presentation/screens/profile/delete_account_screen.dart';
import '../../presentation/screens/profile/my_ratings_screen.dart';
import '../../presentation/screens/profile/rewards_screen.dart';
import '../../presentation/screens/products/products_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/services/services_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen<bool>(
      authProvider.select((s) => s.loggedIn || s.isGuest),
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final canBrowse = auth.loggedIn || auth.isGuest;
    final loc = state.matchedLocation;
    // Public auth flow — phone OTP only, no password screens.
    if (loc == '/splash' ||
        loc == '/onboarding' ||
        loc == '/login' ||
        loc == '/signup' ||
        loc == '/otp') {
      return null;
    }
    if (!canBrowse) return '/login';
    return null;
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/complete-profile', builder: (_, __) => const CompleteProfileScreen()),
      ShellRoute(
        builder: (_, state, child) => MainShell(
          location: state.matchedLocation.isNotEmpty ? state.matchedLocation : state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeTabPlaceholder()),
          ),
          GoRoute(
            path: '/services',
            pageBuilder: (_, s) => NoTransitionPage(
              child: ServicesScreen(initialCategory: s.uri.queryParameters['category']),
            ),
          ),
          GoRoute(
            path: '/product',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProductTabPlaceholder()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (_, s) => NoTransitionPage(
              child: ProductsScreen(initialCategory: s.uri.queryParameters['category']),
            ),
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (_, __) => const NoTransitionPage(child: BookingsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileTabPlaceholder()),
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfileTabPlaceholder()),
          ),
        ],
      ),
      GoRoute(path: '/cart-tab', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/category/:id', builder: (_, s) => CategoryScreen(id: s.pathParameters['id']!, name: s.uri.queryParameters['name'] ?? 'Category')),
      GoRoute(path: '/service/:id', builder: (_, s) => ServiceDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/product/:id', builder: (_, s) => ProductDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/book/:id', builder: (_, s) => SlotBookingScreen(serviceId: s.pathParameters['id']!)),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/booking-success', builder: (_, __) => const BookingSuccessScreen()),
      GoRoute(path: '/booking/:id', builder: (_, s) => BookingDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: '/addresses', builder: (_, __) => const AddressesScreen()),
      GoRoute(path: '/add-address', builder: (_, __) => const AddAddressScreen()),
      GoRoute(
        path: '/quotations',
        builder: (_, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
              (state.extra is int ? state.extra as int : 0);
          final productId = state.uri.queryParameters['productId'] ??
              (state.extra is Map ? (state.extra as Map)['productId'] as String? : null);
          return ProductQuotationsScreen(initialTab: tab, preselectedProductId: productId);
        },
      ),
      GoRoute(
        path: '/product-quotes',
        builder: (_, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
              (state.extra is int ? state.extra as int : 0);
          final productId = state.uri.queryParameters['productId'] ??
              (state.extra is Map ? (state.extra as Map)['productId'] as String? : null);
          return ProductQuotationsScreen(initialTab: tab, preselectedProductId: productId);
        },
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/account-settings', builder: (_, __) => const AccountSettingsScreen()),
      GoRoute(path: '/support-legal', builder: (_, __) => const SupportLegalScreen()),
      GoRoute(path: '/warranty-info', builder: (_, __) => const WarrantyInfoScreen()),
      GoRoute(path: '/delete-account', builder: (_, __) => const DeleteAccountScreen()),
      GoRoute(path: '/ratings', builder: (_, __) => const MyRatingsScreen()),
      GoRoute(path: '/rewards', builder: (_, __) => const RewardsScreen()),
    ],
  );
});
