import 'package:flutter/material.dart';

import 'core/theme/hydrofix_theme.dart';
import 'features/stitch_ui/hydrofix_stitch_screens.dart';

class HydrofixApp extends StatelessWidget {
  const HydrofixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroFix',

      debugShowCheckedModeBanner: false,

      theme: HydroTheme.light,

      home: const HydroWelcome(),
    );
  }
}