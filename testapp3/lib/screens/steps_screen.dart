import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/step_data.dart';
import '../services/step_counter_service.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final StepCounterService _stepService = StepCounterService();
  late Future<List<StepData>> _sevenDaysStepsFuture;
  int _dailyGoal = 10000;
  int _todaySteps = 0;

  @override
  void initState() {
    super.initState();
    _sevenDaysStepsFuture = _stepService.getLast7DaysSteps();
    _loadData();
  }

  Future<void> _loadData() async {
    final goal = await _stepService.getDailyGoal();
    final today = await _stepService.getTodaySteps();

    setState(() {
      _dailyGoal = goal;
      _todaySteps = today;
      _sevenDaysStepsFuture = _stepService.getLast7DaysSteps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steps'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Set Daily Goal',
            onPressed: _showGoalDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0E11), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Steps Card
                _buildTodayStepsCard(),
                const SizedBox(height: 24),

                // Stats Overview
                _buildStatsOverview(),
                const SizedBox(height: 24),

                // Weekly Steps List
                Text(
                  'Last 7 Days',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildWeeklyStepsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStepsCard() {
    final progressPercentage = (_todaySteps / _dailyGoal).clamp(0.0, 1.0);
    final progressColor = _getProgressColor(progressPercentage);

    return Card(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade700],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Today\'s Steps',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      _todaySteps.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'steps',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: progressPercentage,
                          strokeWidth: 8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(progressPercentage * 100).toStringAsFixed(0)}%',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'of goal',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progressPercentage,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_dailyGoal - _todaySteps} steps left',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return FutureBuilder<double>(
      future: _stepService.getAverageSteps(7),
      builder: (context, snapshot) {
        final average = snapshot.data ?? 0.0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Daily Goal',
                _dailyGoal.toString(),
                Icons.flag,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '7-Day Avg',
                average.toStringAsFixed(0),
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStepsList() {
    return FutureBuilder<List<StepData>>(
      future: _sevenDaysStepsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stepsList = snapshot.data ?? [];

        if (stepsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_walk,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'No step data yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Fill missing days with 0 steps
        final now = DateTime.now();
        final allDays = <StepData>[];
        for (int i = 6; i >= 0; i--) {
          final date = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: i));
          final existingData = stepsList.firstWhere(
            (data) =>
                DateTime(
                  data.date.year,
                  data.date.month,
                  data.date.day,
                ).compareTo(date) ==
                0,
            orElse: () => StepData(date: date, steps: 0),
          );
          allDays.add(existingData);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allDays.length,
          itemBuilder: (context, index) {
            final stepData = allDays[index];
            final isToday =
                DateTime.now().difference(stepData.date).inDays == 0;
            final progressPercentage = (stepData.steps / _dailyGoal).clamp(
              0.0,
              1.0,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Day label
                    SizedBox(
                      width: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE').format(stepData.date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade400),
                          ),
                          Text(
                            DateFormat('MMM d').format(stepData.date),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (isToday)
                            Chip(
                              label: const Text(
                                'Today',
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.blue.shade700,
                              labelStyle: const TextStyle(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: progressPercentage,
                              backgroundColor: Colors.grey.shade700,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progressPercentage),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stepData.steps} steps',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Steps count
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${(progressPercentage * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _getProgressColor(progressPercentage),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.75) return Colors.blue;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: _dailyGoal.toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set Daily Step Goal'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Goal (steps)',
                hintText: '10000',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newGoal = int.tryParse(controller.text);
                  if (newGoal != null && newGoal > 0) {
                    await _stepService.setDailyGoal(newGoal);
                    if (mounted) {
                      setState(() => _dailyGoal = newGoal);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily goal updated!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Set'),
              ),
            ],
          ),
    );
  }
}
