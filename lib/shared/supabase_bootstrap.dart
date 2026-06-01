import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_environment.dart';

bool isSupabaseInitialized() {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> ensureSupabaseInitialized() async {
  if (!AppEnvironment.useSupabase) {
    return;
  }

  if (isSupabaseInitialized()) {
    return;
  }

  if (!AppEnvironment.hasSupabaseConfig) {
    throw StateError(
      'Supabase is enabled, but SUPABASE_URL or SUPABASE_ANON_KEY is missing. '
      'Pass them with --dart-define.',
    );
  }

  await Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    anonKey: AppEnvironment.supabaseAnonKey,
  );
}
