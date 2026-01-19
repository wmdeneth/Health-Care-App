# VitaTrack - Code Style & Best Practices Guide

## File Organization

### Naming Conventions

**Files**: `snake_case.dart`
```
✅ home_page.dart
✅ user_profile_service.dart
❌ HomePage.dart
❌ userProfileService.dart
```

**Classes**: `PascalCase`
```dart
✅ class HomePage extends StatelessWidget {}
✅ class UserProfileService {}
❌ class home_page extends StatelessWidget {}
```

**Variables & Methods**: `camelCase`
```dart
✅ int currentWaterMl;
✅ void updateUserProfile() {}
❌ int CurrentWaterMl;
❌ void UpdateUserProfile() {}
```

**Constants**: `UPPER_SNAKE_CASE` (if truly constant) or `camelCase` (if configurable)
```dart
✅ static const int dailyWaterGoal = 2000;
✅ static const String appName = 'VitaTrack';
❌ static const int DAILY_WATER_GOAL = 2000;
```

## Code Structure

### Import Organization

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports (alphabetical)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Relative imports (alphabetical)
import '../config/app_config.dart';
import '../presentation/bloc/index.dart';
import './widgets/common/index.dart';
```

### Class Structure

```dart
class HomePage extends StatefulWidget {
  // 1. Final properties (const required)
  final String title;
  
  // 2. Constructor with const
  const HomePage({
    super.key,
    required this.title,
  });

  // 3. State creation
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. Static constants
  static const int _timeout = 30;
  
  // 2. Instance variables (private with _)
  late StreamSubscription _subscription;
  int _currentWaterMl = 0;
  
  // 3. Lifecycle methods
  @override
  void initState() {
    super.initState();
    // Initialize
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // 4. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }

  // 5. Private helper methods
  void _loadData() {}
  Widget _buildHeader() {}
}
```

## BLoC Pattern

### Events

```dart
// ✅ Good - Clear, specific events
abstract class HomeEvent {
  const HomeEvent();
}

class LoadHomeDataEvent extends HomeEvent {
  const LoadHomeDataEvent();
}

class UpdateWaterIntakeEvent extends HomeEvent {
  final int mlAmount;
  const UpdateWaterIntakeEvent(this.mlAmount);
}

// ❌ Avoid - Generic events
class GenericUpdateEvent extends HomeEvent {
  final Map<String, dynamic> data;
}
```

### States

```dart
// ✅ Good - Use copyWith for modifications
class HomeLoaded extends HomeState {
  final int currentWaterMl;
  final int todaySteps;

  const HomeLoaded({
    required this.currentWaterMl,
    required this.todaySteps,
  });

  HomeLoaded copyWith({
    int? currentWaterMl,
    int? todaySteps,
  }) {
    return HomeLoaded(
      currentWaterMl: currentWaterMl ?? this.currentWaterMl,
      todaySteps: todaySteps ?? this.todaySteps,
    );
  }
}

// ❌ Avoid - Mutable state
class HomeData extends HomeState {
  int currentWaterMl;
  int todaySteps;
}
```

### BLoC Event Handlers

```dart
// ✅ Good - Separate methods for each event
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadData);
    on<UpdateWaterEvent>(_onUpdateWater);
  }

  Future<void> _onLoadData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      // Load data
      emit(const HomeLoaded(...));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onUpdateWater(
    UpdateWaterEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Handle water update
  }
}
```

## Widget Best Practices

### Size & Simplicity

```dart
// ✅ Good - Small, focused widget (~100 lines max)
class WaterIntakeCard extends StatelessWidget {
  final int currentMl;
  final int goalMl;

  const WaterIntakeCard({
    super.key,
    required this.currentMl,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentMl / goalMl * 100).toInt();
    return GradientCard(
      child: Column(
        children: [
          Text('$currentMl / $goalMl ml'),
          LinearProgressIndicator(value: currentMl / goalMl),
          Text('$percentage% complete'),
        ],
      ),
    );
  }
}

// ❌ Avoid - Large, mixed-responsibility widget
class HomeScreenWidget extends StatefulWidget {
  // Mixes data loading, theming, navigation, and UI
  // Hard to test, hard to reuse
}
```

### Composition over Inheritance

```dart
// ✅ Good - Compose widgets
class ProfileCard extends StatelessWidget {
  final User user;

  const ProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      child: Column(
        children: [
          ProfileImage(url: user.photoUrl),
          ProfileName(name: user.name),
          ProfileEmail(email: user.email),
        ],
      ),
    );
  }
}

// ❌ Avoid - Complex inheritance chains
class BaseCard extends StatelessWidget { ... }
class UserCard extends BaseCard { ... }
class AdvancedUserCard extends UserCard { ... }
```

## Theme Usage

### Colors

```dart
// ✅ Good - Use theme colors
Container(
  color: AppTheme.primaryColor,
  child: Text('Hello', style: TextStyle(color: Colors.white)),
)

// ❌ Avoid - Magic color values
Container(
  color: const Color(0xFF00D4FF),
  child: Text('Hello', style: TextStyle(color: const Color(0xFFFFFFFF))),
)
```

### Text Styles

```dart
// ✅ Good - Use theme text styles
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.bold,
  ),
)

