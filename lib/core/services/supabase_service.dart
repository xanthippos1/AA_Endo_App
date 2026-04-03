import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://mjaplyzvhffxuxhsioyp.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1qYXBseXp2aGZmeHV4aHNpb3lwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzc1NzcsImV4cCI6MjA5MDgxMzU3N30.UJXUzMLOJ-MGvfhcfHvIKWkF0X_GmZb909Z2oKKRPFY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
