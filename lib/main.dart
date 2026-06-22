import 'package:flutter/material.dart';
import 'features/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cxoawhfrdkwtpolhjfqn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4b2F3aGZyZGt3dHBvbGhqZnFuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MjMwOTgsImV4cCI6MjA5MTA5OTA5OH0.5HcezX2HK_9Yw9t5upnn2PRqwcTwqbm3FMA9T2S-ojA',
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