// ❌ Avoid - Custom text styles everywhere
Text(
  'Title',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)
```

## Error Handling

### Try-Catch Pattern

```dart
// ✅ Good - Specific error handling
try {
  final data = await firestore.loadUserData();
  emit(DataLoaded(data));
} on FirebaseException catch (e) {
  emit(DataError('Firebase error: ${e.message}'));
} on TimeoutException {
  emit(const DataError('Request timed out'));
} catch (e) {
  emit(DataError('Unknown error: $e'));
}

// ❌ Avoid - Broad catch-all
try {
  final data = await firestore.loadUserData();
  emit(DataLoaded(data));
} catch (_) {
  emit(const DataError('Something went wrong'));
}
```

## Async Operations

### Futures & Streams

```dart
// ✅ Good - Proper async handling
Future<UserData> loadUserData() async {
  try {
    final snapshot = await firestore
      .collection('users')
      .doc(userId)
      .get();
    return UserData.fromMap(snapshot.data()!);
  } catch (e) {
    rethrow;
  }
}

// ✅ Good - Stream builders
StreamBuilder<int>(
  stream: stepService.getTodayStepsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Steps: ${snapshot.data}');
    }
    return const CircularProgressIndicator();
  },
)

// ❌ Avoid - Fire and forget
loadUserData(); // No await, no error handling

// ❌ Avoid - Not handling connection states
StreamBuilder<int>(
  stream: stepService.getTodayStepsStream(),
  builder: (context, snapshot) {
    return Text('Steps: ${snapshot.data ?? 0}');
  },
)
```

## Comments & Documentation

```dart
// ✅ Good - Meaningful comments
/// Loads user profile from Firestore and updates the UI state.
/// 
/// Emits [HomeLoading] while fetching data, then [HomeLoaded] or [HomeError].
/// Throws [FirebaseException] if Firestore is unavailable.
Future<void> loadUserProfile() async { ... }

// Recalculate water intake percentage (must handle edge case of 0 goal)
final percentage = goalMl > 0 ? (currentMl / goalMl * 100).toInt() : 0;

// ❌ Avoid - Redundant comments
int waterMl = 2000; // Set water to 2000

// ❌ Avoid - Commented out code
// int oldWater = 0;
// void oldMethod() { }

// ❌ Avoid - Obvious comments
// Check if list is empty
if (items.isEmpty) { }
```

## Constants Placement

```dart
// ✅ Good - Centralized constants
// config/app_config.dart
class AppConfig {
  static const int dailyWaterGoal = 2000;
  static const int dailyStepGoal = 10000;
  static const Duration networkTimeout = Duration(seconds: 30);
}

// Usage in widgets
const goal = AppConfig.dailyWaterGoal;

// ❌ Avoid - Scattered magic numbers
const int goal = 2000;
const int goal2 = 10000;
if (water > 2000) { } // Different reference

// ❌ Avoid - Hardcoded values in widgets
LinearProgressIndicator(value: currentMl / 2000.0)
```

## Testing Patterns

### Widget Tests

```dart
// ✅ Good
testWidgets('HomePage displays welcome message', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: HomePage()),
  );
  
  expect(find.text('Welcome back!'), findsOneWidget);
  expect(find.byType(WaterCard), findsOneWidget);
});

// ✅ Good - BLoC testing
blocTest<HomeBloc, HomeState>(
  'emits [HomeLoading, HomeLoaded] when data loads',
  build: () => HomeBloc(),
  act: (bloc) => bloc.add(const LoadHomeDataEvent()),
  expect: () => [
    const HomeLoading(),
    isA<HomeLoaded>(),
  ],
);
```

## Performance Tips

```dart
// ✅ Good - Const constructors
const widget = const MyWidget();
const color = Color(0xFF00D4FF);

// ✅ Good - Lazy loading
ListView.builder(
  itemCount: 100,
  itemBuilder: (context, index) => ItemTile(index),
)

// ✅ Good - Keys for dynamic lists
ListView(
  children: items.map((item) => 
    MyTile(key: ValueKey(item.id), item: item),
  ).toList(),
)

// ❌ Avoid - Rebuilding expensive widgets
if (condition) RenderExpensiveWidget() else SizedBox.shrink()

// ✅ Better
condition ? const RenderExpensiveWidget() : const SizedBox.shrink()
```

## Null Safety

```dart
// ✅ Good - Handle nulls explicitly
String getName(User? user) {
  return user?.name ?? 'Unknown User';
}

// ✅ Good - Use ! only when certain
final user = FirebaseAuth.instance.currentUser!;

// ✅ Good - Late initialization
late final Database database;

// ❌ Avoid - Ignoring nulls
String getName(User? user) => user.name; // Runtime error

// ❌ Avoid - Unnecessary !
final name = user?.name ?? 'Unknown';
final finalName = name!; // name is never null
```

---

**Remember**: Consistency is key! Follow these patterns across your codebase for better maintainability and collaboration.
