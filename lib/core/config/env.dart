// Central environment / flavor config.
// LIVE backend is the default. Override per-run with:
//   flutter run --dart-define=BASE_URL=https://your-host
class Env {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://righttouchservernew-727889857503.asia-south1.run.app',
  );
  static const String appName = 'RightTouch';
  static const String currencySymbol = '₹';

  /// First request gets a generous timeout for Render cold-start.
  static const Duration coldStartTimeout = Duration(seconds: 60);

  /// Normal requests after the backend is warm.
  static const Duration connectTimeout = Duration(seconds: 25);
  static const Duration receiveTimeout = Duration(seconds: 25);

  /// Threshold for showing "server waking up" message.
  static const Duration wakeUpThreshold = Duration(seconds: 8);
}