import 'package:flutter/foundation.dart';
import '../../core/network/api_result.dart';
import '../../core/storage/local_cache.dart';
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
      if (v is Map) {
        final nested = _parseList(v, f);
        if (nested.isNotEmpty) return nested;
      }
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
      } else if (kDebugMode && r is ApiErr) {
        debugPrint('[CatalogRepository] categories error: ${r.message} (${r.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CatalogRepository] categories exception: $e');
    }
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
      } else if (kDebugMode && r is ApiErr) {
        debugPrint('[CatalogRepository] services error: ${r.message} (${r.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[CatalogRepository] services exception: $e');
    }

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
      if (r is ApiErr) throw ApiException(r.message);
      throw ApiException('Service not found');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load service: $e');
    }
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
      } else if (kDebugMode && r is ApiErr) {
        debugPrint('[ProductRepository] products error: ${r.message} (${r.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ProductRepository] products exception: $e');
    }
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

  Future<ProductModel> product(String id) async {
    try {
      final r = await gw.product(id);
      if (r is ApiOk) {
        final d = r.data;
        final m = asMap(d);
        final rawProd = m.containsKey('product')
            ? m['product']
            : (m.containsKey('result') ? m['result'] : (m.containsKey('data') ? m['data'] : d));
        if (rawProd != null) {
          final prod = ProductModel.fromJson(rawProd);
          if (prod.id.isNotEmpty && prod.name.isNotEmpty) {
            return prod;
          }
        }
      }
      if (r is ApiErr) throw ApiException(r.message);
    } catch (e) {
      if (e is ApiException) rethrow;
    }
    final list = await products();
    final match = list.where((p) => p.id == id);
    if (match.isNotEmpty) return match.first;
    throw ApiException('Product not found');
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
    try {
      final r = await gw.booking(id);
      if (r is ApiOk) {
        final d = r.data;
        final m = asMap(d);
        return BookingModel.fromJson(m.containsKey('booking') ? m['booking'] : d);
      }
      if (r is ApiErr) {
        // Fallback: if getBookingById restricts to Admin/Owner, get from customer bookings
        final myB = await myBookings().catchError((_) => <BookingModel>[]);
        final found = myB.where((b) => b.id == id).firstOrNull;
        if (found != null) return found;
        throw ApiException(r.message);
      }
    } catch (e) {
      final myB = await myBookings().catchError((_) => <BookingModel>[]);
      final found = myB.where((b) => b.id == id).firstOrNull;
      if (found != null) return found;
      rethrow;
    }
    final myB = await myBookings().catchError((_) => <BookingModel>[]);
    final found = myB.where((b) => b.id == id).firstOrNull;
    if (found != null) return found;
    throw ApiException('Booking not found');
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

  Future<Map<String, dynamic>> completionStatus(String id) async {
    final r = await gw.bookingCompletionStatus(id);
    if (r is ApiOk) return asMap(r.data);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    return {};
  }

  Future<void> delete(String id) async {
    final r = await gw.deleteBooking(id);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }

  Future<void> deleteAll() async {
    final r = await gw.deleteAllBookings();
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
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

  Future<void> updateQty(
    String id,
    int qty, {
    String? itemId,
    String? itemType,
  }) async {
    final effectiveItemId = (itemId != null && itemId.isNotEmpty) ? itemId : id;
    final type = (itemType != null && itemType.isNotEmpty) ? itemType.toLowerCase() : 'service';
    final body = <String, dynamic>{
      'cartItemId': id,
      'id': id,
      'itemId': effectiveItemId,
      'itemType': type,
      'quantity': qty,
      'qty': qty,
    };
    if (kDebugMode) {
      debugPrint('[Cart] updateQty → cartItemId=$id, itemId=$effectiveItemId, type=$type, qty=$qty');
    }
    final r = await gw.cartUpdate(body);
    if (r is ApiErr) {
      if (kDebugMode) {
        debugPrint('[Cart] updateQty FAILED: ${r.message} (${r.statusCode})');
      }
      throw ApiException(r.message, r.statusCode);
    }
    if (kDebugMode) {
      debugPrint('[Cart] updateQty SUCCESS for $effectiveItemId (qty: $qty)');
    }
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

  Future<AddressModel?> getDefault() async {
    try {
      final r = await gw.defaultAddress();
      if (r is ApiOk && r.data != null) {
        final m = asMap(r.data);
        final item = m.containsKey('result')
            ? m['result']
            : (m.containsKey('address') ? m['address'] : m);
        if (item is Map && item.isNotEmpty) {
          final addr = AddressModel.fromJson(item);
          if (addr.id.isNotEmpty) {
            LocalCacheService.instance.cacheDefaultAddressId(addr.id);
            return addr;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> setDefault(AddressModel a) async {
    final r = await gw.setDefault({'addressId': a.id, ...a.toJson()});
    if (r is ApiErr) throw ApiException(r.message);
  }

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    try {
      final r = await gw.reverseGeocode(lat, lng);
      if (r is ApiOk && r.data != null) return asMap(r.data);
    } catch (_) {}
    return null;
  }
}

class PaymentRepository {
  final RemoteGateway gw;
  PaymentRepository(this.gw);

  Future<List<PaymentModel>> list({String? state, int limit = 20, String? cursor}) async {
    try {
      final r = await gw.payments();
      if (r is ApiOk) {
        if (r.data is Map && r.data['items'] is List) {
          return _parseList(r.data['items'], (e) => PaymentModel.fromJson(e));
        }
        return _parseList(r.data, (e) => PaymentModel.fromJson(e));
      }
    } catch (_) {}
    return [];
  }

  Future<PaymentSummaryModel> summary() async {
    try {
      final r = await gw.paymentsSummary();
      if (r is ApiOk) return PaymentSummaryModel.fromJson(r.data);
    } catch (_) {}
    return PaymentSummaryModel();
  }

  Future<PaymentModel?> detail(String bookingId) async {
    try {
      final r = await gw.paymentDetail(bookingId);
      if (r is ApiOk) return PaymentModel.fromJson(r.data);
    } catch (_) {}
    return null;
  }

  Future<PaymentOrderResult> createOrder(String bookingId, {String? idempotencyKey}) async {
    final r = await gw.paymentOrder(bookingId);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    if (r is ApiOk) return PaymentOrderResult.fromJson(r.data);
    throw ApiException('Failed to create payment order');
  }

  Future<PaymentOrderResult> retryPayment(String bookingId, {String? idempotencyKey}) async {
    final r = await gw.paymentRetry(bookingId);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    if (r is ApiOk) return PaymentOrderResult.fromJson(r.data);
    throw ApiException('Failed to retry payment');
  }

  Future<String?> declareCash(String bookingId, {String? idempotencyKey}) async {
    final r = await gw.declareCash(bookingId);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    if (r is ApiOk && r.data is Map) {
      return (r.data as Map)['attemptId']?.toString();
    }
    return null;
  }

  Future<PaymentReceiptModel?> receipt(String bookingId) async {
    try {
      final r = await gw.paymentReceipt(bookingId);
      if (r is ApiOk) return PaymentReceiptModel.fromJson(r.data);
    } catch (_) {}
    return null;
  }

  Future<List<PaymentRefundModel>> refunds(String bookingId) async {
    try {
      final r = await gw.paymentRefunds(bookingId);
      if (r is ApiOk) {
        if (r.data is Map && r.data['refunds'] is List) {
          return _parseList(r.data['refunds'], (e) => PaymentRefundModel.fromJson(e));
        }
        return _parseList(r.data, (e) => PaymentRefundModel.fromJson(e));
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> body) async {
    final r = await gw.verifyPayment(body);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    if (r is ApiOk && r.data is Map) {
      return Map<String, dynamic>.from(r.data as Map);
    }
    return {};
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

  Future<void> submitQuoteRequest(
    String requirement, {
    String? productId,
    int? quantity,
    String? addressId,
    String? locationType,
    double? latitude,
    double? longitude,
    String? additionalNotes,
    String? contactMethod,
  }) async {
    String? finalAddressId = addressId;
    if (finalAddressId == null || finalAddressId.isEmpty) {
      final cachedId = await LocalCacheService.instance.getCachedDefaultAddressId();
      if (cachedId != null && cachedId.isNotEmpty) {
        finalAddressId = cachedId;
      }
    }
    if (finalAddressId == null || finalAddressId.isEmpty) {
      try {
        final defR = await gw.defaultAddress();
        if (defR is ApiOk && defR.data != null) {
          final m = asMap(defR.data);
          final item = m.containsKey('result')
              ? m['result']
              : (m.containsKey('address') ? m['address'] : m);
          if (item is Map) {
            final parsedId = str(item['_id'] ?? item['id'] ?? item['addressId']);
            if (parsedId.isNotEmpty) {
              finalAddressId = parsedId;
              LocalCacheService.instance.cacheDefaultAddressId(parsedId);
            }
          }
        }
      } catch (_) {}
    }

    String normContact = 'whatsapp';
    if (contactMethod != null) {
      final c = contactMethod.toLowerCase().trim();
      if (c == 'call' || c == 'phone') {
        normContact = 'call';
      } else if (c == 'both') {
        normContact = 'both';
      } else {
        normContact = 'whatsapp';
      }
    }

    final isGps = locationType == 'gps' && latitude != null && longitude != null;
    final resolvedLocationType = isGps ? 'gps' : 'saved';

    final body = <String, dynamic>{
      if (productId != null && productId.isNotEmpty) 'productId': productId,
      'quantity': (quantity != null && quantity > 0) ? quantity : 1,
      'locationType': resolvedLocationType,
      if (resolvedLocationType == 'saved' && finalAddressId != null && finalAddressId.isNotEmpty)
        'addressId': finalAddressId,
      if (resolvedLocationType == 'gps') ...{
        'latitude': latitude,
        'longitude': longitude,
      },
      'requirementDescription': requirement,
      if (additionalNotes != null && additionalNotes.isNotEmpty) 'additionalNotes': additionalNotes,
      'preferredContactMethod': normContact,
    };
    final r = await gw.submitQuoteRequest(body);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }

  Future<QuoteRequestModel> quoteRequest(String id) async {
    final r = await gw.quoteRequest(id);
    if (r is ApiOk) {
      final d = r.data;
      final m = asMap(d);
      return QuoteRequestModel.fromJson(m.containsKey('request')
          ? m['request']
          : (m.containsKey('quoteRequest')
              ? m['quoteRequest']
              : (m.containsKey('result') ? m['result'] : d)));
    }
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    throw ApiException('Quote request not found');
  }

  Future<void> updateQuoteRequest(String id, Map<String, dynamic> body) async {
    final r = await gw.updateQuoteRequest(id, body);
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

  Future<ProductBookingModel> productBooking(String id) async {
    final r = await gw.productBooking(id);
    if (r is ApiOk) {
      final d = r.data;
      final m = asMap(d);
      return ProductBookingModel.fromJson(m.containsKey('booking')
          ? m['booking']
          : (m.containsKey('productBooking')
              ? m['productBooking']
              : (m.containsKey('result') ? m['result'] : d)));
    }
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    throw ApiException('Product booking not found');
  }

  Future<void> updateProductBookingQuantity(String id, int quantity) async {
    final r = await gw.updateProductBooking(id, quantity);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }

  Future<void> cancelProductBooking(String id, [String? reason]) async {
    final r = await gw.cancelProductBooking(id, reason);
    if (r is ApiErr) throw ApiException(r.message);
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

  Future<QuotationModel> quotationDetail(String id) async {
    final r = await gw.quotation(id);
    if (r is ApiOk) {
      final d = r.data;
      final m = asMap(d);
      return QuotationModel.fromJson(m.containsKey('quotation') ? m['quotation'] : d);
    }
    if (r is ApiErr) throw ApiException(r.message);
    throw ApiException('Could not load quotation');
  }

  Future<void> viewQuotation(String id) async {
    try {
      await gw.quotationView(id);
    } catch (_) {}
  }

  Future<QuotationAcceptResult> acceptQuote(String id, {List<String>? acceptedItemIds}) async {
    final body = <String, dynamic>{
      if (acceptedItemIds != null && acceptedItemIds.isNotEmpty)
        'acceptedItemIds': acceptedItemIds,
    };
    final r = await gw.quotationAccept(id, body);
    if (r is ApiOk) {
      return QuotationAcceptResult.fromJson(r.data);
    }
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    throw ApiException('Failed to accept quotation');
  }

  Future<void> rejectQuote(String id, [String? reason]) async {
    final r = await gw.quotationReject(id, {
      'reason': (reason != null && reason.trim().isNotEmpty) ? reason.trim() : 'Price is higher than expected.'
    });
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
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

  Future<void> withdrawReport(String id, [String? reason]) async {
    final r = await gw.withdrawReport(id, reason);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }

  Future<List<String>> reportCategories() async {
    try {
      final r = await gw.reportCategories();
      if (r is ApiOk) {
        final d = r.data;
        List rawList = [];
        if (d is List) rawList = d;
        if (d is Map && d['categories'] is List) rawList = d['categories'];
        if (rawList.isNotEmpty) {
          return rawList.map<String>((e) {
            if (e is Map) {
              return (e['label'] ?? e['name'] ?? e['title'] ?? e['key'] ?? 'Other').toString();
            }
            return e.toString();
          }).toList();
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

  Future<void> registerDeviceToken(String token) async {
    try {
      final res = await gw.registerDevice({
        'token': token,
        'fcmToken': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'deviceId': 'default',
      });
      if (res is ApiErr) {
        debugPrint('[FCM Register Error] ${res.message}');
      } else {
        debugPrint('[FCM Register Success] Device token synced');
      }
    } catch (e) {
      debugPrint('[FCM Register Exception] $e');
    }
  }

  Future<void> syncPermissions({
    required String status,
    String? deviceId,
  }) async {
    try {
      final res = await gw.updatePermissions({
        'deviceId': deviceId ?? 'default',
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'permissions': {
          'notification': status,
        },
      });
      if (res is ApiErr) {
        debugPrint('[Permission Sync Error] ${res.message}');
      } else {
        debugPrint('[Permission Sync Success] Notification permission synced: $status');
      }
    } catch (e) {
      debugPrint('[Permission Sync Exception] $e');
    }
  }

  Future<void> deleteDeviceToken([String? token]) async {
    try {
      await gw.deleteDeviceToken({
        if (token != null && token.isNotEmpty) 'fcmToken': token,
        'deviceId': 'default',
      });
    } catch (_) {}
  }

  Future<void> markNotificationOpened(String id) async {
    try {
      await gw.notifOpened(id);
    } catch (_) {}
  }

  Future<void> markNotificationReceived(String id) async {
    try {
      await gw.notifReceived(id);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getPermissions([String? deviceId]) async {
    try {
      final r = await gw.getPermissions(deviceId);
      if (r is ApiOk && r.data != null) return asMap(r.data);
    } catch (_) {}
    return null;
  }
}

class RatingRepository {
  final RemoteGateway gw;
  RatingRepository(this.gw);

  Future<List<RatingModel>> getMyRatings() async {
    try {
      final r = await gw.myRatings();
      if (r is ApiOk) {
        return _parseList(r.data, (e) => RatingModel.fromJson(e));
      }
      final rAlt = await gw.myRatingsAlt();
      if (rAlt is ApiOk) {
        return _parseList(rAlt.data, (e) => RatingModel.fromJson(e));
      }
    } catch (_) {}
    return [];
  }

  Future<RatingModel> getRatingById(String id) async {
    final r = await gw.getRatingById(id);
    if (r is ApiOk) {
      final d = (r.data is Map && r.data['result'] != null)
          ? r.data['result']
          : ((r.data is Map && r.data['data'] != null) ? r.data['data'] : r.data);
      return RatingModel.fromJson(d);
    }
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    throw ApiException('Failed to fetch rating');
  }

  Future<Map<String, dynamic>> submitRating({
    required String bookingId,
    required String bookingType,
    required int rates,
    required String comment,
  }) async {
    final body = {
      'bookingId': bookingId,
      'bookingType': bookingType,
      'rates': rates,
      'comment': comment,
    };
    final r = await gw.submitRating(body);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    if (r is ApiOk && r.data is Map) return Map<String, dynamic>.from(r.data);
    return {};
  }

  Future<Map<String, dynamic>> updateRating({
    required String id,
    int? rates,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      if (rates != null) 'rates': rates,
      if (comment != null) 'comment': comment,
    };
    final r = await gw.updateRating(id, body);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    if (r is ApiOk && r.data is Map) return Map<String, dynamic>.from(r.data);
    return {};
  }

  Future<void> deleteRating(String id) async {
    final r = await gw.deleteRating(id);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
  }
}

class RewardRepository {
  final RemoteGateway gw;
  RewardRepository(this.gw);

  Future<RewardBalanceModel> getBalance() async {
    final r = await gw.rewardBalance();
    if (r is ApiOk) return RewardBalanceModel.fromJson(r.data);
    return const RewardBalanceModel();
  }

  Future<List<RewardTransactionModel>> getHistory({int page = 1, int limit = 20}) async {
    final r = await gw.rewardHistory(page: page, limit: limit);
    if (r is ApiOk) {
      final m = asMap(r.data);
      final raw = m.containsKey('result') ? m['result'] : (m.containsKey('data') ? m['data'] : m);
      return _parseList(raw, (e) => RewardTransactionModel.fromJson(e));
    }
    return [];
  }

  Future<Map<String, dynamic>> reconcile() async {
    final r = await gw.reconcileRewards();
    if (r is ApiOk) return asMap(r.data);
    if (r is ApiErr) throw ApiException(r.message, r.statusCode);
    return {};
  }
}

