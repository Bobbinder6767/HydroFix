import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl {
    return dotenv.env['https://krthhpxkmsqaevlzfwld.supabase.co/'] ?? '';
  }

  static String get supabasePublishableKey {
    return dotenv.env['sb_publishable_EDCTvgwY0idSHNonnArtng_GT-eG5nL'] ?? '';
  }
}