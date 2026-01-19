import 'package:testapp3/models/meal_tip.dart';

/// Home screen states
abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final int currentWaterMl;
  final int dailyWaterGoal;
  final int todaySteps;
  final int dailyStepGoal;
  final bool hasActivityPermission;
  final String? waterReminderHint;
  final MealTip? dailyTip;

  const HomeLoaded({
    required this.currentWaterMl,
    required this.dailyWaterGoal,
    required this.todaySteps,
    required this.dailyStepGoal,
    required this.hasActivityPermission,
    this.waterReminderHint,
    this.dailyTip,
  });

  HomeLoaded copyWith({
    int? currentWaterMl,
    int? dailyWaterGoal,
    int? todaySteps,
    int? dailyStepGoal,
    bool? hasActivityPermission,
    String? waterReminderHint,
    MealTip? dailyTip,
  }) {
    return HomeLoaded(
      currentWaterMl: currentWaterMl ?? this.currentWaterMl,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      todaySteps: todaySteps ?? this.todaySteps,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      hasActivityPermission:
          hasActivityPermission ?? this.hasActivityPermission,
      waterReminderHint: waterReminderHint ?? this.waterReminderHint,
      dailyTip: dailyTip ?? this.dailyTip,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);
}

class PermissionGranted extends HomeState {
  const PermissionGranted();
}

class PermissionDenied extends HomeState {
  const PermissionDenied();
}
