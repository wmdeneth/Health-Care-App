/// Application configuration and constants
class AppConfig {
  // App Info
  static const String appName = 'VitaTrack';
  static const String appVersion = '1.0.0';

  // Health Goals
  static const int dailyWaterGoalMl = 2000;
  static const int waterIncrementMl = 250;
  static const int dailyStepGoal = 10000;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cacheExpiration = Duration(hours: 1);
}
