import 'package:flutter/material.dart';

import '../../core/strings.dart';

class AnalysesScreen extends StatelessWidget {
  const AnalysesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.analyses)),
      body: const SizedBox.shrink(),
    );
  }
}
