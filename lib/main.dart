import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFormatting();
  runApp(const ProviderScope(child: App()));
}
