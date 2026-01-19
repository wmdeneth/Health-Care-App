# 🚀 VitaTrack - Quick Reference Guide

## File Quick Access

| Need | File | Purpose |
|------|------|---------|
| **App constants** | `lib/config/app_config.dart` | Water goal, step goal, timeouts |
| **App theme** | `lib/config/theme.dart` | Colors, fonts, Material 3 |
| **Routes** | `lib/config/routes.dart` | Type-safe navigation |
| **Color helpers** | `lib/core/utils/color_utils.dart` | Hex to Color conversion |
| **Extensions** | `lib/core/utils/extensions.dart` | Context, DateTime helpers |
| **Home events** | `lib/presentation/bloc/home_event.dart` | User actions |
| **Home states** | `lib/presentation/bloc/home_state.dart` | UI states |
| **Home logic** | `lib/presentation/bloc/home_bloc.dart` | Business logic |
| **Home page** | `lib/presentation/pages/home_page.dart` | Modern homepage |
| **Loading UI** | `lib/presentation/widgets/common/loading_overlay.dart` | Reusable loading |
| **Error UI** | `lib/presentation/widgets/common/error_widget.dart` | Reusable error |
| **App bar** | `lib/presentation/widgets/common/custom_app_bar.dart` | Reusable appbar |
| **Cards** | `lib/presentation/widgets/common/gradient_card.dart` | Reusable cards |
| **Section titles** | `lib/presentation/widgets/common/section_header.dart` | Reusable headers |

---

## Code Snippets

### Add Event & Handle in BLoC
```dart
// 1. Create event
class NewEvent extends HomeEvent {
  final String data;
  const NewEvent(this.data);
}

// 2. Add handler to BLoC
on<NewEvent>(_onNew);

// 3. Create handler
Future<void> _onNew(
  NewEvent event,
  Emitter<HomeState> emit,
) async {
  // Handle event
  emit(HomeLoaded(...));
}

// 4. Dispatch from widget
context.read<HomeBloc>().add(NewEvent('data'));
```

### Use BlocBuilder
```dart
BlocBuilder<HomeBloc, HomeState>(
  builder: (context, state) {
    return switch (state) {
      HomeLoading() => const LoadingOverlay(...),
      HomeLoaded() => _buildContent(context, state),
      HomeError(message: final msg) => ErrorWidget(message: msg),
    };
  },
);
```

### Create Reusable Widget
```dart
class MyWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const MyWidget({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      child: Text(title),
    );
  }
}
```

### Add New Route
```dart
// 1. Add to Routes
static const String newPage = '/new-page';

// 2. Add to routes map in main.dart
Routes.newPage: (context) => const NewPage(),

// 3. Use in navigation
Navigator.pushNamed(context, Routes.newPage);
```

### Create New Page
```dart
class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'New Page'),
      body: BlocBuilder<NewBloc, NewState>(
        builder: (context, state) => _build(context, state),
      ),
    );
  }

  Widget _build(BuildContext context, NewState state) {
    // Build UI
    return Center(child: Text('New Page'));
  }
}
```

---

## Theme & Colors

### Access Colors
```dart
AppTheme.primaryColor      // #00D4FF (Cyan)
AppTheme.backgroundColor  // #0B0E11 (Dark)
AppTheme.errorColor       // #FF6B6B (Red)
AppTheme.successColor     // #00D97F (Green)
AppTheme.warningColor     // #FFA500 (Orange)
```

### Access Text Styles
```dart
context.textTheme.headlineSmall
context.textTheme.titleLarge
context.textTheme.bodyLarge
context.textTheme.bodyMedium
context.textTheme.bodySmall
```

### Apply Styles
```dart
Text(
  'Title',
  style: context.textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryColor,
  ),
)
```

---

## Common Extensions

### Context Extensions
```dart
context.screenWidth         // Device width
context.screenHeight        // Device height
context.isLandscape        // Landscape mode?
context.isPortrait         // Portrait mode?
context.screenSize         // Size object
context.devicePadding      // Notch, status bar
context.textTheme          // TextTheme
context.colorScheme        // ColorScheme
```

### DateTime Extensions
```dart
now.isToday                // Is today?
now.isYesterday            // Is yesterday?
now.dayName                // "Monday", "Tuesday", etc
```

---

## State Management

### Emit States
```dart
// Single state
emit(HomeLoaded(...));

// Multiple states
emit(HomeLoading());
emit(HomeLoaded(...));
```

### Check State
```dart
if (state is HomeLoading) { }
if (state is HomeLoaded) { }
if (state is HomeError) { }

// Pattern matching
switch (state) {
  HomeLoading() => ...,
  HomeLoaded() => ...,
  _ => ...,
}
```

### Modify State
```dart
// Use copyWith
state.copyWith(
  currentWaterMl: 500,
  hasActivityPermission: true,
)
```

---

## Error Handling

