import 'package:flutter/foundation.dart';
import '../../core/network/api_result.dart';
import '../datasources/remote_gateway.dart';
import '../models/models.dart';

List<T> _parseList<T>(dynamic raw, T Function(dynamic) f) {
  if (raw is List) return raw.map(f).toList();
  if (raw is Map) {
    for (final k in [
      'items', 'services', 'categories', 'products', 'bookings', 'customerBookings',
      'carts', 'addresses', 'payments', 'quotations', 'quoteRequests', 'productBookings',
      'notifications', 'reports', 'slots', 'ratings', 'result', 'list', 'data', 'records'
    ]) {
      final v = raw[k];
      if (v is List) return v.map(f).toList();
    }
  }
  return [];
}

String? _extractToken(dynamic raw) {
  if (raw is Map) {
    for (final k in ['token', 'accessToken', 'jwt', 'authToken']) {
      final v = raw[k];
      if (v is String && v.isNotEmpty) return v;
    }
    for (final k in ['data', 'result', 'user']) {
      final inner = raw[k];
      final t = _extractToken(inner);
      if (t != null) return t;
    }
    final user = raw['user'];
    if (user is Map) {
      final t = _extractToken(user);
      if (t != null) return t;
    }
  }
  if (raw is String && raw.length > 20) return raw;
  return null;
}

class AuthSession {
  final String? token;
  final String? refreshToken;
  final UserModel? user;
  const AuthSession({this.token, this.refreshToken, this.user});
}

AuthSession toSession(dynamic raw) {
  final m = asMap(raw);
  // Live shape: result = { token, refresh_token, expires_in, user }
  final inner = m.containsKey('user') && m.containsKey('token') ? m : asMap(m['user'] != null && m['token'] == null ? m['user'] : raw);
  String? token;
  String? refresh;
  for (final k in ['token', 'accessToken', 'jwt', 'authToken']) {
    final v = inner[k];
    if (v is String && v.isNotEmpty) {
      token = v;
      break;
    }
  }
  for (final k in ['refresh_token', 'refreshToken']) {
    final v = inner[k];
    if (v is String && v.isNotEmpty) {
      refresh = v;
      break;
    }
  }
  UserModel? user;
  try {
    final u = inner.containsKey('user') ? inner['user'] : raw;
    final parsed = UserModel.fromJson(u);
    if (parsed.id.isNotEmpty || (parsed.fullName.trim().isNotEmpty)) user = parsed;
  } catch (_) {}
  return AuthSession(token: token ?? _extractToken(raw), refreshToken: refresh, user: user);
}

class AuthRepository {
  final RemoteGateway gw;
  AuthRepository(this.gw);

  Future<ApiResult<String?>> requestOtp(String m) async {
    final r = await gw.requestOtp(m);
    if (r is ApiOk) return ApiOk<String?>(_extractToken(r.data));
    if (r is ApiErr) return ApiErr(r.message, r.statusCode, r.code);
    return const ApiErr('Unexpected response');
  }

  /// Returns the raw result payload (purpose/expiresInSeconds) on success.
  Future<dynamic> requestSignupOtp(String mobile) async {
    final r = await gw.signupCustomer(mobile);
    if (r is ApiOk) return r.data;
    if (r is ApiErr) throw ApiException(friendly(r.message, r.code));
    throw ApiException('Unexpected response');
  }

  Future<AuthSession> verifySignupOtp(String mobile, String otp) async {
    final r = await gw.verifySignupCustomer(mobile, otp);
    if (r is ApiOk) return toSession(r.data);
    if (r is ApiErr) throw ApiException(friendly(r.message, r.code));
    throw ApiException('Unexpected response');
  }

  /// Returns the raw result payload (purpose/expiresInSeconds) on success.
  Future<dynamic> requestLoginOtp(String mobile) async {
    final r = await gw.loginCustomer(mobile);
    if (r is ApiOk) return r.data;
    if (r is ApiErr) throw ApiException(friendly(r.message, r.code));
    throw ApiException('Unexpected response');
  }

