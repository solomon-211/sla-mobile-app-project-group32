import 'package:flutter/material.dart';
import 'app_router.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip the sign-in screen when a remembered user is saved on the device.
  // If the saved session cannot be read, fall back to the sign-in screen.
  var signedIn = false;
  try {
    signedIn = await SessionService.restoreSession();
  } catch (_) {
    signedIn = false;
  }
  runApp(SprintTrackApp(startSignedIn: signedIn));
}

class SprintTrackApp extends StatelessWidget {
  const SprintTrackApp({super.key, required this.startSignedIn});

  final bool startSignedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SprintTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: startSignedIn ? AppRoutes.home : AppRoutes.signIn,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
