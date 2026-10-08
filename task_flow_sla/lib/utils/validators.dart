/// Form validation rules. Each returns an error message, or null when valid.
class Validators {
  static const titleMinLength = 3;
  static const titleMaxLength = 60;
  static const descriptionMaxLength = 300;
  static const passwordMinLength = 6;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? taskTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.length < titleMinLength || title.length > titleMaxLength) {
      return 'Title is required ($titleMinLength-$titleMaxLength characters)';
    }
    return null;
  }

  /// The due date must be in the future. When editing, the task's [original]
  /// due date is still accepted so an overdue task can be edited.
  static String? dueDate(DateTime? value, {DateTime? original, DateTime? now}) {
    if (value == null) return 'Pick a due date and time';
    if (value == original) return null;
    if (!value.isAfter(now ?? DateTime.now())) {
      return 'Due date must be in the future';
    }
    return null;
  }

  static String? requiredText(String? value, String fieldName, {int min = 2}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$fieldName is required';
    if (text.length < min) return '$fieldName must be at least $min characters';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < passwordMinLength) {
      return 'Password must be at least $passwordMinLength characters';
    }
    return null;
  }
}
