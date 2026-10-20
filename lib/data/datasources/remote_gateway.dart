import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';

/// Single remote gateway grouping all customer endpoints.
/// Repositories wrap this for clean domain separation.
class RemoteGateway {
  final ApiClient api;
  RemoteGateway(this.api);

  // ---------- Auth (customer passwordless OTP — verified contracts) ----------
  /// POST /api/user/signup/customer (PUBLIC)
  /// Body: {identifier, role:Customer, termsAndServices:true, privacyPolicy:true}
  Future<ApiResult<dynamic>> signupCustomer(String mobile) => api.post(
        ApiEndpoints.signupCustomer,
        {
          'identifier': mobile,
          'role': 'Customer',
          'termsAndServices': true,
          'privacyPolicy': true,
        },
      );

  /// POST /api/user/signup/customer/verify-otp → 201 {token, refresh_token, expires_in, user}
  Future<ApiResult<dynamic>> verifySignupCustomer(String mobile, String otp) =>
      api.post(ApiEndpoints.signupCustomerVerify, {
        'identifier': mobile,
        'otp': otp,
      });

  /// POST /api/user/login/customer (PUBLIC) Body: {identifier, role:Customer}
  Future<ApiResult<dynamic>> loginCustomer(String mobile) => api.post(
        ApiEndpoints.loginCustomer,
        {
          'identifier': mobile,
          'role': 'Customer',
        },
      );

  /// POST /api/user/login/customer/verify-otp → 200 {token, refresh_token, expires_in, user}
  Future<ApiResult<dynamic>> verifyLoginCustomer(String mobile, String otp) =>
      api.post(ApiEndpoints.loginCustomerVerify, {
        'identifier': mobile,
        'otp': otp,
      });

  /// Unified OTP (all roles, DRY) — fallback
  Future<ApiResult<dynamic>> requestOtp(String mobile) => api.post(
        ApiEndpoints.requestOtp,
        {'identifier': mobile, 'role': 'Customer'},
      );
  Future<ApiResult<dynamic>> verifyOtp(String mobile, String otp) =>
      api.post(ApiEndpoints.verifyOtp, {
        'identifier': mobile,
        'otp': otp,
        'role': 'Customer',
      });

  /// POST /api/user/resend-otp (60s cooldown else 429 OTP_COOLDOWN)
  Future<ApiResult<dynamic>> resendOtp(String mobile, {String? purpose}) =>
      api.post(ApiEndpoints.resendOtp, {
        'identifier': mobile,
        if (purpose != null) 'purpose': purpose,
      });
  Future<ApiResult<dynamic>> signup(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.signup, body);

  /// P5 persistent sessions — rotation: old refresh dies immediately.
  Future<ApiResult<dynamic>> refresh(String refreshToken) => api.post(
        ApiEndpoints.refresh,
        {'refresh_token': refreshToken, 'refreshToken': refreshToken},
      );
  Future<ApiResult<dynamic>> logout() => api.post(ApiEndpoints.logout, {});
  Future<ApiResult<dynamic>> logoutAll() => api.post(ApiEndpoints.logoutAll, {});
  Future<ApiResult<dynamic>> verifyGeneric(String identifier, String otp) =>
      api.post(ApiEndpoints.verifySignupOtp,
          {'identifier': identifier, 'mobileNumber': identifier, 'otp': otp});

  /// Dev-only: check whether an identifier is registered (drives
  /// Login-vs-Signup auto-select). Absent on prod → ApiErr.
  Future<ApiResult<dynamic>> debugCheckUser(String identifier) =>
      api.get(ApiEndpoints.debugCheckUser(identifier));
  Future<ApiResult<dynamic>> me() => api.get(ApiEndpoints.me);
  Future<ApiResult<dynamic>> completeProfile(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.completeProfile, body);
  Future<ApiResult<dynamic>> updateProfile(Map<String, dynamic> body) =>
      api.put(ApiEndpoints.me, body);
  /// POST /api/user/auth/accept-terms (Auth) Body: {termsAndServices, privacyPolicy}
  Future<ApiResult<dynamic>> acceptTerms() => api.post(
        ApiEndpoints.acceptTerms,
        {'termsAndServices': true, 'privacyPolicy': true},
      );
  Future<ApiResult<dynamic>> deleteAccount() => api.delete(ApiEndpoints.deleteAccount);

