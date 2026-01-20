import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testapp3/services/notification_service.dart';
import 'package:testapp3/services/water_history_service.dart';
import 'package:testapp3/models/water_log.dart';
import 'package:testapp3/models/step_data.dart';

import '../../config/app_config.dart';
import '../../services/step_counter_service.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC for managing home screen state and logic
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final StepCounterService _stepCounterService = StepCounterService();
  final WaterHistoryService _waterHistoryService = WaterHistoryService.instance;

  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<List<WaterLog>>? _historySubscription;

  int _currentWaterMl = 0;
  int _dailyWaterGoal = AppConfig.dailyWaterGoalMl;
  String? _waterReminderHint;
  int _todaySteps = 0;
  bool _hasActivityPermission = false;
  double? _bmi;
  String? _bmiStatus;
  List<WaterLog> _waterHistory = [];
  List<StepData> _stepHistory = [];

  HomeBloc() : super(const HomeInitial()) {
    on<InitializeHomeEvent>(_onInitializeHome);
    on<LoadUserDataEvent>(_onLoadUserData);
    on<UpdateWaterIntakeEvent>(_onUpdateWaterIntake);
    on<CheckPermissionsEvent>(_onCheckPermissions);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<RefreshDataEvent>(_onRefreshData);
    on<WaterHistoryUpdatedEvent>(_onWaterHistoryUpdated);
  }

  @override
  Future<void> close() {
    _stepSubscription?.cancel();
    _userSubscription?.cancel();
    _historySubscription?.cancel();
    return super.close();
  }

  Future<void> _onInitializeHome(
    InitializeHomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      await _checkPermissions();
      await _loadUserData();

      // Initialize step service and listen to changes
      await _stepCounterService.initStepCounter();
      _stepSubscription?.cancel();
      _stepSubscription = _stepCounterService.getTodayStepsStream().listen((
        steps,
      ) {
        add(const LoadUserDataEvent());
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Listen to user data changes
        _userSubscription?.cancel();
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((snapshot) {
              add(const LoadUserDataEvent());
            });

        // Listen to water history changes
        _historySubscription?.cancel();
        _historySubscription = _waterHistoryService
            .getWaterHistoryStream()
            .listen((history) {
              add(WaterHistoryUpdatedEvent(history));
            });
      }

      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadUserData(
    LoadUserDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _loadUserData();
      _todaySteps = await _stepCounterService.getTodaySteps();
      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onUpdateWaterIntake(
    UpdateWaterIntakeEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Pessimistic or Optimistic? Let's go with immediate backend call.
    // The snapshot listener will update the UI automatically.
    await _waterHistoryService.addWater(event.mlAmount);
  }

  void _onWaterHistoryUpdated(
    WaterHistoryUpdatedEvent event,
    Emitter<HomeState> emit,
  ) {
    _waterHistory = event.history;
    _emitLoadedState(emit);
  }

  Future<void> _onCheckPermissions(
    CheckPermissionsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _checkPermissions();
      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final status = await Permission.activityRecognition.request();
      _hasActivityPermission = status.isGranted;

      if (_hasActivityPermission) {
        emit(const PermissionGranted());
        await _stepCounterService.initStepCounter();
      } else {
        emit(const PermissionDenied());
      }
      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onRefreshData(
    RefreshDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _loadUserData();
      await _checkPermissions();
      _todaySteps = await _stepCounterService.getTodaySteps();
      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.activityRecognition.status;
    _hasActivityPermission = status.isGranted;
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data() ?? <String, dynamic>{};

      _currentWaterMl = (data['currentIntake'] as num?)?.toInt() ?? 0;
      final newGoal = (data['dailyWaterGoal'] as num?)?.toInt();

      if (newGoal != null && newGoal != _dailyWaterGoal) {
        _dailyWaterGoal = newGoal;
        scheduleDailyHydrationReminders();
      }

      final weightKg = (data['weightKg'] as num?)?.toDouble();
      final heightCm = (data['heightCm'] as num?)?.toDouble();

      if (weightKg != null && heightCm != null && heightCm > 0) {
        final heightM = heightCm / 100.0;
        _bmi = weightKg / (heightM * heightM);

        if (_bmi! < 18.5) {
          _bmiStatus = 'Underweight';
        } else if (_bmi! < 25) {
          _bmiStatus = 'Normal';
        } else if (_bmi! < 30) {
          _bmiStatus = 'Overweight';
        } else {
          _bmiStatus = 'Obese';
        }
      } else {
        _bmi = null;
        _bmiStatus = null;
      }

      // Fetch step history
      _stepHistory = await _stepCounterService.getLast7DaysSteps();
    } catch (e) {
      // Error logging could go here
    }
  }

  void _emitLoadedState(Emitter<HomeState> emit) {
    emit(
      HomeLoaded(
        currentWaterMl: _currentWaterMl,
        dailyWaterGoal: _dailyWaterGoal,
        todaySteps: _todaySteps,
        dailyStepGoal: AppConfig.dailyStepGoal,
        hasActivityPermission: _hasActivityPermission,
        waterReminderHint: _waterReminderHint,
        bmi: _bmi,
        bmiStatus: _bmiStatus,
        waterHistory: _waterHistory,
        stepHistory: _stepHistory,
      ),
    );
  }
}
