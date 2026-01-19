/// Template for creating new feature screens with modern architecture
///
/// Copy this structure when adding new features
/// Example: WaterIntakeTracking, AuthFlow, Settings, etc.

// ============ 1. EVENTS (lib/presentation/bloc/feature_event.dart) ============
/*
abstract class FeatureEvent {
  const FeatureEvent();
}

class LoadFeatureDataEvent extends FeatureEvent {
  const LoadFeatureDataEvent();
}

class UpdateFeatureEvent extends FeatureEvent {
  final String data;
  const UpdateFeatureEvent(this.data);
}
*/

// ============ 2. STATES (lib/presentation/bloc/feature_state.dart) ============
/*
abstract class FeatureState {
  const FeatureState();
}

class FeatureInitial extends FeatureState {
  const FeatureInitial();
}

class FeatureLoading extends FeatureState {
  const FeatureLoading();
}

class FeatureLoaded extends FeatureState {
  final String data;
  const FeatureLoaded(this.data);
}

class FeatureError extends FeatureState {
  final String message;
  const FeatureError(this.message);
}
*/

// ============ 3. BLOC (lib/presentation/bloc/feature_bloc.dart) ============
/*
import 'package:flutter_bloc/flutter_bloc.dart';

class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  FeatureBloc() : super(const FeatureInitial()) {
    on<LoadFeatureDataEvent>(_onLoadFeatureData);
    on<UpdateFeatureEvent>(_onUpdateFeature);
  }

  Future<void> _onLoadFeatureData(
    LoadFeatureDataEvent event,
    Emitter<FeatureState> emit,
  ) async {
    emit(const FeatureLoading());
    try {
      // TODO: Load data
      emit(const FeatureLoaded('data'));
    } catch (e) {
      emit(FeatureError(e.toString()));
    }
  }

  Future<void> _onUpdateFeature(
    UpdateFeatureEvent event,
    Emitter<FeatureState> emit,
  ) async {
    // TODO: Handle update
  }
}
*/

// ============ 4. PAGE/SCREEN (lib/presentation/pages/feature_page.dart) ============
/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/feature_bloc.dart';
import '../widgets/common/index.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Feature Title'),
      body: BlocBuilder<FeatureBloc, FeatureState>(
        builder: (context, state) {
          return switch (state) {
            FeatureInitial() || FeatureLoading() =>
              const Center(child: CircularProgressIndicator()),
            FeatureLoaded(data: final data) => _buildContent(context, data),
            FeatureError(message: final error) =>
              ErrorWidget(
                message: error,
                onRetry: () => context.read<FeatureBloc>().add(
                  const LoadFeatureDataEvent(),
                ),
              ),
          };
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, String data) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Build UI
          ],
        ),
      ),
    );
  }
}
*/

// ============ 5. REUSABLE WIDGET (lib/presentation/widgets/feature/feature_card.dart) ============
/*
import 'package:flutter/material.dart';
import '../common/gradient_card.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
*/

// ============ 6. REGISTER BLOC IN MAIN (lib/main.dart) ============
/*
MultiBlocProvider(
  providers: [
    // ... existing providers
    BlocProvider(
      create: (context) => FeatureBloc(),
    ),
  ],
  child: MaterialApp(...),
)
*/

// ============ 7. ADD ROUTE (lib/config/routes.dart) ============
/*
class Routes {
  // ... existing routes
  static const String feature = '/feature';
}
*/

// ============ 8. REGISTER ROUTE (lib/main.dart) ============
/*
routes: {
  // ... existing routes
  Routes.feature: (context) => const FeaturePage(),
}
*/

// ============ FEATURE CHECKLIST ============
/*
✅ Created Events class
✅ Created States class (with copyWith if needed)
✅ Created BLoC with event handlers
✅ Created Page/Screen with BLoC integration
✅ Created reusable widgets (if needed)
✅ Registered BLoC in main.dart
✅ Added route constant in routes.dart
✅ Registered route in main.dart routes
✅ Tested loading/error/success states
✅ Added proper error handling
*/