  // ---------- Catalog ----------
  Future<ApiResult<dynamic>> categories() => api.get(ApiEndpoints.allCategories);
  Future<ApiResult<dynamic>> services({String? search, String? categoryId, double? lat, double? lng}) =>
      api.get(ApiEndpoints.allServices, query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });
  Future<ApiResult<dynamic>> service(String id) => api.get(ApiEndpoints.serviceById(id));
  Future<ApiResult<dynamic>> products() => api.get(ApiEndpoints.allProducts);

  // ---------- Booking ----------
  Future<ApiResult<dynamic>> slots() => api.get(ApiEndpoints.bookingSlots);
  Future<ApiResult<dynamic>> schedule(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.bookingSchedule, body);
  Future<ApiResult<dynamic>> myBookings() => api.get(ApiEndpoints.customerBookings);
  Future<ApiResult<dynamic>> booking(String id) => api.get(ApiEndpoints.bookingById(id));
  Future<ApiResult<dynamic>> cancelReasons() => api.get(ApiEndpoints.bookingReasons);
  Future<ApiResult<dynamic>> cancelBooking(String id, [String? reason]) =>
      api.put(ApiEndpoints.bookingCancel(id), {'reason': reason ?? 'Customer request'});
  Future<ApiResult<dynamic>> completedServices({double? lat, double? lng}) =>
      api.get(ApiEndpoints.completedServices, query: {
        'active': 'true',
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });
  Future<ApiResult<dynamic>> bookAgain(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.bookAgain, body);

  // ---------- Cart / checkout ----------
  Future<ApiResult<dynamic>> cartAdd(String itemId, String type, int qty) =>
      api.post(ApiEndpoints.cartAdd, {'itemId': itemId, 'itemType': type, 'quantity': qty});
  Future<ApiResult<dynamic>> myCart() => api.get(ApiEndpoints.myCart);
  Future<ApiResult<dynamic>> cartUpdate(Map<String, dynamic> body) async {
    // 1. Try PUT /api/user/cart/update
    final res = await api.put(ApiEndpoints.cartUpdate, body);
    if (res is ApiOk) return res;

    // 2. Try PUT /api/user/cart/:id with cartItemId / id
    final cid = (body['cartItemId'] ?? body['id'])?.toString();
    if (cid != null && cid.isNotEmpty) {
      final res2 = await api.put(ApiEndpoints.cartItemUpdate(cid), body);
      if (res2 is ApiOk) return res2;
    }

    // 3. Try PUT /api/user/cart/:id with itemId
    final iid = body['itemId']?.toString();
    if (iid != null && iid.isNotEmpty && iid != cid) {
      final res3 = await api.put(ApiEndpoints.cartItemUpdate(iid), body);
      if (res3 is ApiOk) return res3;
    }

    // 4. Fallback: try cartAdd
    if (iid != null && iid.isNotEmpty) {
      final resAdd = await api.post(ApiEndpoints.cartAdd, {
        'itemId': iid,
        'itemType': body['itemType'] ?? 'service',
        'quantity': body['quantity'] ?? 1,
      });
      if (resAdd is ApiOk) return resAdd;
    }

    return res;
  }
  Future<ApiResult<dynamic>> cartRemove(String id) async {
    final res = await api.delete(ApiEndpoints.cartRemove(id));
    if (res is ApiErr && res.statusCode == 404) {
      return api.delete(ApiEndpoints.cartRemoveAlt(id));
    }
    return res;
  }
  Future<ApiResult<dynamic>> cartSchedule(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.cartSetSchedule, body);
  Future<ApiResult<dynamic>> checkout(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.checkout, body);

  // ---------- Payments ----------
  Future<ApiResult<dynamic>> payments() => api.get(ApiEndpoints.payments);
  Future<ApiResult<dynamic>> paymentsSummary() => api.get(ApiEndpoints.paymentsSummary);
  Future<ApiResult<dynamic>> paymentDetail(String bookingId) =>
      api.get(ApiEndpoints.paymentDetail(bookingId));
  Future<ApiResult<dynamic>> paymentOrder(String bookingId) =>
      api.post(ApiEndpoints.paymentOrder(bookingId), {});
  Future<ApiResult<dynamic>> paymentRetry(String bookingId) =>
      api.post(ApiEndpoints.paymentRetry(bookingId), {});
  Future<ApiResult<dynamic>> paymentRefunds(String bookingId) =>
      api.get(ApiEndpoints.paymentRefunds(bookingId));
  Future<ApiResult<dynamic>> declareCash(String bookingId) =>
      api.post(ApiEndpoints.cashDeclare(bookingId), {});
  Future<ApiResult<dynamic>> verifyPayment(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.paymentVerify, body);

  // ---------- Addresses ----------
  Future<ApiResult<dynamic>> addresses() => api.get(ApiEndpoints.addresses);
  Future<ApiResult<dynamic>> defaultAddress() => api.get(ApiEndpoints.addressDefault);
  Future<ApiResult<dynamic>> createAddress(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.addresses, body);
  Future<ApiResult<dynamic>> updateAddress(Map<String, dynamic> body) =>
      api.put(ApiEndpoints.addresses, body);
  Future<ApiResult<dynamic>> deleteAddress(String addressId) =>
      api.delete(
        ApiEndpoints.addresses,
        {'addressId': addressId, 'id': addressId, '_id': addressId},
        {'addressId': addressId, 'id': addressId},
      );
  Future<ApiResult<dynamic>> setDefault(Map<String, dynamic> body) =>
      api.put(ApiEndpoints.addressDefault, body);
  Future<ApiResult<dynamic>> searchAddress(String q) =>
      api.get(ApiEndpoints.addressSearch, query: {'q': q, 'query': q});

  // ---------- Zones ----------
  Future<ApiResult<dynamic>> resolveZone(double lat, double lng) =>
      api.post(ApiEndpoints.zoneResolve, {'latitude': lat, 'longitude': lng});
  Future<ApiResult<dynamic>> checkService(double lat, double lng, [String? serviceId]) =>
      api.post(ApiEndpoints.zoneCheckService, {
        'latitude': lat, 'longitude': lng,
        if (serviceId != null) 'serviceId': serviceId,
      });

  // ---------- Ratings / reports / quotes / notifications ----------
  Future<ApiResult<dynamic>> submitRating(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.rating, body);
  Future<ApiResult<dynamic>> myRatings() => api.get(ApiEndpoints.ratings);
  Future<ApiResult<dynamic>> myRatingsAlt() => api.get(ApiEndpoints.myRatings);
  Future<ApiResult<dynamic>> getRatingById(String id) =>
      api.get(ApiEndpoints.ratingById(id));
  Future<ApiResult<dynamic>> updateRating(String id, Map<String, dynamic> body) =>
      api.put(ApiEndpoints.updateRating(id), body);
  Future<ApiResult<dynamic>> deleteRating(String id) =>
      api.delete(ApiEndpoints.deleteRating(id));
  Future<ApiResult<dynamic>> createReport(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.reports, body);
  Future<ApiResult<dynamic>> myReports() => api.get(ApiEndpoints.myReports);
  Future<ApiResult<dynamic>> reportCategories() => api.get(ApiEndpoints.reportCategories);
  Future<ApiResult<dynamic>> quoteRequests() => api.get(ApiEndpoints.quoteRequests);
  Future<ApiResult<dynamic>> submitQuoteRequest(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.quoteRequests, body);
  Future<ApiResult<dynamic>> cancelQuoteRequest(String id) =>
      api.post(ApiEndpoints.quoteRequestCancel(id), {});
  Future<ApiResult<dynamic>> quotations() => api.get(ApiEndpoints.quotations);
  Future<ApiResult<dynamic>> quotation(String id) => api.get(ApiEndpoints.quotation(id));
  Future<ApiResult<dynamic>> quotationView(String id) =>
      api.post(ApiEndpoints.quotationView(id), {});
  Future<ApiResult<dynamic>> quotationAccept(String id) =>
      api.post(ApiEndpoints.quotationAccept(id), {});
  Future<ApiResult<dynamic>> quotationReject(String id) =>
      api.post(ApiEndpoints.quotationReject(id), {});
  Future<ApiResult<dynamic>> productBookings() =>
      api.get(ApiEndpoints.productBookings);
  Future<ApiResult<dynamic>> cancelProductBooking(String id, [String? reason]) =>
      api.put(ApiEndpoints.productBookingCancel(id), {'reason': reason ?? 'Customer request'});
  Future<ApiResult<dynamic>> notifications() => api.get(ApiEndpoints.notifications);
  Future<ApiResult<dynamic>> unreadCount() => api.get(ApiEndpoints.notifUnreadCount);
  Future<ApiResult<dynamic>> markAllRead() => api.patch(ApiEndpoints.notifReadAll, {});
  Future<ApiResult<dynamic>> markRead(String id) => api.patch(ApiEndpoints.notifRead(id), {});
  Future<ApiResult<dynamic>> registerDevice(Map<String, dynamic> body) =>
      api.post(ApiEndpoints.deviceToken, body);
  Future<ApiResult<dynamic>> deleteDeviceToken([Map<String, dynamic>? body]) =>
      api.delete(ApiEndpoints.deviceToken, body);
  Future<ApiResult<dynamic>> updatePermissions(Map<String, dynamic> body) =>
      api.put(ApiEndpoints.permissions, body);
}
