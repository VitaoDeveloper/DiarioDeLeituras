import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/app.dart';
import 'package:reading_management/core/strings.dart';

void main() {
  testWidgets('exibe a navegação inferior com as quatro abas', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text(AppStrings.works), findsWidgets);
  });
}
