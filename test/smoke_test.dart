import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/app.dart';
import 'package:reading_management/core/app_drawer_button.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';
import 'package:reading_management/features/works/works_providers.dart';

void main() {
  testWidgets('exibe o menu lateral com as quatro seções', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worksProvider.overrideWith((ref) => Stream.value(const <Work>[])),
          genresProvider.overrideWithValue(const <String>[]),
          streakProvider.overrideWithValue(
            const StreakInfo(
              current: 0,
              best: 0,
              atRisk: false,
              readDays: <int>{},
            ),
          ),
        ],
        child: const App(),
      ),
    );

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(AppDrawerButton), findsOneWidget);

    await tester.tap(find.byType(AppDrawerButton));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationDrawerDestination), findsNWidgets(5));
    expect(find.text(AppStrings.works), findsWidgets);
    expect(find.text(AppStrings.notes), findsWidgets);
    expect(find.text(AppStrings.analyses), findsWidgets);
    expect(find.text(AppStrings.stats), findsWidgets);
    expect(find.text(AppStrings.settings), findsWidgets);
  });
}