  Future<AuthSession> verifyLoginOtp(String mobile, String otp) async {
    final r = await gw.verifyLoginCustomer(mobile, otp);
    if (r is ApiOk) return toSession(r.data);
    if (r is ApiErr) throw ApiException(friendly(r.message, r.code));
    throw ApiException('Unexpected response');
  }

  Future<({String? token, UserModel? user})> verifyOtp(String mobile, String otp) async {
    // Back-compat: try login-verify first, fall back to generic alias.
    try {
      final s = await verifyLoginOtp(mobile, otp);
      return (token: s.token, user: s.user);
    } catch (_) {
      final r = await gw.verifyOtp(mobile, otp);
      if (r is ApiOk) {
        final s = toSession(r.data);
        return (token: s.token, user: s.user);
      }
      if (r is ApiErr) throw ApiException(r.message);
      throw ApiException('Unexpected response');
    }
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final r = await gw.refresh(refreshToken);
    if (r is ApiOk) return toSession(r.data);
    if (r is ApiErr) throw ApiException(friendly(r.message, r.code));
    throw ApiException('Unexpected response');
  }

  Future<void> resend(String mobile, {String? purpose}) async {
    final r = await gw.resendOtp(mobile, purpose: purpose);
    if (r is ApiErr) throw ApiException(friendly(r.message, r.code));
  }

  /// Returns (exists, raw) for the debug check-user endpoint.
  /// exists=null when the endpoint is unavailable (prod).
  Future<({bool? exists, dynamic raw})> checkUser(String identifier) async {
    final r = await gw.debugCheckUser(identifier);
    if (r is ApiOk) {
      final d = r.data;
      final m = asMap(d);
      bool? exists;
      for (final k in ['exists', 'registered', 'found', 'isRegistered']) {
        if (m[k] is bool) exists = m[k] as bool;
      }
      // A returned user object implies existence.
      if (exists == null && (m.containsKey('user') || m.containsKey('_id'))) {
        exists = true;
      }
      return (exists: exists, raw: d);
    }
    final e = r as ApiErr;
    if (e.statusCode == 404) return (exists: false, raw: null);
    throw ApiException(friendly(e.message, e.code));
  }

  /// Friendly mapping for customer-visible error codes.
  static String friendly(String msg, String? code) {
    switch (code) {
      case 'OTP_INVALID':
        return 'Wrong OTP. 5 attempts allowed — check and retry.';
      case 'OTP_INVALID_OR_EXPIRED':
        return 'OTP expired or already used. Request a new one.';
      case 'OTP_COOLDOWN':
        return 'OTP was just sent. Wait 60 seconds before resending.';
      case 'MOBILE_ALREADY_EXISTS':
        return 'This number is already registered. Please log in instead.';
      case 'USER_NOT_FOUND':
        return 'Number not registered — please sign up first.';
      case 'ROLE_MISMATCH':
        return 'This number is registered in another role.';
      case 'ROLE_NOT_ALLOWED_FOR_SIGNUP':
        return 'This role cannot sign up here.';
      case 'TERMS_OR_PRIVACY_NOT_ACCEPTED':
        return 'Please accept Terms and Privacy Policy.';
      case 'ACCOUNT_BLOCKED':
      case 'ACCOUNT_DELETED':
      case 'ACCOUNT_INACTIVE':
        return 'This account is blocked. Contact support.';
      case 'REFRESH_INVALID':
        return 'Session expired. Please log in again.';
      case 'SESSION_REVOKED':
      case 'SESSION_ROLE_MISMATCH':
        return 'You were logged out from another device. Please log in again.';
      default:
        return msg;
    }
  }

