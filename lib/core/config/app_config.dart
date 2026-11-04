class AppConfig {
  static const String appName = 'Message Pro';
  static const String appSlug = 'message-pro';
  static const String appVersion = '1.0.7';
  static const int buildNumber = 10;

  static const String defaultBaseUrl = 'http://api.message-pro.com';
  static const String defaultWebSocketUrl = 'wss://omni.message-pro.com/cable';
  static const String clientName = 'Message Pro Mobile';

  // API prefix rules
  static const List<String> nonAccountRoutes = [
    'profile',
    'profile/availability',
    'profile/set_active_account',
    'notification_subscriptions',
    'support',
  ];

  static const List<String> authRoutes = [
    'auth/sign_in',
    'auth/validate_token',
    'auth/sign_out',
    'auth/password',
  ];
}
