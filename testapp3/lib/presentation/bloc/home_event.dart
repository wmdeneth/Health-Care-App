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
