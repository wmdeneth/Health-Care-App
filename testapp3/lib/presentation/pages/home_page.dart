import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_config.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/extensions.dart';
import '../../widgets/step_ring.dart';
import '../../widgets/water_card.dart';
import '../../services/step_counter_service.dart';
import '../../services/meal_tip_service.dart';
import '../../services/water_notification_test.dart';
import '../bloc/index.dart';
import '../widgets/common/index.dart';

/// Modernized home page with BLoC state management
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MealTipService _mealTipService = MealTipService();
  final StepCounterService _stepCounterService = StepCounterService();

  @override
  void initState() {
    super.initState();
    // Initialize BLoC with home data
    context.read<HomeBloc>().add(const InitializeHomeEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return switch (state) {
              HomeInitial() ||
              HomeLoading() => const Center(child: CircularProgressIndicator()),
              HomeLoaded() => _buildContent(context, state),
              HomeError(message: final error) => AppErrorWidget(
                message: error,
                onRetry:
                    () =>
                        context.read<HomeBloc>().add(const RefreshDataEvent()),
              ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(AppConfig.appName),
      backgroundColor: AppTheme.secondaryBackground,
      elevation: 0,
      actions: [
        _buildAppBarAction(
          icon: Icons.science_outlined,
          tooltip: 'Water Tests',
          onPressed: () => Navigator.pushNamed(context, Routes.waterTest),
        ),
        _buildAppBarAction(
          icon: Icons.directions_walk,
          tooltip: 'Steps',
          onPressed: () => Navigator.pushNamed(context, Routes.steps),
        ),
        _buildAppBarAction(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          onPressed: () => Navigator.pushNamed(context, Routes.notifications),
        ),
        _buildAppBarAction(
          icon: Icons.account_circle_outlined,
          tooltip: 'Profile',
          onPressed: () => Navigator.pushNamed(context, Routes.profile),
        ),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
  }

  Widget _buildContent(BuildContext context, HomeLoaded state) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(const RefreshDataEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeaderSection(context),
                const SizedBox(height: 28),

                // Permission Alert (if needed)
                if (!state.hasActivityPermission)
                  _buildPermissionAlert(context),

                // Stats Section
                SectionHeader(
                  title: 'Today\'s Progress',
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(context, state),
                const SizedBox(height: 28),

                // Health Metrics Section
                SectionHeader(
                  title: 'Health Metrics',
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 16),
                _buildStepsRing(state),
                const SizedBox(height: 16),
                _buildWaterCard(state),
                const SizedBox(height: 28),

                // Tips Section
                SectionHeader(
                  title: 'Daily Tips',
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                ),
                const SizedBox(height: 16),
                _buildDailyTip(context),
                const SizedBox(height: 28),

                // Testing Tools Section
                _buildTestingToolsCard(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back!',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your health journey today',
          style: context.textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPermissionAlert(BuildContext context) {
    return Column(
      children: [
        GradientCard(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.1),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.orange.shade300),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Step Tracking',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Allow activity recognition to track your daily steps',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed:
                    () => context.read<HomeBloc>().add(
                      const RequestPermissionEvent(),
                    ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Allow'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, HomeLoaded state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Steps',
            value: state.todaySteps.toString(),
            goal: '${state.dailyStepGoal}',
            icon: Icons.directions_walk,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Water',
            value: '${state.currentWaterMl}ml',
            goal: '${state.dailyWaterGoal}ml',
            icon: Icons.water_drop,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String goal,
    required IconData icon,
  }) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              Text(
                goal,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsRing(HomeLoaded state) {
    return StreamBuilder<int>(
      stream: _stepCounterService.getTodayStepsStream(),
      builder: (context, snapshot) {
        final steps = snapshot.data ?? 0;
        return StepRing(steps: steps, goal: state.dailyStepGoal);
      },
    );
  }

  Widget _buildWaterCard(HomeLoaded state) {
    return WaterCard(
      currentMl: state.currentWaterMl,
      dailyGoalMl: state.dailyWaterGoal,
    );
  }

  Widget _buildDailyTip(BuildContext context) {
    return StreamBuilder(
      stream: _mealTipService.streamMealTips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tips = snapshot.data ?? [];
        if (tips.isEmpty) {
          return GradientCard(
            child: Center(
              child: Text(
                'No tips available',
                style: context.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final tip = tips.first;
        return GradientCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.title,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tip.subtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestingToolsCard(BuildContext context) {
    return GradientCard(
      gradient: LinearGradient(
        colors: [
          Colors.purple.withValues(alpha: 0.2),
          Colors.purple.withValues(alpha: 0.1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.purple.shade300),
              const SizedBox(width: 8),
              Text(
                'Testing Tools',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Test water notification functionality and debugging tools',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.purple.shade200,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _runTests(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _runTests(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Running tests... Check console output'),
        duration: Duration(seconds: 2),
      ),
    );

    WaterNotificationTest.runAllTests().then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tests complete! Check console for results'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    });
  }
}
