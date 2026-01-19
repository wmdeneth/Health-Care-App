# VitaTrack Architecture Diagrams

## Application Layer Architecture

```
┌─────────────────────────────────────────────────────┐
│                    USER INTERFACE                   │
│            (Widgets, Pages, Screens)                │
└────────────────┬──────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│           PRESENTATION LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐│
│  │ BLoC         │  │ Pages        │  │ Widgets     ││
│  │ (Business    │  │ (UI Routes)  │  │ (Reusable)  ││
│  │  Logic)      │  │              │  │             ││
│  └──────────────┘  └──────────────┘  └─────────────┘│
└────────────────┬──────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│           DOMAIN LAYER                              │
│  (Use Cases, Entities, Business Rules)              │
│  [READY FOR IMPLEMENTATION]                         │
└────────────────┬──────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│           DATA LAYER                                │
│  ┌──────────────────┐  ┌──────────────────────────┐ │
│  │ Repositories     │  │ Data Sources             │ │
│  │ (Interfaces)     │  │ (Firebase, Local Store)  │ │
│  └──────────────────┘  └──────────────────────────┘ │
│  [READY FOR IMPLEMENTATION]                         │
└────────────────┬──────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│           EXTERNAL SERVICES                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Firebase │  │ Local    │  │ Sensors  │          │
│  │          │  │ Storage  │  │ & APIs   │          │
│  └──────────┘  └──────────┘  └──────────┘          │
└─────────────────────────────────────────────────────┘
```

## Data Flow: User Interaction → State Update

```
┌─────────────────┐
│   USER ACTION   │
│  (e.g. tap)     │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────────┐
│ Page/Widget dispatches Event        │
│ context.read<HomeBloc>()            │
│   .add(UpdateWaterEvent(250))       │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│ BLoC Event Handler Executes         │
│ _onUpdateWater(event, emit)         │
│   - Perform logic                   │
│   - Call services                   │
│   - Emit new state                  │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│ Emit New State                      │
│ emit(HomeLoaded(                    │
│   currentWaterMl: 250               │
│ ))                                  │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│ BlocBuilder Rebuilds Widget         │
│ builder: (context, state) =>        │
│   _buildContent(context, state)     │
└────────┬────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│ UI Updates Automatically            │
│ User sees new water progress        │
└─────────────────────────────────────┘
```

## BLoC Pattern Diagram

```
┌──────────────────────────────────────────┐
│          BLOC (Business Logic)           │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ Event Handlers                     │  │
│  │ on<LoadDataEvent>(_onLoad)        │  │
│  │ on<UpdateDataEvent>(_onUpdate)    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Services & Repositories                │
│  Database calls                         │
│  Business logic                         │
│                                          │
└──────────────────────────────────────────┘
         ↑                        ↓
         │                        │
    INPUT                       OUTPUT
         │                        │
┌────────┴─────┐           ┌──────┴────────┐
│   EVENTS     │           │    STATES     │
└──────────────┘           └───────────────┘
    • Load                      • Loading
    • Update                     • Loaded
    • Delete                     • Error
    • Refresh                    • Success
```

## Folder Structure Tree

```
lib/
│
├── config/
│   ├── app_config.dart          # Constants & settings
│   ├── routes.dart              # Type-safe routes
│   └── theme.dart               # UI Theme
│
├── core/
│   └── utils/
│       ├── color_utils.dart     # Color helpers
│       └── extensions.dart      # Extension methods
│
├── data/                        # Data Layer (To-Do)
│   ├── datasources/
│   └── repositories/
│
├── domain/                      # Domain Layer (To-Do)
│   ├── entities/
│   └── usecases/
│
├── presentation/                # UI & State Management
│   ├── bloc/
│   │   ├── home_bloc.dart       # Business logic
│   │   ├── home_event.dart      # User actions
│   │   └── home_state.dart      # UI states
│   ├── pages/
│   │   └── home_page.dart       # Modern page
│   └── widgets/
│       └── common/              # Reusable widgets
│           ├── loading_overlay.dart
│           ├── error_widget.dart
│           ├── custom_app_bar.dart
│           ├── gradient_card.dart
│           └── section_header.dart
│
├── screens/                     # Legacy screens (preserved)
├── services/                    # Legacy services (preserved)
├── models/                      # Legacy models (preserved)
├── widgets/                     # Legacy widgets (preserved)
│
└── main.dart                    # App entry point
```

## State Management Flow

