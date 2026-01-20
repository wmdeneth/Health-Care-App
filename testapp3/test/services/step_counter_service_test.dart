import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testapp3/services/step_counter_service.dart';

// Attempt to use StepCount directly. If this fails, we stick to Fake.
// Assuming constructor is StepCount({required int steps, required DateTime timeStamp}) or similar.
// Since we can't see source, we try Reflection/Fake approach which is safer generally,
// but let's try to make a Mock that is robust.

class MockStepCount implements StepCount {
  final int _steps;
  final DateTime _timeStamp;

  MockStepCount(this._steps, this._timeStamp);

  @override
  int get steps => _steps;

  @override
  DateTime get timeStamp => _timeStamp;

  @override
  String toString() => 'Steps: $_steps';
}

class MockPedestrianStatus implements PedestrianStatus {
  final String _status;
  final DateTime _timeStamp;
  MockPedestrianStatus(this._status, this._timeStamp);
  @override
  String get status => _status;
  @override
  DateTime get timeStamp => _timeStamp;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Define variables
  StepCounterService? service;
  StreamController<StepCount>? stepStreamController;
  StreamController<PedestrianStatus>? statusStreamController;

  setUp(() async {
    // Reset SharedPrefs
    SharedPreferences.setMockInitialValues({});

    // Initialize Service (Singleton)
    service = StepCounterService();

    // Reset internal state
    await service!.resetForTesting();

    // Initialize Controllers
    stepStreamController = StreamController<StepCount>.broadcast();
    statusStreamController = StreamController<PedestrianStatus>.broadcast();

    // Inject Mocks
    service!.stepCountStreamOverride = stepStreamController!.stream;
    service!.pedestrianStatusStreamOverride = statusStreamController!.stream;
  });

  tearDown(() async {
    await stepStreamController?.close();
    await statusStreamController?.close();
    service = null;
  });

  test('Initializes with 0 steps', () async {
    await service!.initStepCounter();
    expect(service!.getCurrentSteps(), 0);
  });

  test('Establishes baseline', () async {
    await service!.initStepCounter();
    stepStreamController!.add(MockStepCount(1000, DateTime.now()));
    await Future.delayed(Duration.zero);
    expect(service!.getCurrentSteps(), 0);
  });

  test('Increments steps', () async {
    await service!.initStepCounter();

    // Baseline
    stepStreamController!.add(MockStepCount(1000, DateTime.now()));
    await Future.delayed(Duration.zero);

    // Increment
    stepStreamController!.add(MockStepCount(1050, DateTime.now()));
    await Future.delayed(Duration.zero);

    expect(service!.getCurrentSteps(), 50);
  });

  test('Reboot handling (count decreases)', () async {
    await service!.initStepCounter();

    // Baseline
    stepStreamController!.add(MockStepCount(1000, DateTime.now()));
    await Future.delayed(Duration.zero);

    // +50
    stepStreamController!.add(MockStepCount(1050, DateTime.now()));
    await Future.delayed(Duration.zero);
    expect(service!.getCurrentSteps(), 50);

    // Reboot -> 10
    stepStreamController!.add(MockStepCount(10, DateTime.now()));
    await Future.delayed(Duration.zero);

    // 50 (stored) + 10 (new delta) = 60
    expect(service!.getCurrentSteps(), 60);
  });

  test('New Day Reset', () async {
    // Set old date in prefs
    SharedPreferences.setMockInitialValues({
      'today_steps': 500,
      'last_sensor_reading': 5000,
      'last_saved_date': '2000-01-01',
    });

    await service!.initStepCounter();

    // Should reset to 0 immediately
    expect(service!.getCurrentSteps(), 0);

    // New step event
    stepStreamController!.add(MockStepCount(5050, DateTime.now()));
    await Future.delayed(Duration.zero);

    // Logic: lastSensorReading 5000 (from prefs). New 5050. Delta 50.
    // Reset happened, so 0 + 50 = 50.
    expect(service!.getCurrentSteps(), 50);
  });
}
