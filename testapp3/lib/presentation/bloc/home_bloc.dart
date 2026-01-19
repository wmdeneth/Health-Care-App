import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/app_config.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC for managing home screen state and logic
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  int _currentWaterMl = 0;
  String? _waterReminderHint;

  HomeBloc() : super(const HomeInitial()) {
    on<InitializeHomeEvent>(_onInitializeHome);
    on<LoadUserDataEvent>(_onLoadUserData);
    on<UpdateWaterIntakeEvent>(_onUpdateWaterIntake);
    on<CheckPermissionsEvent>(_onCheckPermissions);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<RefreshDataEvent>(_onRefreshData);
  }

  Future<void> _onInitializeHome(
    InitializeHomeEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      await _checkPermissions();
      await _loadUserData();
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
      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onUpdateWaterIntake(
    UpdateWaterIntakeEvent event,
    Emitter<HomeState> emit,
  ) async {
    _currentWaterMl += event.mlAmount;
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
      if (status.isGranted) {
        emit(const PermissionGranted());
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
      _emitLoadedState(emit);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _checkPermissions() async {
    // Permission status check is handled by RequestPermissionEvent
    // This is called during initialization but actual permission handling
    // is done through the RequestPermissionEvent handler
  }

  Future<void> _loadUserData() async {
    // Load water reminder preference
    // This would typically come from a service
  }

  void _emitLoadedState(Emitter<HomeState> emit) {
    // Permission checks should be done via RequestPermissionEvent for proper async handling
    final hasActivityPermission = false;
    emit(
      HomeLoaded(
        currentWaterMl: _currentWaterMl,
        dailyWaterGoal: AppConfig.dailyWaterGoalMl,
        todaySteps: 0, // This would come from step service
        dailyStepGoal: AppConfig.dailyStepGoal,
        hasActivityPermission: hasActivityPermission,
        waterReminderHint: _waterReminderHint,
      ),
    );
  }
}
