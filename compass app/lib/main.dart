import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const CompassApp());
}

class CompassApp extends StatelessWidget {
  const CompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern Compass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const CompassHomePage(),
    );
  }
}

class CompassHomePage extends StatefulWidget {
  const CompassHomePage({super.key});

  @override
  State<CompassHomePage> createState() => _CompassHomePageState();
}

class _CompassHomePageState extends State<CompassHomePage> {
  double? _heading;
  StreamSubscription<CompassEvent>? _compassSub;
  String _status = 'Checking permissions...';
  // rotation expressed in turns (1.0 == 360°). We accumulate small deltas to
  // ensure the animation always uses the shortest rotation path.
  double _rotationTurns = 0.0;
  double _lastRawHeading = 0.0;
  static const Duration _animDuration = Duration(milliseconds: 360);

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isDenied || status.isRestricted) {
      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) {
        setState(() => _status = 'Location permission is required');
        return;
      }
    }

    _startCompass();
  }

  void _startCompass() {
    try {
      _compassSub = FlutterCompass.events?.listen((event) {
        final raw = event.heading;
        if (raw == null) {
          setState(() => _status = 'Compass sensor not available');
          return;
        }

        // compute smallest delta between last heading and new heading
        var delta = raw - _lastRawHeading;
        // normalize to [-180, 180]
        while (delta > 180) delta -= 360;
        while (delta < -180) delta += 360;

        _rotationTurns += delta / 360.0;
        _lastRawHeading = raw;

        setState(() {
          _heading = raw;
          _status = 'OK';
        });
      });
    } on MissingPluginException {
      // On some platforms (windows desktop) the flutter_compass plugin
      // may not provide a platform implementation. Gracefully report that
      // to the user instead of crashing.
      setState(() => _status = 'Compass plugin not supported on this platform');
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading ?? 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Compass'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status == 'OK' ? '${heading.toStringAsFixed(0)}°' : _status,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.white, Colors.grey.shade200],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x14000000),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    // Tween the rotation turns for smooth movement. We use
                    // TweenAnimationBuilder and feed it the accumulated
                    // _rotationTurns value; the builder will animate between
                    // the previous and new values automatically.
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: _rotationTurns),
                      duration: _animDuration,
                      builder: (context, turns, child) {
                        return Transform.rotate(
                          angle: (turns * 2 * math.pi) * -1,
                          child: child,
                        );
                      },
                      child: CustomPaint(
                        size: const Size(260, 260),
                        painter: _CompassPainter(),
                      ),
                    ),
                    Positioned(
                      top: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _reRequestPermissions,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Request Permission'),
                  ),
                  const SizedBox(width: 12),
                  if (_status == 'OK')
                    Chip(
                      label: Text(_cardinal(heading)),
                      backgroundColor: Colors.teal.shade50,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reRequestPermissions() async {
    final result = await Permission.locationWhenInUse.request();
    if (result.isGranted) {
      setState(() => _status = 'OK');
      _startCompass();
    } else if (result.isPermanentlyDenied) {
      openAppSettings();
    } else {
      setState(() => _status = 'Location permission is required');
    }
  }
}

/// Return a short cardinal direction for a heading in degrees
String _cardinal(double heading) {
  final dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final idx = (((heading + 22.5) % 360) / 45).floor() % 8;
  return dirs[idx];
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.grey.shade400;

    canvas.drawCircle(center, radius, ringPaint);

    final tickPaint = Paint()
      ..strokeWidth = 2
      ..color = Colors.black87;

    for (int i = 0; i < 360; i += 10) {
      final isMajor = i % 90 == 0;
      final length = isMajor ? 18.0 : 8.0;
      final angle = (i - 180) * (math.pi / 180);
      final p1 = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 12 - length) * math.cos(angle),
        center.dy + (radius - 12 - length) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(i ~/ 10) * 10}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final tpOffset = Offset(
          center.dx + (radius - 40) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius - 40) * math.sin(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, tpOffset);
      }
    }

    // draw needle
    final needlePaint = Paint()..color = Colors.redAccent;
    final path = Path();
    path.moveTo(center.dx, center.dy - 8);
    path.lineTo(center.dx - 8, center.dy + radius / 2);
    path.lineTo(center.dx + 8, center.dy + radius / 2);
    path.close();
    canvas.drawPath(path, needlePaint);

    final hubPaint = Paint()..color = Colors.black87;
    canvas.drawCircle(center, 6, hubPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
