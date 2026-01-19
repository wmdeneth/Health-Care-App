# Modern Flutter App Architecture Guide

## Overview

This Flutter application follows **Clean Architecture** principles combined with **BLoC pattern** for state management. The structure is designed for scalability, maintainability, and testability.

## Directory Structure

```
lib/
├── config/                          # App configuration & theme
│   ├── app_config.dart             # Constants and configuration
│   ├── routes.dart                 # Type-safe routing definitions
│   └── theme.dart                  # Centralized theme configuration
│
├── core/                            # Core utilities & helpers
│   └── utils/
│       ├── color_utils.dart        # Color manipulation utilities
│       ├── extensions.dart         # Dart & Flutter extensions
│       └── validators.dart         # Input validation (future)
│
├── data/                            # Data layer (repositories & datasources)
│   ├── repositories/               # Repository implementations
│   └── datasources/                # Local & remote data sources
│
├── domain/                          # Domain layer (entities & use cases)
│   ├── entities/                   # Business logic entities
│   └── usecases/                   # Use case implementations
│
├── presentation/                    # Presentation layer (UI & state management)
│   ├── bloc/                       # BLoC state management
│   │   ├── home_bloc.dart
│   │   ├── home_event.dart
│   │   └── home_state.dart
│   ├── pages/                      # Full-screen pages/routes
│   │   └── home_page.dart
│   └── widgets/                    # Reusable UI components
│       └── common/                 # Common/shared widgets
│
├── screens/                         # (Legacy) Existing screen implementations
├── models/                          # (Legacy) Data models
├── services/                        # (Legacy) Business logic services
└── main.dart                        # Application entry point
```

## Architecture Layers

### 1. **Config Layer** (`lib/config/`)
- **Purpose**: Centralized configuration, constants, and theme
- **Responsibilities**:
  - App-wide constants (goals, timeouts)
  - Type-safe route definitions
  - Centralized theme configuration
  - Color palette management

**Key Files**:
- `app_config.dart` - Constants like daily water goal, step goal
- `theme.dart` - Dark theme with Material 3
- `routes.dart` - Typed route constants

### 2. **Core Layer** (`lib/core/`)
- **Purpose**: Shared utilities and extensions
- **Responsibilities**:
  - Utility functions (color manipulation)
  - Extension methods for common types
  - Global helper functions

**Key Files**:
- `utils/color_utils.dart` - Hex to Color conversion
- `utils/extensions.dart` - Context, DateTime extensions

### 3. **Data Layer** (`lib/data/`)
- **Purpose**: Handle all data operations
- **Responsibilities**:
  - Fetch data from Firebase/local storage
  - Transform external data formats
  - Implement repositories

**Structure**:
- `repositories/` - Implements domain interfaces
- `datasources/` - External API/database calls

### 4. **Domain Layer** (`lib/domain/`)
- **Purpose**: Business logic and use cases
- **Responsibilities**:
  - Define entity models
  - Implement use cases
  - No framework/platform-specific code

**Structure**:
- `entities/` - Business logic models
- `usecases/` - Application business rules

### 5. **Presentation Layer** (`lib/presentation/`)
- **Purpose**: UI and state management
- **Responsibilities**:
  - Display UI components
  - Handle user interactions
  - Manage local UI state via BLoC

**Structure**:
- `bloc/` - BLoC for state management (HomeBloc, etc.)
- `pages/` - Full-screen pages (HomePage, ProfilePage)
- `widgets/common/` - Reusable UI components

## State Management with BLoC

### What is BLoC?

**BLoC** (Business Logic Component) separates business logic from UI:
- **Events**: User actions sent to BLoC
- **State**: UI state emitted by BLoC
- **Bloc**: Handles events and emits states

### Example Flow:

```
User Action → Event → BLoC → New State → UI Update
     (tap)  (InitializeHomeEvent) (HomeBloc) (HomeLoaded) (rebuild)
```

### Home BLoC Structure:

```dart
// Events - what can happen
abstract class HomeEvent {}
class InitializeHomeEvent extends HomeEvent {}
class UpdateWaterIntakeEvent extends HomeEvent {}

// States - what the UI can show
abstract class HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final int currentWaterMl;
  final int todaySteps;
  // ... other properties
}

// BLoC - handles events, emits states
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<InitializeHomeEvent>(_onInitializeHome);
    on<UpdateWaterIntakeEvent>(_onUpdateWaterIntake);
  }
}
```

