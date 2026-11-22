import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/app.dart';
import 'package:reading_management/core/app_drawer_button.dart';
import 'package:reading_management/core/surpresa.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';
import 'package:reading_management/features/works/works_providers.dart';

ProviderScope buildAppComSurpresa() => ProviderScope(
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
    );

void main() {
  testWidgets('a surpresa só aparece após a sequência secreta de toques no logo',
      (tester) async {
    await tester.pumpWidget(buildAppComSurpresa());
    await tester.pumpAndSettle();

    expect(find.byType(SurpresaOverlay), findsNothing);
    expect(find.byType(LogoComSurpresa), findsNothing);

    await tester.tap(find.byType(AppDrawerButton));
    await tester.pumpAndSettle();

    expect(find.byType(LogoComSurpresa), findsOneWidget);

    // Menos toques que o necessário não revelam nada.
    for (var i = 0; i < LogoComSurpresa.tapsRequired - 1; i++) {
      await tester.tap(find.byType(LogoComSurpresa));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    expect(find.byType(SurpresaOverlay), findsNothing);

    // O último toque completa o gesto.
    await tester.tap(find.byType(LogoComSurpresa));
    await tester.pumpAndSettle();

    expect(find.byType(SurpresaOverlay), findsOneWidget);
    expect(find.text('Vai Corinthians!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Um toque na tela fecha a surpresa e volta ao app normal.
    await tester.tap(find.byType(SurpresaOverlay));
    await tester.pumpAndSettle();

    expect(find.byType(SurpresaOverlay), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
