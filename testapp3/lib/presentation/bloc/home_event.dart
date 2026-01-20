import '../../models/water_log.dart';

/// Home screen events
abstract class HomeEvent {
  const HomeEvent();
}

class InitializeHomeEvent extends HomeEvent {
  const InitializeHomeEvent();
}

class LoadUserDataEvent extends HomeEvent {
  const LoadUserDataEvent();
}

class UpdateWaterIntakeEvent extends HomeEvent {
  final int mlAmount;

  const UpdateWaterIntakeEvent(this.mlAmount);
}

class CheckPermissionsEvent extends HomeEvent {
  const CheckPermissionsEvent();
}

class RequestPermissionEvent extends HomeEvent {
  const RequestPermissionEvent();
}

class RefreshDataEvent extends HomeEvent {
  const RefreshDataEvent();
}

class WaterHistoryUpdatedEvent extends HomeEvent {
  final List<WaterLog> history;
  const WaterHistoryUpdatedEvent(this.history);
}
