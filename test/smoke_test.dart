import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/app.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';
import 'package:reading_management/features/works/works_providers.dart';

void main() {
  testWidgets('exibe a navegação inferior com as quatro abas', (tester) async {
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

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text(AppStrings.works), findsWidgets);
  });
}