### Try-Catch
```dart
try {
  // Do something
  emit(HomeLoaded(...));
} on FirebaseException catch (e) {
  emit(HomeError('Firebase: ${e.message}'));
} on TimeoutException {
  emit(const HomeError('Request timed out'));
} catch (e) {
  emit(HomeError('Error: $e'));
}
```

### Show Error to User
```dart
if (state is HomeError) {
  return ErrorWidget(
    message: state.message,
    onRetry: () => context.read<HomeBloc>()
      .add(const LoadHomeDataEvent()),
  );
}
```

---

## Navigation

### Navigate to Page
```dart
// Named route (preferred)
Navigator.pushNamed(context, Routes.home);

// With arguments
Navigator.pushNamed(context, Routes.profile, arguments: userId);

// Replace current page
Navigator.pushReplacementNamed(context, Routes.login);

// Go back
Navigator.pop(context);
Navigator.pop(context, 'result');
```

### Get Navigation Result
```dart
final result = await Navigator.pushNamed(context, Routes.newPage);
```

---

## Useful Patterns

### Refresh Data
```dart
RefreshIndicator(
  onRefresh: () async {
    context.read<HomeBloc>().add(const RefreshDataEvent());
  },
  child: ListView(...),
)
```

### Show Loading Overlay
```dart
LoadingOverlay(
  isLoading: state is HomeLoading,
  message: 'Loading...',
  child: _buildContent(context, state),
)
```

### Stream Builder
```dart
StreamBuilder<int>(
  stream: stepService.getTodayStepsStream(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }
    return Text('Steps: ${snapshot.data}');
  },
)
```

### Show Snackbar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Success!'),
    backgroundColor: AppTheme.successColor,
    duration: Duration(seconds: 2),
  ),
);
```

---

## Debugging

### Print State Changes
```dart
on<LoadEvent>((event, emit) async {
  print('Loading started');
  emit(HomeLoading());
  // ...
  print('Loaded: $data');
  emit(HomeLoaded(data));
});
```

### Check BLoC State
```dart
final state = context.read<HomeBloc>().state;
print('Current state: $state');
```

### View Widget Tree
- Android Studio: Device > DevTools > Inspector
- VS Code: Flutter Inspector extension

---

## Performance Tips

### Use Const Widgets
```dart
// ❌ Rebuilds every time
Text('Hello')

// ✅ Skipped if not changed
const Text('Hello')
```

### Use Keys for Lists
```dart
ListView(
  children: items.map((item) =>
    MyTile(key: ValueKey(item.id), item: item),
  ).toList(),
)
```

### Lazy Load Lists
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => 
    MyTile(item: items[index]),
)
```

### Use Late Initialization
```dart
late final Database database;

@override
void initState() {
  super.initState();
  database = Database();
}
```

---

## File Naming

| Type | Convention | Example |
|------|-----------|---------|
| **Dart files** | snake_case | `home_page.dart` |
| **Classes** | PascalCase | `class HomePage` |
| **Variables** | camelCase | `int currentWaterMl` |
| **Constants** | camelCase | `const dailyGoal = 2000` |
| **Private members** | _camelCase | `int _waterMl` |

---

## Export Pattern

### Create Index Files
```dart
// lib/presentation/bloc/index.dart
export 'home_bloc.dart';
export 'home_event.dart';
export 'home_state.dart';

// Usage in widgets
import '../../presentation/bloc/index.dart';
```

---

## BLoC Checklist

✅ Create Events class
✅ Create States class  
✅ Create BLoC class
✅ Add event handlers with `on<Event>()`
✅ Register in `main.dart` BlocProvider
✅ Use BlocBuilder in pages
✅ Add error/loading states
✅ Test state transitions

---

## Documentation Files

| File | Read When |
|------|-----------|
| `README_MODERN_ARCHITECTURE.md` | First time setup |
| `MODERN_ARCHITECTURE.md` | Need detailed guide |
| `CODE_STYLE_GUIDE.md` | Writing code |
| `ARCHITECTURE_DIAGRAMS.md` | Need visual help |
| `FEATURE_TEMPLATE.dart` | Adding new feature |
| `IMPLEMENTATION_COMPLETE.md` | Overall status |

---

## Quick Commands

```bash
# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Format code
dart format lib/

# Analyze code
flutter analyze

# Run tests
flutter test

# Build release
flutter build apk
flutter build ios
```

---

## Key Constants

```dart
// lib/config/app_config.dart
AppConfig.dailyWaterGoalMl    // 2000
AppConfig.waterIncrementMl    // 250
AppConfig.dailyStepGoal       // 10000
AppConfig.networkTimeout      // 30 seconds
AppConfig.cacheExpiration     // 1 hour
```

---

## Version Info

- **Flutter**: 3.7.2+
- **Dart**: 3.7.2+
- **BLoC**: 8.1.4
- **Material**: Material 3

---

**Keep this guide handy while developing! 📋**

*Last Updated: January 19, 2026*
