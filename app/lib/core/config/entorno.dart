class EntornoApp {
  const EntornoApp._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fovvgqurnztnjcibtopq.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable__OLs173ROXP4ETaNzA4EKQ_1fYYxUxo',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvdnZncXVybnp0bmpjaWJ0b3BxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNDU2OTksImV4cCI6MjEwODYyMTY5OX0.H3WM2nttxQzy7_QftW8UXgn07SrdpgSIJdEJOjyG5No',
  );

  static const String powerSyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
    defaultValue: 'https://6adfc85231f8906225acc79f.powersync.journeyapps.com',
  );
}
