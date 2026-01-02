import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://zuksfgjhfdrgeoxtvvyn.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1a3NmZ2poZmRyZ2VveHR2dnluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNzAyODAsImV4cCI6MjA3ODY0NjI4MH0.rPZWKSJA5vHScr-o4f5e4gwNs1cxpRMYjPV-X6CkNxo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

