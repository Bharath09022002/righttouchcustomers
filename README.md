# RightTouch — Customer App (Flutter, Production Structure)

Home-services customer app (like your Figma: green CTA, white cards, bottom nav)
wired to **RightTouch API - Customer & User Application** (`http://localhost:7372`).

## Run

```bash
cd frontend
flutter pub get
# point at your backend (default is http://localhost:7372)
flutter run --dart-define=BASE_URL=http://localhost:7372
# Android emulator talking to host-machine backend:
flutter run --dart-define=BASE_URL=http://10.0.2.2:7372
```

## Folder structure

```
lib/
  main.dart                      # bootstrap + token cache warmup
  app.dart                       # MaterialApp.router
  core/
    config/env.dart              # BASE_URL via --dart-define
    theme/                       # AppColors + AppTheme (Figma green)
    network/                     # ApiClient (Dio+JWT), ApiEndpoints, ApiResult
    storage/token_storage.dart   # JWT (secure storage + prefs mirror)
    router/app_router.dart        # go_router + auth guard + ShellRoute tabs
    utils/                       # validators, INR/date formatting
    widgets/                     # AppButton, SectionHeader, Empty/Error, RatingStars, AppImage
  data/
    models/models.dart            # User/Category/Service/Booking/Cart/Address/Payment/Quote/Notification
    datasources/remote_gateway.dart  # ALL Postman endpoints grouped
    repositories/repositories.dart    # Auth/Catalog/Booking/Cart/Address/Payment/Support
  presentation/
    providers/providers.dart      # Riverpod: auth + catalog + bookings + cart + addresses…
    shell/main_shell.dart         # Bottom nav: Home / Bookings / Cart / Profile
    screens/
      splash, onboarding
      auth/ login (request-otp) → otp (verify-otp) → complete-profile
      home/ home, search (?search&categoryId), category, service-detail
      booking/ slot-booking (schedule), checkout, success, list, detail (cancel+rate)
      cart/ cart (my-cart/add/remove → checkout)
      payments/ list + retry order
      addresses/ list + add (GPS zone resolve/check-service)
      quotations/ list + accept/reject
      support/ notifications + reports
      profile/ profile + edit (me/PUT, delete-my-account)
    widgets/cards.dart            # CategoryTile, ServiceCard, BookingCard
```

## API coverage (Postman → code)

| Flow | Endpoint | Used in |
|---|---|---|
| OTP login | `POST /api/user/auth/login/request-otp` | `LoginScreen` |
| Verify | `POST /api/user/auth/login/verify-otp` | `OtpScreen` |
| Me / update | `GET,PUT /api/user/me` | bootstrap, `EditProfileScreen` |
| Complete profile | `POST /api/user/complete-profile` | `CompleteProfileScreen` |
| Terms / delete | `POST .../accept-terms`, `DELETE .../delete-my-account` | gateway + profile |
| Categories | `GET /api/user/getAllcategory` | Home horizontal list |
| Services | `GET /api/user/getAllServices?search&categoryId` | Home/Search/Category |
| Service detail | `GET /api/user/getServiceById/:id` | `ServiceDetailScreen` |
| Slots / schedule | `GET .../booking/slots`, `POST .../booking/schedule` | `SlotBookingScreen` |
| My bookings / cancel | `GET .../getCustomerBookings`, `PUT .../cancel/:id`, `GET .../reasons` | Bookings + detail |
| Rebook / completed | `POST .../book-again`, `GET .../completed-services` | gateway ready |
| Cart | `POST .../cart/add`, `GET .../my-cart`, `PUT .../update`, `DELETE .../remove/:id` | Cart + service cards |
| Checkout | `POST /api/user/checkout` | `CheckoutScreen` |
| Payments | `GET /api/user/payments`, `/summary`, `POST :id/order`, `POST :id/retry` | `PaymentsScreen` |
| Addresses | `GET/POST/PUT/DELETE /api/addresses`, `/default`, `/search`, `/reverse` | Addresses screens |
| Zones | `POST /api/zones/resolve`, `/check-service` | Add-address serviceability |
| Ratings | `POST /api/user/rating`, `GET .../get-my-ratings` | Booking detail rate sheet |
| Reports | `POST /api/user/reports`, `GET .../mine`, `/categories` | `ReportsScreen` |
| Quotes | `GET /api/user/quotations`, `POST :id/accept|reject|view` | `QuotationsScreen` |
| Notifications | `GET /api/user/notifications`, `PATCH :id/read`, `/read-all` | `NotificationsScreen` |
| Device token | `POST /api/user/device-token` | `registerDevice()` ready |

Backend envelope `{status, data}` is unwrapped centrally in `ApiClient`.
Auth header `Bearer <customerToken>` is injected automatically.