```
                    HomePage
                       │
                       ↓
                ┌──────────────┐
                │ BlocProvider │ ← MultiBlocProvider in main.dart
                └──────────────┘
                       │
          ┌────────────┴────────────┐
          ↓                         ↓
    ┌──────────┐         ┌─────────────────┐
    │ BlocBuilder       │ BlocListener    │
    │ Rebuilds UI       │ Side Effects    │
    └──────────┘        └─────────────────┘
          │                      │
          ↓                      ↓
    ┌──────────┐      ┌─────────────────┐
    │ Receives │      │ Navigate/Show   │
    │ State    │      │ Snackbar/Dialog │
    └──────────┘      └─────────────────┘
```

## Component Reusability

```
┌─────────────────────────────────────────┐
│      Common Reusable Widgets            │
├─────────────────────────────────────────┤
│                                         │
│  LoadingOverlay                         │
│  ├── HomePage ✓                         │
│  ├── ProfilePage ✓                      │
│  └── SettingsPage ✓                     │
│                                         │
│  ErrorWidget                            │
│  ├── HomePage ✓                         │
│  ├── NotificationsPage ✓                │
│  └── StepsPage ✓                        │
│                                         │
│  GradientCard                           │
│  ├── HomePage ✓                         │
│  ├── ProfilePage ✓                      │
│  └── Custom pages ✓                     │
│                                         │
│  CustomAppBar                           │
│  ├── All pages ✓                        │
│                                         │
│  SectionHeader                          │
│  ├── HomePage ✓                         │
│  └── Custom pages ✓                     │
│                                         │
└─────────────────────────────────────────┘
```

## Feature Addition Workflow

```
1. DEFINE
   ├── Create Events
   ├── Create States
   └── Create BLoC

2. IMPLEMENT
   ├── Create Page/Screen
   ├── Create Widgets
   └── Add Routes

3. INTEGRATE
   ├── Register BLoC in main.dart
   ├── Add route mapping
   └── Test flow

4. ENHANCE
   ├── Add error handling
   ├── Add loading states
   └── Add animations

DONE! Feature ready to use
```

## Dependency Injection (BLoC Providers)

```
main.dart
    │
    ├── HomeBloc
    │   ├── MealTipService
    │   └── StepCounterService
    │
    ├── AuthBloc
    │   └── FirebaseAuth
    │
    ├── ProfileBloc
    │   └── UserProfileService
    │
    └── NotificationBloc
        └── NotificationService

All BLoCs available via:
context.read<HomeBloc>()
context.read<AuthBloc>()
```

## Error Handling Flow

```
Error Occurs
    │
    ↓
┌─────────────────────┐
│ Try-Catch Block     │
│ in BLoC Event       │
└─────────────────────┘
    │
    ├─→ FirebaseException
    │       ↓
    │   emit(HomeError('Firebase error'))
    │
    ├─→ TimeoutException
    │       ↓
    │   emit(HomeError('Request timeout'))
    │
    └─→ Other Exception
            ↓
        emit(HomeError('Unknown error'))
            │
            ↓
    ┌─────────────────────┐
    │ BlocBuilder catches │
    │ HomeError state     │
    └─────────────────────┘
            │
            ↓
    Display ErrorWidget
    with retry button
```

## Theme Application

```
AppTheme (lib/config/theme.dart)
    │
    ├── Colors
    │   ├── primaryColor (#00D4FF)
    │   ├── backgroundColor (#0B0E11)
    │   ├── cardBackground (#1F2937)
    │   ├── errorColor (#FF6B6B)
    │   ├── successColor (#00D97F)
    │   └── warningColor (#FFA500)
    │
    ├── TextTheme
    │   ├── headlineSmall (24pt, bold)
    │   ├── titleLarge (20pt, bold)
    │   ├── bodyLarge (16pt)
    │   ├── bodyMedium (14pt)
    │   └── bodySmall (12pt)
    │
    ├── Components
    │   ├── AppBarTheme
    │   ├── CardTheme
    │   ├── ButtonTheme
    │   └── InputTheme
    │
    └── Applied via
        Theme.of(context).textTheme.titleLarge
        AppTheme.primaryColor
        Theme.of(context).colorScheme
```

---

These diagrams visualize:
- Application layer structure
- Data flow during user interactions
- BLoC pattern mechanics
- Folder organization
- State management flow
- Component reusability
- Feature addition process
- Error handling strategy
- Dependency injection
- Theme application system

**Use these diagrams as reference when:**
- Adding new features
- Debugging state issues
- Explaining architecture to team members
- Onboarding new developers
- Planning app expansions
