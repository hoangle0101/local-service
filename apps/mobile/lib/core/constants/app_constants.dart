class AppConstants {
  // API base URL for emulator (10.0.2.2)
  // Change to your computer's local IP (e.g., 192.168.1.5) for physical device testing
  // static const String apiBaseUrl = 'http://172.26.18.193:3000';
  static const String apiBaseUrl = 'http://172.26.18.193:3000';
  // Socket URL (usually same as base URL for Socket.IO)
  static const String socketUrl = apiBaseUrl;

  // Other constants can be added here
  static const String appName = 'Local Service Platform';
}
