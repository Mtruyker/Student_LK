import 'package:supabase_flutter/supabase_flutter.dart';

enum AppUserRole {
  student,
  teacher,
  admin,
}

extension AppUserRoleX on AppUserRole {
  String get value {
    switch (this) {
      case AppUserRole.student:
        return 'student';
      case AppUserRole.teacher:
        return 'teacher';
      case AppUserRole.admin:
        return 'admin';
    }
  }
}

AppUserRole? appUserRoleFromClaims(Map<String, dynamic>? claims) {
  final rawRole = claims?['role']?.toString().trim().toLowerCase();
  switch (rawRole) {
    case 'student':
      return AppUserRole.student;
    case 'teacher':
      return AppUserRole.teacher;
    case 'admin':
      return AppUserRole.admin;
    default:
      return null;
  }
}

AppUserRole? appUserRoleFromUser(User? user) {
  return appUserRoleFromClaims(user?.appMetadata);
}

bool userHasRole(User? user, AppUserRole role) {
  return appUserRoleFromUser(user) == role;
}
