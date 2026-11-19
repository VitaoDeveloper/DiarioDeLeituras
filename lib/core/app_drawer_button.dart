import 'package:flutter/material.dart';

import 'router.dart';

/// Botão de abrir o menu lateral, usado no leading das AppBars das seções.
class AppDrawerButton extends StatelessWidget {
  const AppDrawerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: openAppDrawer,
    );
  }
}
