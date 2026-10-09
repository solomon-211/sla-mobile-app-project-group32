import 'package:flutter/material.dart';
import 'app_router.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip the welcome screens when a remembered user is saved on the device.
  // If the saved session cannot be read, start on the Landing screen.
  var signedIn = false;
  try {
    signedIn = await SessionService.restoreSession();
  } catch (error, stack) {
    debugPrint('Could not restore session: $error\n$stack');
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
      initialRoute: startSignedIn ? AppRoutes.home : AppRoutes.landing,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
