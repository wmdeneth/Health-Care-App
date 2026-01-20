import '../../models/meal_tip.dart';
import '../../models/water_log.dart';
import '../../models/step_data.dart';

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
  final double? bmi;
  final String? bmiStatus;
  final List<WaterLog> waterHistory;
  final List<StepData> stepHistory;

  const HomeLoaded({
    required this.currentWaterMl,
    required this.dailyWaterGoal,
    required this.todaySteps,
    required this.dailyStepGoal,
    required this.hasActivityPermission,
    this.waterReminderHint,
    this.dailyTip,
    this.bmi,
    this.bmiStatus,
    this.waterHistory = const [],
    this.stepHistory = const [],
  });

  HomeLoaded copyWith({
    int? currentWaterMl,
    int? dailyWaterGoal,
    int? todaySteps,
    int? dailyStepGoal,
    bool? hasActivityPermission,
    String? waterReminderHint,
    MealTip? dailyTip,
    double? bmi,
    String? bmiStatus,
    List<WaterLog>? waterHistory,
    List<StepData>? stepHistory,
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
      bmi: bmi ?? this.bmi,
      bmiStatus: bmiStatus ?? this.bmiStatus,
      waterHistory: waterHistory ?? this.waterHistory,
      stepHistory: stepHistory ?? this.stepHistory,
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
