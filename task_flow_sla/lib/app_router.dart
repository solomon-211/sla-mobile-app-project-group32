import 'package:flutter/material.dart';

import 'models/task.dart';
import 'screens/home_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/register_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/task_form_screen.dart';

/// All named routes in one place.
///
/// Landing -> Register or Sign In -> Home (Dashboard / Tasks / Team tabs)
/// Home    -> Task Details -> Task Form (edit)
/// Home    -> Task Form (create)
class AppRoutes {
  static const landing = 'landing';
  static const register = 'register';
  static const signIn = 'sign-in';
  static const home = 'home';
  static const taskDetails = 'task-details';
  static const taskForm = 'task-form';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case landing:
        page = const LandingScreen();
      case register:
        page = const RegisterScreen();
      case home:
        page = const HomeShell();
      case taskDetails:
        // Expects the task id.
        page = TaskDetailsScreen(taskId: settings.arguments as int);
      case taskForm:
        // Expects a Task to edit, or null to create a new one.
        page = TaskFormScreen(task: settings.arguments as Task?);
      default:
        page = const SignInScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  /// Leaves the sign-in or register screen after a successful sign in.
  /// Clears the stack so Back cannot return to Landing or Sign In.
  static void goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, home, (route) => false);
  }

  /// Back from Sign In or Register: return to the previous screen, or to
  /// Landing when there is nothing underneath (e.g. after signing out).
  static void backToLanding(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(landing);
    }
  }
}
