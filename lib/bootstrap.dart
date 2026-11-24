import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/env.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
  url: 'https://ijwrevmzukmrlckmwbzj.supabase.co',
  publishableKey: Env.supabasePublishableKey.trim(),
);

  runApp(
    const ProviderScope(
      child: HydrofixApp(),
    ),
  );
} 