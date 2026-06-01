class AppEnvironment {
  const AppEnvironment._();

  static const bool useSupabase = bool.fromEnvironment(
    'USE_SUPABASE',
    defaultValue: true,
  );

  static const bool enableLegacyApi = bool.fromEnvironment(
    'ENABLE_LEGACY_API',
    defaultValue: false,
  );

  static const bool enableDemoMode = bool.fromEnvironment(
    'ENABLE_DEMO_MODE',
    defaultValue: false,
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String supabasePasswordResetRedirectUrl =
      String.fromEnvironment('SUPABASE_PASSWORD_RESET_REDIRECT_URL');

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String defaultAdminEmail = String.fromEnvironment(
    'DEFAULT_ADMIN_EMAIL',
  );
  static const String defaultAdminPassword = String.fromEnvironment(
    'DEFAULT_ADMIN_PASSWORD',
  );
  static const String defaultTeacherEmail = String.fromEnvironment(
    'DEFAULT_TEACHER_EMAIL',
  );
  static const String defaultTeacherPassword = String.fromEnvironment(
    'DEFAULT_TEACHER_PASSWORD',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static bool get hasLegacyApiConfig => apiBaseUrl.trim().isNotEmpty;

  static String? get optionalPasswordResetRedirectUrl {
    final value = supabasePasswordResetRedirectUrl.trim();
    return value.isEmpty ? null : value;
  }
}
