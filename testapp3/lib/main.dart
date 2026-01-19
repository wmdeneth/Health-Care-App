import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/app_config.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'presentation/bloc/index.dart';
import 'presentation/pages/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/steps_screen.dart';
import 'screens/water_notification_test_screen.dart';
import 'services/notification_service.dart';
import 'services/step_counter_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initNotificationService();

  // Test notification - shows when app opens
  await showAppLaunchNotification();

  // Initialize step counter
  final stepService = StepCounterService();
  await stepService.initStepCounter();

  final user = FirebaseAuth.instance.currentUser;

  runApp(MyApp(initialRoute: user != null ? Routes.home : Routes.login));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => HomeBloc())],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(context),
        initialRoute: initialRoute,
        routes: {
          Routes.login: (context) => const LoginScreen(),
          Routes.register: (context) => const RegisterScreen(),
          Routes.home: (context) => const HomePage(),
          Routes.profile: (context) => const ProfileScreen(),
          Routes.notifications: (context) => const NotificationsScreen(),
          Routes.steps: (context) => const StepsScreen(),
          Routes.waterTest: (context) => const WaterNotificationTestScreen(),
        },
      ),
    );
  }
}