  Future<ApiResult<dynamic>> me() => gw.me();
  Future<ApiResult<dynamic>> completeProfile(Map<String, dynamic> b) => gw.completeProfile(b);
  Future<ApiResult<dynamic>> updateProfile(Map<String, dynamic> b) => gw.updateProfile(b);
  Future<ApiResult<dynamic>> deleteAccount() => gw.deleteAccount();
}

class CatalogRepository {
  final RemoteGateway gw;
  CatalogRepository(this.gw);

  static final List<CategoryModel> fallbackCategories = [
    CategoryModel(
      id: '6ab2650a28cacb45be3e6ede',
      name: 'Solar Panel Services',
      description: 'Rooftop Solar Installation, Inverter Setup & Maintenance',
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077672/boutique/category/1790077667758-07c23513-7ee4-4973-b8d3-e5f7f498a50c.jpg',
      type: 'Service',
      serviceCount: 4,
    ),
    CategoryModel(
      id: '6ab2658e28cacb45be3e71de',
      name: 'Surveilance & CCTV',
      description: '4K IP Camera Setup, DVR/NVR Wiring & Mobile Live Feeds',
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077414/boutique/category/1790077408627-78b0e2ca-544f-4922-99d8-1f1ab250284a.jpg',
      type: 'Service',
      serviceCount: 5,
    ),
    CategoryModel(
      id: '6ab2677328cacb45be3e79f4',
      name: 'Battery & Inverter',
      description: 'UPS Backup, Battery Health Check & Acid Refill',
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790076791/boutique/category/1790076787267-b518e2bb-b1f0-4b9e-aa3f-fc4cee7b207e.jpg',
      type: 'Service',
      serviceCount: 3,
    ),
    CategoryModel(
      id: '6ab2682128cacb45be3e8001',
      name: 'Air Conditioner Repair',
      description: 'AC Gas Charging, Jet Foam Service & Installation',
      image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80',
      type: 'Service',
      serviceCount: 6,
    ),
  ];

  static final List<ServiceModel> fallbackServices = [
    ServiceModel(
      id: '6ab2650a28cacb45be3e8001',
      name: 'On-Grid Rooftop Solar Installation & Net-Metering',
      description: 'Complete rooftop solar installation with MNRE subsidy documentation, bi-directional net meter setup, and lightning arrestor.',
      price: 14999,
      mrp: 18999,
      rating: 4.9,
      ratingCount: 142,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077672/boutique/category/1790077667758-07c23513-7ee4-4973-b8d3-e5f7f498a50c.jpg',
      categoryId: '6ab2650a28cacb45be3e6ede',
      categoryName: 'Solar Panel Services',
      warranty: '5 Year Installation Warranty',
      durationMin: 240,
    ),
    ServiceModel(
      id: '6ab2658e28cacb45be3e8002',
      name: '4-Camera HD CCTV Surveillance Setup & Mobile Live View',
      description: 'Full wiring, dome & bullet camera mounting, DVR configuration, hard disk setup, and smartphone live streaming setup.',
      price: 2499,
      mrp: 3499,
      rating: 4.9,
      ratingCount: 98,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077414/boutique/category/1790077408627-78b0e2ca-544f-4922-99d8-1f1ab250284a.jpg',
      categoryId: '6ab2658e28cacb45be3e71de',
      categoryName: 'Surveilance & CCTV',
      warranty: '1 Year Doorstep Warranty',
      durationMin: 120,
    ),
    ServiceModel(
      id: '6ab2677328cacb45be3e8003',
      name: 'Home Inverter / UPS Comprehensive Health Check & Repair',
      description: 'MOSFET testing, transformer check, battery gravity testing, acid top-up, and terminal cleaning.',
      price: 499,
      mrp: 799,
      rating: 4.8,
      ratingCount: 76,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790076791/boutique/category/1790076787267-b518e2bb-b1f0-4b9e-aa3f-fc4cee7b207e.jpg',
      categoryId: '6ab2677328cacb45be3e79f4',
      categoryName: 'Battery & Inverter',
      warranty: '30-Day Service Warranty',
      durationMin: 45,
    ),
    ServiceModel(
      id: '6ab2682128cacb45be3e8004',
      name: 'Split AC Deep Cleaning (Jet Foam Service)',
      description: 'High pressure jet pump wash with indoor coil foam cleaning, outdoor unit descaling, and cooling temperature verification.',
      price: 599,
      mrp: 999,
      rating: 4.9,
      ratingCount: 210,
      image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80',
      categoryId: '6ab2682128cacb45be3e8001',
      categoryName: 'Air Conditioner Repair',
      warranty: '60-Day Protection Plan',
      durationMin: 60,
    ),
  ];

