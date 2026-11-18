import 'package:flutter/material.dart';

import '../../core/strings.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notes)),
      body: const SizedBox.shrink(),
    );
  }
}