## Reusable Widgets

Located in `lib/presentation/widgets/common/`:

- **`LoadingOverlay`** - Shows loading indicator with optional message
- **`ErrorWidget`** - Displays error with retry button
- **`CustomAppBar`** - Centralized app bar configuration
- **`GradientCard`** - Card with customizable gradient
- **`SectionHeader`** - Section titles with optional trailing action

### Usage Example:

```dart
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) {
    return switch (state) {
      HomeLoading() => const Center(child: CircularProgressIndicator()),
      HomeLoaded() => _buildContent(context, state),
      HomeError(message: final error) => ErrorWidget(message: error),
    };
  },
);
```

## Routing (Type-Safe)

Instead of magic strings, use the `Routes` class:

```dart
// ❌ Avoid
Navigator.pushNamed(context, '/home');

// ✅ Prefer
Navigator.pushNamed(context, Routes.home);
```

Define new routes in `lib/config/routes.dart`:

```dart
class Routes {
  static const String home = '/home';
  static const String profile = '/profile';
  // Add new routes here
}
```

## Theme Configuration

All theme settings are in `lib/config/theme.dart`:

```dart
class AppTheme {
  static const Color primaryColor = Color(0xFF00D4FF);
  static const Color backgroundColor = Color(0xFF0B0E11);
  
  static ThemeData darkTheme(BuildContext context) {
    // Material 3 theme configuration
  }
}
```

## Best Practices

### 1. **Use BLoC for Complex State**
- Multi-step operations
- Data that affects multiple screens
- Scenarios with loading, error, success states

### 2. **Keep Widgets Small**
- Extract reusable pieces into separate widgets
- Max ~200 lines per widget class
- Use composition over large monolithic widgets

### 3. **Centralize Configuration**
- Colors → `config/theme.dart`
- Routes → `config/routes.dart`
- Constants → `config/app_config.dart`

### 4. **Use Extensions for DRY Code**
```dart
// Instead of
MediaQuery.of(context).size.width

// Use
context.screenWidth
```

### 5. **Handle Loading & Error States**
```dart
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) => state.maybeWhen(
    loading: () => LoadingOverlay(...),
    error: (msg) => ErrorWidget(message: msg),
    loaded: (data) => _buildContent(data),
    orElse: () => SizedBox.shrink(),
  ),
);
```

## Migration from Old Structure

### Old Approach
- Mixed UI and business logic in screens
- Manual state management with setState
- Magic route strings

### New Approach
- Clean separation of concerns
- Predictable state management via BLoC
- Type-safe routing

**Gradual Migration Path**:
1. Create new features using BLoC + clean architecture
2. Keep existing screens as-is
3. Gradually refactor legacy screens when needed
4. Share common utilities and widgets across both

## Testing Strategy

### Unit Tests (Domain & BLoC)
```dart
test('HomeBloc emits [HomeLoading, HomeLoaded] when data loads', () async {
  // Test BLoC state transitions
});
```

### Widget Tests (Presentation)
```dart
testWidgets('HomePage displays correct UI', (tester) async {
  // Test UI rendering and interactions
});
```

### Integration Tests (Full app flow)
```dart
testWidgets('User can navigate through app', (tester) async {
  // Test complete user journeys
});
```

## Key Improvements in New Architecture

✅ **Scalability** - Easy to add new features
✅ **Testability** - Separate, testable layers
✅ **Maintainability** - Clear code organization
✅ **Type Safety** - Typed routes, events, states
✅ **Code Reuse** - Common widgets & utilities
✅ **Performance** - Efficient state management with BLoC
✅ **Consistency** - Unified theme and styling

## Next Steps

1. **Add more BLoCs** - Auth, Profile, Notifications
2. **Implement repositories** - Data layer for Firebase operations
3. **Create use cases** - Domain layer business logic
4. **Add tests** - Unit, widget, and integration tests
5. **Refactor legacy screens** - Use HomePage pattern for other screens

## Resources

- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
- [Flutter State Management Guide](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)
- [Material 3 Design System](https://m3.material.io/)