  Future<List<CategoryModel>> categories() async {
    try {
      final r = await gw.categories();
      if (r is ApiOk) {
        final list = _parseList(r.data, (e) => CategoryModel.fromJson(e));
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return fallbackCategories;
  }

  Future<(List<ServiceModel> items, String? prompt)> services({String? search, String? categoryId, double? lat, double? lng}) async {
    try {
      final r = await gw.services(search: search, categoryId: categoryId, lat: lat, lng: lng);
      if (r is ApiOk) {
        final data = r.data;
        final items = _parseList(data, (e) => ServiceModel.fromJson(e));
        if (items.isNotEmpty) {
          String? prompt;
          if (data is Map) {
            prompt = (data['availabilityPrompt'] ?? data['prompt'] ?? data['message'])?.toString();
          }
          return (items, prompt);
        }
      }
    } catch (_) {}

    var filtered = fallbackServices;
    if (categoryId != null && categoryId.isNotEmpty) {
      filtered = filtered.where((s) => s.categoryId == categoryId).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((s) => s.name.toLowerCase().contains(q) || (s.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    return (filtered, null);
  }

  Future<ServiceModel> service(String id) async {
    try {
      final r = await gw.service(id);
      if (kDebugMode) {
        debugPrint('[CatalogRepository] raw GET /api/user/getServiceById/$id response: ${r is ApiOk ? r.data : (r as ApiErr).message}');
      }
      if (r is ApiOk) {
        final d = r.data;
        final m = asMap(d);
        final inner = m.containsKey('service') ? m['service'] : d;
        return ServiceModel.fromJson(inner);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CatalogRepository] error fetching service $id: $e');
    }
    return fallbackServices.firstWhere((s) => s.id == id, orElse: () => fallbackServices.first);
  }
}

class ProductRepository {
  final RemoteGateway gw;
  ProductRepository(this.gw);

  static final List<ProductModel> fallbackProducts = [
    ProductModel(
      id: '6ab2650a28cacb45be3e7001',
      name: 'RightTouch 550W Mono PERC Solar Panel',
      description: 'High efficiency Half-Cut Bifacial Mono-crystalline solar panel with 25-year performance warranty and anti-reflective coating.',
      price: 18500,
      mrp: 22000,
      rating: 4.9,
      ratingCount: 112,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077672/boutique/category/1790077667758-07c23513-7ee4-4973-b8d3-e5f7f498a50c.jpg',
      categoryName: 'Solar Products',
      categoryId: '6ab2650a28cacb45be3e6ede',
      brand: 'RightTouch Solar',
      warranty: '25 Year Performance Warranty',
    ),
    ProductModel(
      id: '6ab2650a28cacb45be3e7002',
      name: 'RightTouch 5kVA Solar Hybrid MPPT Inverter',
      description: 'Pure sine wave hybrid inverter with integrated MPPT charge controller, WiFi monitoring, and dual AC outputs.',
      price: 42000,
      mrp: 48000,
      rating: 4.9,
      ratingCount: 84,
      image: 'https://res.cloudinary.com/db0ani4q6/image/upload/v1780291260/boutique/category/1780291257800-1772945969521-whatsapp-image-2026-02-05-at-10.jpg',
      categoryName: 'Solar Products',
      categoryId: '6ab2650a28cacb45be3e6ede',
      brand: 'RightTouch Power',
      warranty: '5 Year Comprehensive Warranty',
    ),
    ProductModel(
      id: '6ab2658e28cacb45be3e7003',
      name: 'RightTouch 4K UltraHD AI NightVision CCTV Camera',
      description: 'Full color night vision, AI human & vehicle detection, two-way audio, and IP67 weatherproof metallic casing.',
      price: 3499,
      mrp: 4999,
      rating: 4.8,
      ratingCount: 146,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077414/boutique/category/1790077408627-78b0e2ca-544f-4922-99d8-1f1ab250284a.jpg',
      categoryName: 'Surveilance Products',
      categoryId: '6ab2658e28cacb45be3e71de',
      brand: 'RightTouch Vision',
      warranty: '2 Year Replacement Warranty',
    ),
    ProductModel(
      id: '6ab2658e28cacb45be3e7004',
      name: 'RightTouch 8-Channel 4K NVR Smart Security Kit',
      description: 'Complete 8-channel PoE NVR kit with 2TB surveillance hard drive, 4 cameras, and instant remote mobile live feed.',
      price: 16999,
      mrp: 21999,
      rating: 4.9,
      ratingCount: 92,
      image: 'https://res.cloudinary.com/db0ani4q6/image/upload/v1780291469/boutique/category/1780291467309-cctv-ser.jpg',
      categoryName: 'Surveilance Products',
      categoryId: '6ab2658e28cacb45be3e71de',
      brand: 'RightTouch Vision',
      warranty: '3 Year Brand Warranty',
    ),
    ProductModel(
      id: '6ab2677328cacb45be3e7005',
      name: 'RightTouch 150Ah Tall Tubular Solar C10 Battery',
      description: 'Heavy duty tall tubular battery designed for high discharge solar and inverter cycles with 99.99% pure lead oxide.',
      price: 13500,
      mrp: 16000,
      rating: 4.9,
      ratingCount: 78,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790076791/boutique/category/1790076787267-b518e2bb-b1f0-4b9e-aa3f-fc4cee7b207e.jpg',
      categoryName: 'Battery',
      categoryId: '6ab2677328cacb45be3e79f4',
      brand: 'RightTouch Energy',
      warranty: '60 Months (36M Replacement + 24M Pro-rata)',
    ),
    ProductModel(
      id: '6ab2658e28cacb45be3e7006',
      name: 'RightTouch 360° Smart WiFi PTZ Outdoor Camera',
      description: 'Pan-tilt-zoom 3MP high-speed dome camera with auto tracking, siren alarm, micro SD storage, and mobile control.',
      price: 4599,
      mrp: 5999,
      rating: 4.8,
      ratingCount: 65,
      image: 'https://res.cloudinary.com/dpoebjnnu/image/upload/v1790077414/boutique/category/1790077408627-78b0e2ca-544f-4922-99d8-1f1ab250284a.jpg',
      categoryName: 'Surveilance Products',
      categoryId: '6ab2658e28cacb45be3e71de',
      brand: 'RightTouch Vision',
      warranty: '2 Year Warranty',
    ),
  ];

  Future<List<ProductModel>> products({String? search, String? categoryId}) async {
    try {
      final r = await gw.products();
      if (r is ApiOk) {
        final raw = r.data;
        final list = _parseList(raw, (e) => ProductModel.fromJson(e));
        if (list.isNotEmpty) {
          return _filter(list, search, categoryId);
        }
      }
    } catch (_) {}
    return _filter(fallbackProducts, search, categoryId);
  }

  List<ProductModel> _filter(List<ProductModel> list, String? search, String? categoryId) {
    var result = list;
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((p) {
        if (p.categoryId == categoryId) return true;
        if (p.categoryName?.toLowerCase() == categoryId.toLowerCase()) return true;
        return false;
      }).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false) ||
        (p.categoryName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return result;
  }
}

class BookingRepository {
  final RemoteGateway gw;
  BookingRepository(this.gw);
  Future<List<BookingModel>> myBookings() async {
    final r = await gw.myBookings();
    if (r is ApiOk) return _parseList(r.data, (e) => BookingModel.fromJson(e));
    if (r is ApiErr) throw ApiException(r.message);
    throw ApiException('Unexpected response');
  }

  Future<BookingModel> detail(String id) async {
    final r = await gw.booking(id);
    if (r is ApiOk) {
      final d = r.data;
      final m = asMap(d);
      return BookingModel.fromJson(m.containsKey('booking') ? m['booking'] : d);
    }
    if (r is ApiErr) throw ApiException(r.message);
    throw ApiException('Unexpected response');
  }

  Future<void> schedule(Map<String, dynamic> b) async {
    final r = await gw.schedule(b);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> cancel(String id, [String? reason]) async {
    final r = await gw.cancelBooking(id, reason);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> bookAgain(String bookingId) async {
    final r = await gw.bookAgain({'bookingId': bookingId});
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }

  Future<List<String>> reasons() async {
    final r = await gw.cancelReasons();
    if (r is ApiOk) {
      final d = r.data;
      if (d is List) return d.map((e) => e.toString()).toList();
      if (d is Map) {
        for (final k in ['reasons', 'items', 'data']) {
          final v = d[k];
          if (v is List) return v.map((e) => e is Map ? (e['reason'] ?? e['name'] ?? e.toString()).toString() : e.toString()).toList();
        }
      }
    }
    return ['Plan changed', 'Booked by mistake', 'Found another provider', 'Price too high', 'Other'];
  }
}

class CartRepository {
  final RemoteGateway gw;
  CartRepository(this.gw);

  Future<List<CartItemModel>> myCart() async {
    final r = await gw.myCart();
    if (kDebugMode) {
      debugPrint('[Cart] raw GET /cart/my-cart JSON: ${r is ApiOk ? r.data : (r as ApiErr).message}');
    }
    if (r is ApiOk) {
      return _parseList(r.data, (e) => CartItemModel.fromJson(e));
    }
    if (r is ApiErr) throw ApiException(r.message);
    throw ApiException('Unexpected response');
  }

  Future<void> add(String id, String type, int qty, {String? name, num? price, String? image}) async {
    if (id.isEmpty) throw ApiException('Item ID is missing');
    debugPrint('[Cart] add → itemId=$id, itemType=$type, qty=$qty');
    final r = await gw.cartAdd(id, type, qty);
    if (r is ApiErr) {
      debugPrint('[Cart] add FAILED: ${r.message} (${r.statusCode}) reason: ${r.reason ?? "none"}');
      throw ApiException(r.message, r.statusCode);
    }
    debugPrint('[Cart] add SUCCESS for $id');
  }

  Future<void> remove(String id) async {
    final r = await gw.cartRemove(id);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> checkout(Map<String, dynamic> b) async {
    final r = await gw.checkout(b);
    if (r is ApiErr) throw ApiException(r.message);
  }
}

class AddressRepository {
  final RemoteGateway gw;
  AddressRepository(this.gw);
  Future<List<AddressModel>> list() async {
    final r = await gw.addresses();
    if (r is ApiOk) return _parseList(r.data, (e) => AddressModel.fromJson(e));
    if (r is ApiErr) throw ApiException(r.message);
    throw ApiException('Unexpected response');
  }

  Future<void> create(AddressModel a) async {
    final r = await gw.createAddress(a.toJson());
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> remove(String id) async {
    final r = await gw.deleteAddress(id);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> setDefault(AddressModel a) async {
    final r = await gw.setDefault({'addressId': a.id, ...a.toJson()});
    if (r is ApiErr) throw ApiException(r.message);
  }
}

class PaymentRepository {
  final RemoteGateway gw;
  PaymentRepository(this.gw);
  Future<List<PaymentModel>> list() async {
    try {
      final r = await gw.payments();
      if (r is ApiOk) return _parseList(r.data, (e) => PaymentModel.fromJson(e));
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> summary() async {
    try {
      final r = await gw.paymentsSummary();
      if (r is ApiOk) return asMap(r.data);
    } catch (_) {}
    return {'totalPaid': 0, 'pending': 0, 'refunded': 0};
  }

  Future<void> createOrder(String bookingId) async {
    final r = await gw.paymentOrder(bookingId);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> retryPayment(String bookingId) async {
    final r = await gw.paymentRetry(bookingId);
    if (r is ApiErr) throw ApiException(r.message);
  }
}

class SupportRepository {
  final RemoteGateway gw;
  SupportRepository(this.gw);

  Future<List<QuotationModel>> quotations() async {
    try {
      final r = await gw.quotations();
      if (r is ApiOk) return _parseList(r.data, (e) => QuotationModel.fromJson(e));
    } catch (_) {}
    return [];
  }

  Future<List<QuoteRequestModel>> quoteRequests() async {
    try {
      final r = await gw.quoteRequests();
      if (r is ApiOk) return _parseList(r.data, (e) => QuoteRequestModel.fromJson(e));
    } catch (_) {}
    return [];
  }

  Future<void> submitQuoteRequest(String requirement, {String? addressId, String? contactMethod}) async {
    final body = {
      'requirementDescription': requirement,
      'locationType': addressId != null ? 'saved' : 'current',
      if (addressId != null) 'addressId': addressId,
      'preferredContactMethod': contactMethod ?? 'phone',
    };
    final r = await gw.submitQuoteRequest(body);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }

  Future<void> cancelQuoteRequest(String id) async {
    final r = await gw.cancelQuoteRequest(id);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<List<ProductBookingModel>> productBookings() async {
    try {
      final r = await gw.productBookings();
      if (r is ApiOk) return _parseList(r.data, (e) => ProductBookingModel.fromJson(e));
    } catch (_) {}
    return [];
  }

  Future<List<NotificationModel>> notifications() async {
    try {
      final r = await gw.notifications();
      if (r is ApiOk) return _parseList(r.data, (e) => NotificationModel.fromJson(e));
    } catch (_) {}
    return [];
  }

  Future<int> unreadCount() async {
    try {
      final r = await gw.unreadCount();
      if (r is ApiOk) {
        final d = r.data;
        if (d is Map) return (d['unreadCount'] ?? d['count'] ?? 0) as int;
        if (d is num) return d.toInt();
      }
    } catch (_) {}
    return 0;
  }

  Future<void> acceptQuote(String id) async {
    final r = await gw.quotationAccept(id);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> rejectQuote(String id) async {
    final r = await gw.quotationReject(id);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<void> report(Map<String, dynamic> b) async {
    final r = await gw.createReport(b);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<List<ReportModel>> myReports() async {
    try {
      final r = await gw.myReports();
      if (r is ApiOk) return _parseList(r.data, (e) => ReportModel.fromJson(e));
    } catch (_) {}
    return [];
  }

  Future<List<String>> reportCategories() async {
    try {
      final r = await gw.reportCategories();
      if (r is ApiOk) {
        final d = r.data;
        if (d is List) return d.map((e) => e.toString()).toList();
        if (d is Map && d['categories'] is List) {
          return (d['categories'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return ['Service Quality', 'Technician Delayed', 'Billing Issue', 'Spare Parts Issue', 'Other'];
  }

  Future<void> rating(Map<String, dynamic> b) async {
    final r = await gw.submitRating(b);
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<Map<String, dynamic>?> zoneCheck(double lat, double lng) async {
    final r = await gw.checkService(lat, lng);
    if (r is ApiOk) {
      final d = r.data;
      if (d is Map) return Map<String, dynamic>.from(d);
      return {'data': d};
    }
    return null;
  }
}
