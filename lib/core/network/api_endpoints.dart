/// Typed API endpoints derived from the Postman collection
/// "RightTouch API - Customer & User Application".
class ApiEndpoints {
  // Auth — customer OTP (primary, per backend Customer Flow)
  static const signupCustomer = '/api/user/signup/customer';
  static const signupCustomerVerify = '/api/user/signup/customer/verify-otp';
  static const loginCustomer = '/api/user/login/customer';
  static const loginCustomerVerify = '/api/user/login/customer/verify-otp';
  static const refresh = '/api/user/auth/refresh';
  static const logout = '/api/user/auth/logout';
  static const logoutAll = '/api/user/auth/logout-all';
  // Generic aliases (kept as fallback)
  static const requestOtp = '/api/user/auth/login/request-otp';
  static const verifyOtp = '/api/user/auth/login/verify-otp';
  static const acceptTerms = '/api/user/auth/accept-terms';
  static const deleteAccount = '/api/user/delete-my-account';
  static const signup = '/api/user/signup';
  static const resendOtp = '/api/user/resend-otp';
  static const verifySignupOtp = '/api/user/verify-otp';
  // Debug helper (dev backends only): does this identifier exist?
  static String debugCheckUser(String identifier) =>
      '/api/user/debug/check-user/$identifier';

  // Profile
  static const me = '/api/user/me';
  static const completeProfile = '/api/user/complete-profile';

  // Catalog
  static const allCategories = '/api/user/getAllcategory';
  static String categoryById(String id) => '/api/user/getByIdcategory/$id';
  static const allServices = '/api/user/getAllServices';
  static String serviceById(String id) => '/api/user/getServiceById/$id';

  // Products
  static const allProducts = '/api/user/getProduct';
  static String productById(String id) => '/api/user/getOneProduct/$id';

  // Booking
  static const bookingSlots = '/api/user/booking/slots';
  static const bookingSchedule = '/api/user/booking/schedule';
  static String bookingCancel(String id) => '/api/user/booking/cancel/$id';
  static const bookingReasons = '/api/user/booking/reasons';
  static const customerBookings = '/api/user/booking/getCustomerBookings';
  static String bookingById(String id) =>
      '/api/user/booking/getBookingById/$id';
  static const completedServices = '/api/user/booking/completed-services';
  static const bookAgain = '/api/user/booking/book-again';

  // Cart + checkout
  static const cartAdd = '/api/user/cart/add';
  static const myCart = '/api/user/cart/my-cart';
  static const cartUpdate = '/api/user/cart/update';
  static const cartSetSchedule = '/api/user/cart/set-schedule';
  static String cartRemove(String id) => '/api/user/cart/remove/$id';
  static const checkout = '/api/user/checkout';

  // Payments
  static const payments = '/api/user/payments';
  static const paymentsSummary = '/api/user/payments/summary';
  static String paymentDetail(String bookingId) =>
      '/api/user/payments/$bookingId';
  static String paymentReceipt(String bookingId) =>
      '/api/user/payments/$bookingId/receipt';
  static String paymentRefunds(String bookingId) =>
      '/api/user/payments/$bookingId/refunds';
  static String paymentOrder(String bookingId) =>
      '/api/user/payments/$bookingId/order';
  static String paymentRetry(String bookingId) =>
      '/api/user/payments/$bookingId/retry';
  static String cashDeclare(String bookingId) =>
      '/api/user/payments/$bookingId/cash/declare';

  // Addresses
  static const addresses = '/api/addresses';
  static const addressSearch = '/api/addresses/search';
  static const addressReverse = '/api/addresses/reverse';
  static const addressDefault = '/api/addresses/default';

  // Zones (GPS resolution + serviceability)
  static const zoneResolve = '/api/zones/resolve';
  static const zoneCheckService = '/api/zones/check-service';

  // Ratings
  static const rating = '/api/user/rating';
  static const ratings = '/api/user/ratings';
  static const myRatings = '/api/user/get-my-ratings';
  static String ratingById(String id) => '/api/user/ratings/$id';
  static String ratingByIdAlt(String id) => '/api/user/getRatingById/$id';
  static String updateRating(String id) => '/api/user/updateRating/$id';
  static String deleteRating(String id) => '/api/user/deleteRating/$id';
  static const adminRatings = '/api/user/admin/ratings';
  static const allRatings = '/api/user/getAllRatings';

  // Reports / complaints
  static const reports = '/api/user/reports';
  static const myReports = '/api/user/reports/mine';
  static const reportCategories = '/api/user/reports/categories';
  static String reportWithdraw(String id) =>
      '/api/user/reports/$id/withdraw';

  // Quotations
  static const quoteRequests = '/api/user/product-quote-requests';
  static String quoteRequestCancel(String id) =>
      '/api/user/product-quote-requests/$id/cancel';
  static const quotations = '/api/user/quotations';
  static String quotation(String id) => '/api/user/quotations/$id';
  static String quotationAccept(String id) =>
      '/api/user/quotations/$id/accept';
  static String quotationReject(String id) =>
      '/api/user/quotations/$id/decline';
  static String quotationDecline(String id) =>
      '/api/user/quotations/$id/decline';
  static String quotationView(String id) =>
      '/api/user/quotations/$id/view';
  static const productBookings = '/api/user/product-bookings';

  // Notifications
  static const notifications = '/api/user/notifications';
  static const notifUnreadCount = '/api/user/notifications/unread-count';
  static const notifReadAll = '/api/user/notifications/read-all';
  static String notifRead(String id) =>
      '/api/user/notifications/$id/read';

  // Device token & Permissions
  static const deviceToken = '/api/user/device-token';
  static const permissions = '/api/user/permissions';

  // Alternative & Additional Postman Collection Endpoints
  static String cartRemoveAlt(String id) => '/api/user/cart/removed/$id';
  static String cartItemUpdate(String id) => '/api/user/cart/$id';
  static String cartById(String id) => '/api/user/cart/$id';
  static const paymentOrderAlt = '/api/user/payment/order';
  static const paymentVerify = '/api/user/payment/verify';
  static const productQuotes = '/api/user/product-quotes';
  static String productQuote(String id) => '/api/user/product-quotes/$id';
  static String productBookingDetail(String id) => '/api/user/product-bookings/$id';
  static String productBookingCancel(String id) => '/api/user/productBookingCancel/$id';
  static String productBookingUpdate(String id) => '/api/user/productBookingUpdate/$id';
  static const bookingDeleteAll = '/api/user/booking/deleteAll';
}
