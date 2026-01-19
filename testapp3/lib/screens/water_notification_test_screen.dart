import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/water_notification_test.dart';

/// Standalone screen for testing water notifications
class WaterNotificationTestScreen extends StatefulWidget {
  const WaterNotificationTestScreen({super.key});

  @override
  State<WaterNotificationTestScreen> createState() =>
      _WaterNotificationTestScreenState();
}

class _WaterNotificationTestScreenState
    extends State<WaterNotificationTestScreen> {
  bool _isRunning = false;
  final List<String> _testLogs = [];

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      if (user == null) {
        _testLogs.add('⚠️  No user logged in');
      } else {
        _testLogs.add('✓ User logged in: ${user.email ?? user.uid}');
      }
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testLogs.clear();
      _testLogs.add('🚀 Starting water notification tests...');
    });

    try {
      await WaterNotificationTest.runAllTests();
      setState(() {
        _testLogs.add('');
        _testLogs.add('✅ All tests completed!');
        _testLogs.add('Check the debug console for detailed results.');
      });
    } catch (e) {
      setState(() {
        _testLogs.add('');
        _testLogs.add('❌ Error running tests: $e');
      });
    }

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _runSingleTest(
    String testName,
    Future<bool> Function() test,
  ) async {
    setState(() {
      _testLogs.add('Running: $testName...');
    });

    try {
      final result = await test();
      setState(() {
        _testLogs.add(result ? '✅ $testName: PASSED' : '❌ $testName: FAILED');
      });
    } catch (e) {
      setState(() {
        _testLogs.add('❌ $testName: ERROR - $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Notification Tests'),
        elevation: 0,
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
          child: Column(
            children: [
              // Test controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isRunning ? null : _runTests,
                      icon:
                          _isRunning
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.play_arrow),
                      label: Text(_isRunning ? 'Running...' : 'Run All Tests'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick test buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed:
                              _isRunning
                                  ? null
                                  : () => _runSingleTest(
                                    'Enable Reminders',
                                    WaterNotificationTest
                                        .testEnableWaterReminders,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                          ),
                          child: const Text('Enable'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _isRunning
                                  ? null
                                  : () => _runSingleTest(
                                    'Schedule',
                                    WaterNotificationTest
                                        .testScheduleNotifications,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                          ),
                          child: const Text('Schedule'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _isRunning
                                  ? null
                                  : () => _runSingleTest(
                                    'Test Now',
                                    WaterNotificationTest
                                        .testImmediateNotification,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                          ),
                          child: const Text('Test Now'),
                        ),
                        ElevatedButton(
                          onPressed:
                              _isRunning
                                  ? null
                                  : () => _runSingleTest(
                                    'Check Profile',
                                    WaterNotificationTest.testUserProfile,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade800,
                          ),
                          child: const Text('Profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1),

              // Test logs
              Expanded(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child:
                      _testLogs.isEmpty
                          ? Center(
                            child: Text(
                              'No tests run yet\nTap "Run All Tests" to begin',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _testLogs.length,
                            itemBuilder: (context, index) {
                              final log = _testLogs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  log,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ),

              // Info panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withValues(alpha: 0.2),
                  border: Border(
                    top: BorderSide(
                      color: Colors.blue.shade800.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade300),
                        const SizedBox(width: 8),
                        Text(
                          'Testing Info',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Tests verify notification scheduling, permissions, and actions\n'
                      '• Check debug console for detailed output\n'
                      '• "Test Now" sends an immediate notification\n'
                      '• Make sure notifications are enabled in settings',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
