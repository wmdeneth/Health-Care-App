import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/utils/extensions.dart';
import '../../widgets/step_ring.dart';
import '../../widgets/water_card.dart';
import '../../services/step_counter_service.dart';
import '../../services/meal_tip_service.dart';
import '../bloc/index.dart';
import '../widgets/common/index.dart';
import '../../models/meal_tip.dart';
import '../../models/notification_history.dart';
import '../../services/notification_history_service.dart';
import 'package:intl/intl.dart';

enum HomeViewType { dashboard, analysis, tips, water }

/// Modernized home page with BLoC state management
class HomePage extends StatefulWidget {
  final HomeViewType viewType;
  const HomePage({super.key, this.viewType = HomeViewType.dashboard});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MealTipService _mealTipService = MealTipService();
  final StepCounterService _stepCounterService = StepCounterService();
  final NotificationHistoryService _historyService =
      NotificationHistoryService();

  @override
  void initState() {
    super.initState();
    // Initialize BLoC with home data
    context.read<HomeBloc>().add(const InitializeHomeEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  () => context.read<HomeBloc>().add(const RefreshDataEvent()),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.viewType == HomeViewType.dashboard) ...[
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

                  const SectionHeader(
                    title: 'Steps Tracking',
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    centered: true,
                  ),
                  const SizedBox(height: 16),
                  Center(child: _buildStepsRing(state)),
                  const SizedBox(height: 28),

                  SectionHeader(
                    title: 'Quick Actions',
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  const SizedBox(height: 16),
                  _buildWaterCard(state),
                ],

                if (widget.viewType == HomeViewType.analysis) ...[
                  const SectionHeader(
                    title: 'Health Metrics',
                    padding: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  const SizedBox(height: 16),
                  _buildBMICard(context, state),
                  const SizedBox(height: 28),

                  const SectionHeader(
                    title: 'Last 7 Days Water',
                    padding: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  const SizedBox(height: 16),
                  _buildWaterHistory(state),
                  const SizedBox(height: 28),

                  const SectionHeader(
                    title: 'Last 7 Days Steps',
                    padding: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  const SizedBox(height: 16),
                  _buildStepHistory(state),
                ],

                if (widget.viewType == HomeViewType.tips) ...[
                  const SectionHeader(
                    title: 'Daily Tips',
                    padding: EdgeInsets.symmetric(horizontal: 0),
                  ),
                  const SizedBox(height: 16),
                  _buildDailyTip(context),
                ],

                if (widget.viewType == HomeViewType.water) ...[
                  _buildWaterRemindersView(),
                ],
                const SizedBox(height: 40),
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

  Widget _buildBMICard(BuildContext context, HomeLoaded state) {
    if (state.bmi == null) {
      return GradientCard(
        gradient: LinearGradient(
          colors: [Colors.grey.shade800, Colors.grey.shade900],
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, Routes.profile),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_weight_outlined,
                  color: Colors.white70,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up BMI',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add height & weight in profile',
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bmi = state.bmi!;
    final status = state.bmiStatus ?? 'Unknown';
    Color statusColor;
    IconData statusIcon;
    String message;

    if (status == 'Normal') {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.check_circle_outline;
      message = 'You are in a healthy range!';
    } else {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.warning_amber_rounded;
      if (status == 'Underweight') {
        message = 'Warning: BMI is too low.';
      } else {
        message = 'Warning: BMI is too high.';
      }
    }

    // Obese gets red
    if (status == 'Obese') {
      statusColor = Colors.redAccent;
    }

    return GradientCard(
      gradient: LinearGradient(
        colors: [
          statusColor.withValues(alpha: 0.15),
          statusColor.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.monitor_weight, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI Score',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          bmi.toStringAsFixed(1),
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status != 'Normal') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: TextStyle(color: statusColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
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
      onAddWater: () {
        context.read<HomeBloc>().add(const UpdateWaterIntakeEvent(250));
      },
    );
  }

  Widget _buildDailyTip(BuildContext context) {
    return StreamBuilder<List<MealTip>>(
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

        return Column(
          children:
              tips.map((tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GradientCard(
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
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildStepHistory(HomeLoaded state) {
    if (state.stepHistory.isEmpty) {
      return GradientCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No step history available.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
          ),
        ),
      );
    }

    return GradientCard(
      padding: const EdgeInsets.all(0),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.stepHistory.length,
        separatorBuilder:
            (context, index) =>
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
        itemBuilder: (context, index) {
          final data = state.stepHistory[index];
          final dateStr =
              '${data.date.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][data.date.month - 1]}';
          final progress = (data.steps / state.dailyStepGoal).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDayLabel(data.date.toIso8601String().split('T')[0]),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${data.steps} steps',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  progress >= 1.0
                                      ? Colors.greenAccent
                                      : Colors.white70,
                              fontWeight:
                                  progress >= 1.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0
                                ? Colors.greenAccent
                                : AppTheme.primaryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaterHistory(HomeLoaded state) {
    if (state.waterHistory.isEmpty) {
      return GradientCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'No history yet. Start tracking today!',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
          ),
        ),
      );
    }

    // Take up to 7 days
    final displayHistory =
        state.waterHistory.take(7).toList().reversed.toList();

    return GradientCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  displayHistory.map((log) {
                    final progress = (log.intake / log.goal.clamp(1, 9999))
                        .clamp(0.01, 1.1);
                    final dayLabel = _getDayLabel(log.date);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${log.intake}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 80 * progress.toDouble(),
                          width: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors:
                                  progress >= 1.0
                                      ? [Colors.greenAccent, Colors.green]
                                      : [
                                        const Color(0xFF00C6FF),
                                        const Color(0xFF0072FF),
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: (progress >= 1.0
                                        ? Colors.greenAccent
                                        : const Color(0xFF00C6FF))
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                dayLabel == 'Today'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                dayLabel == 'Today'
                                    ? Colors.white
                                    : Colors.white70,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final checkDate = DateTime(date.year, date.month, date.day);

      if (checkDate.isAtSameMomentAs(today)) {
        return 'Today';
      }
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday -
          1];
    } catch (_) {
      return '';
    }
  }

  Widget _buildWaterRemindersView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Upcoming Reminders',
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
        StreamBuilder<List<NotificationHistory>>(
          stream: _historyService.getFutureNotificationsStream(),
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No upcoming reminders scheduled.',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0),
              itemCount: notifications.length.clamp(0, 5), // Show top 5
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _buildWaterRecordTile(n, isUpcoming: true);
              },
            );
          },
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Past 7 Days History',
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
        StreamBuilder<List<NotificationHistory>>(
          stream: _historyService.getPastNotificationsStream(days: 7),
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No past reminders found.',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _buildWaterRecordTile(n, isUpcoming: false);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildWaterRecordTile(
    NotificationHistory n, {
    bool isUpcoming = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              isUpcoming
                  ? Colors.orange.withValues(alpha: 0.1)
                  : (n.drank
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.blue.withValues(alpha: 0.2)),
          child: Icon(
            isUpcoming
                ? Icons.schedule
                : (n.drank ? Icons.check : Icons.water_drop),
            color:
                isUpcoming
                    ? Colors.orangeAccent
                    : (n.drank ? Colors.greenAccent : Colors.blueAccent),
          ),
        ),
        title: Text(
          isUpcoming ? 'Planned Water' : n.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration:
                (!isUpcoming && n.drank) ? TextDecoration.lineThrough : null,
            color: (!isUpcoming && n.drank) ? Colors.white38 : Colors.white,
          ),
        ),
        subtitle: Text(
          '${DateFormat('HH:mm').format(n.notificationTime)} • ${n.incrementMl}ml',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing:
            isUpcoming
                ? const Text(
                  'Pending',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                )
                : (n.drank
                    ? const Text(
                      'Done',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                    )
                    : OutlinedButton(
                      onPressed: () => _historyService.markAsDrank(n.id),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: const BorderSide(color: Colors.blueAccent),
                      ),
                      child: const Text('Log', style: TextStyle(fontSize: 12)),
                    )),
      ),
    );
  }
}
