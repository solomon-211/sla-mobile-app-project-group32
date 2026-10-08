import 'package:flutter/material.dart';

import 'models/task.dart';
import 'screens/home_shell.dart';
import 'screens/sign_in_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/task_form_screen.dart';

/// All named routes in one place.
///
/// Sign In -> Home (Dashboard / Tasks / Team tabs)
/// Home    -> Task Details -> Task Form (edit)
/// Home    -> Task Form (create)
class AppRoutes {
  static const signIn = 'sign-in';
  static const home = 'home';
  static const taskDetails = 'task-details';
  static const taskForm = 'task-form';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
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
}
