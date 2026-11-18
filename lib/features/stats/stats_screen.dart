import 'package:flutter/material.dart';

import '../../core/strings.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.stats)),
      body: const SizedBox.shrink(),
    );
  }
}
