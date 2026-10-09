import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_result.dart';
import '../../core/storage/token_storage.dart';
import '../../data/datasources/remote_gateway.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

// ---------- infra ----------
final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStorageProvider)));
final gatewayProvider = Provider<RemoteGateway>((ref) => RemoteGateway(ref.watch(apiClientProvider)));
final authRepoProvider = Provider((ref) => AuthRepository(ref.watch(gatewayProvider)));
final catalogRepoProvider = Provider((ref) => CatalogRepository(ref.watch(gatewayProvider)));
final bookingRepoProvider = Provider((ref) => BookingRepository(ref.watch(gatewayProvider)));
final cartRepoProvider = Provider((ref) => CartRepository(ref.watch(gatewayProvider)));
final addressRepoProvider = Provider((ref) => AddressRepository(ref.watch(gatewayProvider)));
final paymentRepoProvider = Provider((ref) => PaymentRepository(ref.watch(gatewayProvider)));
final supportRepoProvider = Provider((ref) => SupportRepository(ref.watch(gatewayProvider)));

// ---------- auth state ----------
enum AuthMode { login, signup }

class AuthState {
  final bool loading;
  final bool loggedIn;
  final UserModel? user;
  final String? mobile;
  final AuthMode mode;
  final String? otpHint;
  AuthState({this.loading = false, this.loggedIn = false, this.user, this.mobile, this.mode = AuthMode.login, this.otpHint});
  AuthState copyWith({bool? loading, bool? loggedIn, UserModel? user, String? mobile, AuthMode? mode, String? otpHint}) =>
      AuthState(
        loading: loading ?? this.loading,
        loggedIn: loggedIn ?? this.loggedIn,
        user: user ?? this.user,
        mobile: mobile ?? this.mobile,
        mode: mode ?? this.mode,
        otpHint: otpHint ?? this.otpHint,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  bool _bootstrapping = false;
  AuthNotifier(this.ref) : super(AuthState());

  void setMode(AuthMode m) => state = state.copyWith(mode: m);
  void setMobile(String m) => state = state.copyWith(mobile: m);

  Future<void> bootstrap() async {
    if (_bootstrapping || state.user != null) return;
    _bootstrapping = true;
    try {
      final t = ref.read(tokenStorageProvider);
      await t.loadCache();
      if (t.cachedToken?.isNotEmpty == true) {
        state = state.copyWith(loggedIn: true, loading: true);
        try {
          final r = await ref.read(authRepoProvider).me();
          if (r is ApiOk) {
            final d = r.data;
            final m = asMap(d);
            state = state.copyWith(
                user: UserModel.fromJson(m.containsKey('user') ? m['user'] : d),
                loading: false);
          } else {
            // Access token dead → try silent refresh before forcing login.
            final refreshed = await refreshSession();
            if (!refreshed) {
              await t.clear();
              state = state.copyWith(loading: false, loggedIn: false, user: null);
            } else {
              await bootstrap();
            }
          }
        } catch (_) {
          await t.clear();
          state = state.copyWith(loading: false, loggedIn: false, user: null);
        }
      }
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _persistSession(AuthSession s) async {
    final store = ref.read(tokenStorageProvider);
    if (s.token != null && s.token!.isNotEmpty) {
      await store.saveToken(s.token!);
      store.cachedToken = s.token;
    }
    if (s.refreshToken != null && s.refreshToken!.isNotEmpty) {
      await store.saveRefreshToken(s.refreshToken!);
    }
  }

  /// Stage 0 step 1/3 — mode-aware. Signup sends terms flags;
  /// 409 MOBILE_ALREADY_EXISTS bubbles up so UI can flip to Login.
  /// On success stores a human-readable OTP hint from the backend
  /// payload (purpose + expiry) for the OTP screen.
  Future<String?> requestOtp(String mobile, {AuthMode? mode}) async {
    final m = (mode ?? state.mode);
    state = state.copyWith(loading: true, mobile: mobile, mode: m);
    await ref.read(tokenStorageProvider).saveMobile(mobile);
    try {
      final dynamic raw = m == AuthMode.signup
          ? await ref.read(authRepoProvider).requestSignupOtp(mobile)
          : await ref.read(authRepoProvider).requestLoginOtp(mobile);
      state = state.copyWith(loading: false, otpHint: _hint(raw));
      return null;
    } catch (e) {
      state = state.copyWith(loading: false);
      return e.toString();
    }
  }

  static String? _hint(dynamic raw) {
    final m = asMap(raw);
    if (m.isEmpty) return null;
    final purpose = (m['purpose'] ?? '').toString();
    final exp = m['expiresInSeconds'];
    final mins = exp is num ? (exp ~/ 60) : 5;
    if (purpose.isEmpty) return 'Code valid for $mins min';
    final p = purpose.toLowerCase();
    final what = p.contains('signup') ? 'Signup' : 'Login';
    return '$what OTP sent • valid $mins min';
  }

  /// Dev-helper: is this number registered? Returns true/false, or null
  /// when the debug endpoint is unavailable (prod backends).
  Future<({bool? exists, String message})> checkNumber(
      String identifier) async {
    try {
      final r = await ref.read(authRepoProvider).checkUser(identifier);
      if (r.exists == null) {
        return (exists: null, message: 'Status check unavailable on server');
      }
      return (
        exists: r.exists,
        message: r.exists == true
            ? 'Number is registered — use Login'
            : 'Number is new — use Sign up'
      );
    } catch (e) {
      return (exists: null, message: e.toString());
    }
  }

  /// Stage 0 step 2/4 — verifies OTP, persists token + refresh_token.
  Future<String?> verifyOtp(String otp) async {
    final mobile =
        state.mobile ?? await ref.read(tokenStorageProvider).getMobile() ?? '';
    state = state.copyWith(loading: true);
    try {
      final AuthSession s = state.mode == AuthMode.signup
          ? await ref.read(authRepoProvider).verifySignupOtp(mobile, otp)
          : await ref.read(authRepoProvider).verifyLoginOtp(mobile, otp);
      await _persistSession(s);
      state = state.copyWith(loading: false, loggedIn: true, user: s.user);
      return null;
    } catch (e) {
      state = state.copyWith(loading: false);
      return e.toString();
    }
  }

  Future<String?> resendOtp() async {
    final mobile =
        state.mobile ?? await ref.read(tokenStorageProvider).getMobile() ?? '';
    if (mobile.isEmpty) return 'Enter your mobile number first.';
    try {
      final purpose = state.mode == AuthMode.signup ? 'SIGNUP' : 'LOGIN';
      await ref.read(authRepoProvider).resend(mobile, purpose: purpose);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Stage 0b — rotate refresh token. Returns false when re-login is needed.
  Future<bool> refreshSession() async {
    final rt = await ref.read(tokenStorageProvider).getRefreshToken();
    if (rt == null || rt.isEmpty) return false;
    try {
      final s = await ref.read(authRepoProvider).refresh(rt);
      await _persistSession(s);
      ref.read(tokenStorageProvider).cachedToken = s.token;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout({bool allDevices = false}) async {
    try {
      if (allDevices) {
        await ref.read(gatewayProvider).logoutAll();
      } else {
        await ref.read(gatewayProvider).logout();
      }
    } catch (_) {
      // Server logout is best-effort; local wipe is authoritative.
    }
    await ref.read(tokenStorageProvider).clear();
    state = AuthState();
  }

  void setUser(UserModel u) => state = state.copyWith(user: u);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

final productRepoProvider = Provider((ref) => ProductRepository(ref.watch(gatewayProvider)));

// ---------- catalog ----------
final categoryListProvider =
    FutureProvider((ref) => ref.watch(catalogRepoProvider).categories());

final serviceCategoriesProvider = FutureProvider((ref) async {
  final cats = await ref.watch(categoryListProvider.future);
  final filtered = cats.where((c) => !c.isProductCategory).toList();
  return filtered.isNotEmpty ? filtered : cats;
});

final productCategoriesProvider = FutureProvider((ref) async {
  final cats = await ref.watch(categoryListProvider.future);
  final filtered = cats.where((c) => c.isProductCategory).toList();
  return filtered;
});

class ServiceQuery {
  final String search;
  final String? categoryId;
  const ServiceQuery([this.search = '', this.categoryId]);
  @override
  bool operator ==(Object other) =>
      other is ServiceQuery && other.search == search && other.categoryId == categoryId;
  @override
  int get hashCode => Object.hash(search, categoryId);
}

final serviceQueryProvider =
    StateProvider<ServiceQuery>((_) => const ServiceQuery());
final serviceListProvider = FutureProvider((ref) async {
  final q = ref.watch(serviceQueryProvider);
  final res = await ref
      .watch(catalogRepoProvider)
      .services(search: q.search, categoryId: q.categoryId);
  return res.$1;
});
final serviceDetailProvider = FutureProvider.family(
    (ref, String id) => ref.watch(catalogRepoProvider).service(id));

class ProductQuery {
  final String search;
  final String? categoryId;
  const ProductQuery([this.search = '', this.categoryId]);
  @override
  bool operator ==(Object other) =>
      other is ProductQuery && other.search == search && other.categoryId == categoryId;
  @override
  int get hashCode => Object.hash(search, categoryId);
}

final productQueryProvider =
    StateProvider<ProductQuery>((_) => const ProductQuery());
final productListProvider = FutureProvider((ref) async {
  final q = ref.watch(productQueryProvider);
  return ref
      .watch(productRepoProvider)
      .products(search: q.search, categoryId: q.categoryId);
});

// ---------- bookings / cart / addresses / misc ----------
final myBookingsProvider =
    FutureProvider((ref) => ref.watch(bookingRepoProvider).myBookings());
final bookingDetailProvider = FutureProvider.family(
    (ref, String id) => ref.watch(bookingRepoProvider).detail(id));
final cartProvider =
    FutureProvider((ref) => ref.watch(cartRepoProvider).myCart());
final addressListProvider =
    FutureProvider((ref) => ref.watch(addressRepoProvider).list());
final selectedAddressProvider = StateProvider<AddressModel?>((_) => null);
final paymentListProvider =
    FutureProvider((ref) => ref.watch(paymentRepoProvider).list());
final paymentSummaryProvider =
    FutureProvider((ref) => ref.watch(paymentRepoProvider).summary());
final quotationListProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).quotations());
final quoteRequestListProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).quoteRequests());
final productBookingsProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).productBookings());
final notificationListProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).notifications());
final unreadNotificationCountProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).unreadCount());
final myReportsProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).myReports());
final reportCategoriesProvider =
    FutureProvider((ref) => ref.watch(supportRepoProvider).reportCategories());
final cancelReasonsProvider =
    FutureProvider((ref) => ref.watch(bookingRepoProvider).reasons());

