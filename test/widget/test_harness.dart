import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:righttouch/core/theme/app_theme.dart';
import 'package:righttouch/data/models/models.dart';
import 'package:righttouch/presentation/providers/providers.dart';

/// Standard screen resolutions for Phase 4 audit
const kScreenResolutions = <String, Size>{
  'small_phone_320x480': Size(320, 480),
  'standard_390x844': Size(390, 844),
  'large_android_412x915': Size(412, 915),
  'tablet_820x1180': Size(820, 1180),
};

/// Font scale factors for Phase 4 audit
const kFontScales = <double>[0.8, 1.0, 1.5, 2.0];

/// Mock / Fake Data Factories
UserModel createFakeUser({
  String id = 'user_123',
  String fname = 'Test',
  String lname = 'Customer',
  String mobile = '9876543210',
  String email = 'customer@example.com',
}) {
  return UserModel(
    id: id,
    fname: fname,
    lname: lname,
    mobile: mobile,
    email: email,
    profileCompleted: true,
  );
}

AddressModel createFakeAddress({
  String id = 'addr_1',
  String type = 'Home',
  String line = '42 Anna Salai, Chennai',
  String city = 'Chennai',
  String state = 'Tamil Nadu',
  String pincode = '600002',
  bool isDefault = true,
}) {
  return AddressModel(
    id: id,
    type: type,
    line: line,
    city: city,
    state: state,
    pincode: pincode,
    isDefault: isDefault,
    lat: 13.0827,
    lng: 80.2707,
  );
}

CategoryModel createFakeCategory({
  String id = 'cat_1',
  String name = 'Solar Solutions',
  String? description = 'Expert cleaning and maintenance',
}) {
  return CategoryModel(
    id: id,
    name: name,
    description: description,
  );
}

ServiceModel createFakeService({
  String id = 'svc_1',
  String name = 'Solar Panel Deep Cleaning',
  num price = 1199,
  num mrp = 1499,
  double rating = 4.8,
  int ratingCount = 124,
}) {
  return ServiceModel(
    id: id,
    name: name,
    price: price,
    mrp: mrp,
    rating: rating,
    ratingCount: ratingCount,
    description: 'Complete high pressure cleaning and inspection.',
    serviceHighlights: const ['High pressure water wash', 'Inverter check', 'Efficiency test'],
  );
}

CartItemModel createFakeCartItem({
  String id = 'cart_item_1',
  String itemId = 'svc_1',
  String itemType = 'service',
  String name = 'Solar Panel Deep Cleaning',
  num price = 1199,
  num originalPrice = 1499,
  int qty = 1,
}) {
  return CartItemModel(
    id: id,
    itemId: itemId,
    itemType: itemType,
    name: name,
    price: price,
    originalPrice: originalPrice,
    qty: qty,
  );
}

BookingModel createFakeBooking({
  String id = 'bk_101',
  String status = 'pending',
  String serviceName = 'Solar Panel Deep Cleaning',
  num amount = 1199,
}) {
  return BookingModel(
    id: id,
    status: status,
    serviceName: serviceName,
    amount: amount,
    addressLine: '42 Anna Salai, Chennai',
    technicianName: 'Suresh Kumar',
  );
}

/// Baseline standard provider overrides
List<Override> createDefaultOverrides({
  UserModel? user,
  AddressModel? selectedAddress,
  List<CategoryModel>? categories,
  List<ServiceModel>? services,
  List<CartItemModel>? cartItems,
  List<BookingModel>? bookings,
  int unreadNotifications = 0,
}) {
  final addr = selectedAddress ?? createFakeAddress();
  final catList = categories ?? [createFakeCategory()];
  final svcList = services ?? [createFakeService()];
  final cartList = cartItems ?? [createFakeCartItem()];
  final bookingList = bookings ?? [createFakeBooking()];

  return [
    selectedAddressProvider.overrideWith((ref) => addr),
    unreadNotificationCountProvider.overrideWith((ref) async => unreadNotifications),
    cartProvider.overrideWith((ref) async => cartList),
    categoryListProvider.overrideWith((ref) async => catList),
    serviceListProvider.overrideWith((ref) async => svcList),
    addressListProvider.overrideWith((ref) async => [addr]),
    myBookingsProvider.overrideWith((ref) async => bookingList),
    bookingDetailProvider.overrideWith((ref, id) async {
      return bookingList.firstWhere((b) => b.id == id, orElse: () => createFakeBooking(id: id));
    }),
    serviceDetailProvider.overrideWith((ref, id) async {
      return svcList.firstWhere((s) => s.id == id, orElse: () => createFakeService(id: id));
    }),
    authProvider.overrideWith((ref) {
      final notifier = AuthNotifier(ref);
      if (user != null) {
        notifier.state = AuthState(
          loggedIn: true,
          user: user,
        );
      }
      return notifier;
    }),
  ];
}

/// Harness helper to build standard GoRouter MaterialApp
Widget createTestApp({
  required Widget screen,
  String route = '/',
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
}) {
  final router = GoRouter(
    initialLocation: route,
    routes: [
      GoRoute(
        path: route,
        builder: (context, state) => screen,
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const Scaffold(body: Text('Addresses Screen')),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const Scaffold(body: Text('Cart Screen')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const Scaffold(body: Text('Notifications Screen')),
      ),
      GoRoute(
        path: '/service/:id',
        builder: (context, state) => Scaffold(body: Text('Service ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (context, state) => Scaffold(body: Text('Booking ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const Scaffold(body: Text('Checkout Screen')),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(body: Text('Profile Screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides.isEmpty ? createDefaultOverrides() : overrides,
    child: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
