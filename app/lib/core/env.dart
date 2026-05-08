/// App-wide environment / build configuration.
///
/// Override these from the command line, e.g.:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
///
/// Defaults are tuned for the typical local-dev setup:
/// - Android emulator → http://10.0.2.2:4000/api
/// - iOS simulator   → http://localhost:4000/api
class AppEnv {
  const AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  static const String appName = 'ASMC Workforce';
}
