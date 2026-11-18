import 'package:flutter/material.dart';

import '../../core/strings.dart';

class WorksScreen extends StatelessWidget {
  const WorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.works)),
      body: const SizedBox.shrink(),
    );
  }
}
