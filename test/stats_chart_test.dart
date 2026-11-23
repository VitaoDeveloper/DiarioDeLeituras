import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/core/formatters.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_chart.dart';
import 'package:reading_management/features/stats/stats_providers.dart';
import 'package:reading_management/features/stats/stats_screen.dart';
import 'package:reading_management/features/works/readings_providers.dart';
import 'package:reading_management/features/works/works_providers.dart';

Widget _emptyStatsScreen() => ProviderScope(
  overrides: [
    worksProvider.overrideWith((ref) => Stream.value(const <Work>[])),
    readingsProvider.overrideWith((ref) => Stream.value(const <Reading>[])),
    readingSessionsProvider.overrideWith(
      (ref) => Stream.value(const <ReadingSession>[]),
    ),
    streakProvider.overrideWithValue(
      const StreakInfo(current: 0, best: 0, atRisk: false, readDays: <int>{}),
    ),
  ],
  child: const MaterialApp(home: StatsScreen()),
);

void main() {
  setUpAll(() async {
    await initializeFormatting();
  });

  group('niceAxis', () {
    test('arredonda maxY para cima e mantém no máximo cinco rótulos', () {
      final cases = <double, ({double maxY, double interval})>{
        0: (maxY: 1, interval: 1),
        1: (maxY: 1, interval: 1),
        7: (maxY: 10, interval: 5),
        38: (maxY: 50, interval: 20),
        134: (maxY: 200, interval: 50),
        162: (maxY: 200, interval: 50),
        1000: (maxY: 1000, interval: 500),
      };

      for (final entry in cases.entries) {
        final axis = niceAxis(entry.key);
        expect(axis.maxY, entry.value.maxY, reason: 'maxY de ${entry.key}');
        expect(
          axis.interval,
          entry.value.interval,
          reason: 'interval de ${entry.key}',
        );
        expect(axis.interval, greaterThanOrEqualTo(1));
        expect(axis.maxY / axis.interval, lessThanOrEqualTo(4));
      }
    });

    test('não gera valores inválidos para entradas vazias ou inválidas', () {
      for (final value in <double>[-3, double.nan, double.infinity]) {
        final axis = niceAxis(value);
        expect(axis.maxY, 1);
        expect(axis.interval, 1);
      }
    });
  });

  group('rótulos do eixo X', () {
    for (final daysInMonth in <int>[28, 30, 31]) {
      test('mês de $daysInMonth dias mostra dias únicos e espaçados', () {
        final labels = visibleMonthDayLabels(daysInMonth).toList()..sort();

        expect(labels.first, 1);
        expect(labels.last, daysInMonth);
        expect(labels, containsAll(<int>[5, 10, 15, 20, 25]));
        expect(labels.toSet().length, labels.length);
        for (var index = 1; index < labels.length; index++) {
          expect(labels[index] - labels[index - 1], greaterThanOrEqualTo(3));
        }
        expect(shouldShowMonthDayLabel(2, daysInMonth), isFalse);
        expect(shouldShowMonthDayLabel(21, daysInMonth), isFalse);
      });
    }
  });

  test('resumo e tooltip usam textos pt-BR', () {
    final data = [
      const StatsDatum(label: '21 de nov', value: 134),
      const StatsDatum(label: '22 de nov', value: 56),
    ];

    expect(
      statsSummaryText(StatsValueKind.pages, data),
      '${AppStrings.chartTotalLabel}: 190 ${AppStrings.pagePlural}',
    );
    expect(
      statsValueText(StatsValueKind.pages, 134),
      '134 ${AppStrings.pagePlural}',
    );
    expect(
      statsValueText(StatsValueKind.works, 3),
      AppStrings.workCountLabel(3),
    );
    expect(
      statsValueText(StatsValueKind.ratings, 4.5, detail: '2 leituras'),
      '4,5 (2 leituras)',
    );
    expect(abbreviatedLabel('Ficção científica', maxLength: 8), 'Ficção…');
    expect(statsAxisText(StatsValueKind.pages, 1000), '1.000');
  });

  testWidgets('gráfico de 30 dias não estoura em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = [
      for (var day = 1; day <= 30; day++)
        StatsDatum(label: '$day', value: day == 21 ? 134 : 0),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 288,
              height: 220,
              child: StatsBarChart(
                data: data,
                kind: StatsValueKind.pages,
                mode: StatsXAxisMode.days,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatsBarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seletor Dia/Mês troca a granularidade e o vazio é legível', (
    tester,
  ) async {
    await tester.pumpWidget(_emptyStatsScreen());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.granularityDay), findsOneWidget);
    expect(find.text(AppStrings.periodMonth), findsOneWidget);
    expect(find.text(AppStrings.emptyWorksChart), findsWidgets);
    expect(find.text(AppStrings.emptySessionsChart), findsOneWidget);

    await tester.scrollUntilVisible(find.text(AppStrings.periodMonth), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.periodMonth));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.granularityDay), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
