import 'package:fl_chart/fl_chart.dart';
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

Widget _statsScreen({
  List<Work> works = const [],
  List<Reading> readings = const [],
  List<ReadingSession> sessions = const [],
}) => ProviderScope(
  overrides: [
    worksProvider.overrideWith((ref) => Stream.value(works)),
    readingsProvider.overrideWith((ref) => Stream.value(readings)),
    readingSessionsProvider.overrideWith((ref) => Stream.value(sessions)),
    streakProvider.overrideWithValue(
      const StreakInfo(current: 0, best: 0, atRisk: false, readDays: <int>{}),
    ),
  ],
  child: const MaterialApp(home: StatsScreen()),
);

Widget _emptyStatsScreen() => _statsScreen();

Work _work() => Work(
  id: 1,
  type: WorkType.livro,
  title: 'Obra',
  author: 'Autor',
  genre: 'Ficção',
  status: WorkStatus.lido,
  createdAt: DateTime(2026, 1, 1),
);

Reading _reading() => Reading(
  id: 1,
  workId: 1,
  number: 1,
  status: WorkStatus.lido,
  rating: 4,
  finishedAt: DateTime(2026, 11, 3),
  createdAt: DateTime(2026, 1, 1),
);

ReadingSession _session() => ReadingSession(
  id: 1,
  workId: 1,
  readingId: 1,
  date: DateTime(2026, 11, 3),
  pagesRead: 12,
  note: null,
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
        180: (maxY: 200, interval: 50),
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
        expect(statsAxisValues(axis).length, lessThanOrEqualTo(5));
        expect(statsAxisValues(axis).last, lessThanOrEqualTo(axis.maxY));
        expect(
          statsAxisValues(axis).every((tick) => tick == tick.roundToDouble()),
          isTrue,
        );
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

  test('largura padrão do slot das barras fica entre 36 e 48 dp', () {
    const chart = StatsBarChart(data: [], kind: StatsValueKind.pages);
    expect(chart.barSlotWidth, inInclusiveRange(36, 48));
  });

  testWidgets('período abre no dado mais recente e rola até o mais antigo', (
    tester,
  ) async {
    final data = [
      for (var day = 1; day <= 40; day++)
        StatsDatum(
          label: '$day',
          value: day == 1
              ? 5
              : day == 40
              ? 134
              : 0,
          groupLabel: day == 1
              ? 'nov/2026'
              : day == 32
              ? 'dez/2026'
              : null,
          fullLabel: '$day de nov de 2026',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: StatsBarChart(
              data: data,
              kind: StatsValueKind.pages,
              mode: StatsXAxisMode.days,
              scrollable: true,
              tooltipLabelBuilder: (item, index) =>
                  item.fullLabel ?? item.label,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollFinder = find.byType(SingleChildScrollView);
    expect(scrollFinder, findsOneWidget);
    final controller = tester
        .widget<SingleChildScrollView>(scrollFinder)
        .controller!;
    expect(controller.position.maxScrollExtent, greaterThan(0));
    expect(controller.offset, controller.position.maxScrollExtent);
    expect(find.text('40'), findsOneWidget);

    // O eixo Y com os valores numéricos fica fora da área rolável.
    expect(find.text('200'), findsOneWidget);
    expect(
      find.descendant(of: scrollFinder, matching: find.text('200')),
      findsNothing,
    );

    // Tooltip continua disponível no toque e usa o rótulo completo da data.
    final barChart = tester.widget<BarChart>(find.byType(BarChart));
    expect(barChart.data.barTouchData.enabled, isTrue);
    final tooltip = barChart.data.barTouchData.touchTooltipData.getTooltipItem(
      BarChartGroupData(x: 39, barRods: [BarChartRodData(toY: 134)]),
      39,
      BarChartRodData(toY: 134),
      0,
    );
    expect(tooltip, isNotNull);
    expect(tooltip!.text, contains('40 de nov de 2026'));
    expect(tooltip.text, contains('134'));

    controller.jumpTo(0);
    await tester.pumpAndSettle();

    expect(controller.offset, 0);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('nov/2026'), findsOneWidget);
    expect(find.text('dez/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cards mostram subtítulo, títulos dos eixos e resumo do período',
    (tester) async {
      await tester.pumpWidget(
        _statsScreen(
          works: [_work()],
          readings: [_reading()],
          sessions: [_session()],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          AppStrings.chartSubtitle(
            AppStrings.pagesRead,
            AppStrings.granularityDay,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          AppStrings.chartAxisLabel(
            AppStrings.granularityDay,
            AppStrings.pages,
          ),
        ),
        findsNothing,
      );
      expect(
        find.text(AppStrings.chartAxisLabel(AppStrings.type, AppStrings.works)),
        findsNothing,
      );
      // Um título no seletor Dia/Mês e um em cada gráfico de período.
      expect(find.text(AppStrings.granularityDay), findsNWidgets(3));
      expect(find.text(AppStrings.works), findsWidgets);
      expect(find.textContaining(AppStrings.totalVisiblePeriod), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('títulos dos eixos ficam fixos na origem do gráfico', (
    tester,
  ) async {
    final data = [
      const StatsDatum(label: '1', value: 134),
      const StatsDatum(label: '2', value: 56),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: StatsBarChart(
              data: data,
              kind: StatsValueKind.pages,
              mode: StatsXAxisMode.days,
              scrollable: true,
              axisXTitle: 'Dia',
              axisYTitle: 'Páginas',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dia'), findsOneWidget);
    expect(find.text('Páginas'), findsOneWidget);
    final rotated = find.byWidgetPredicate(
      (widget) => widget is RotatedBox && widget.quarterTurns == 3,
    );
    expect(rotated, findsOneWidget);
    expect(
      find.descendant(of: rotated, matching: find.text('Páginas')),
      findsOneWidget,
    );

    final scroll = find.byType(SingleChildScrollView);
    expect(
      find.descendant(of: scroll, matching: find.text('Dia')),
      findsNothing,
    );
    expect(
      find.descendant(of: scroll, matching: find.text('Páginas')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  test('rótulos extremos do eixo Y cabem na área útil', () {
    const plotHeight = 220 - 2 * statsVerticalInset - statsXTitleHeight - 44.0;
    final axis = niceAxis(134);

    for (final kind in <StatsValueKind>[
      StatsValueKind.pages,
      StatsValueKind.readings,
    ]) {
      for (final tick in <double>[0, axis.maxY]) {
        final top = statsAxisLabelTop(tick, axis, plotHeight);
        expect(top, greaterThanOrEqualTo(0), reason: '$kind no tick $tick');
        expect(
          top + statsTickTextHeight,
          lessThanOrEqualTo(plotHeight),
          reason: '$kind no tick $tick',
        );
      }
    }
  });

  testWidgets('todos os rótulos do eixo Y dos gráficos de período cabem', (
    tester,
  ) async {
    await tester.pumpWidget(
      _statsScreen(
        works: [_work()],
        readings: [_reading()],
        sessions: [_session()],
      ),
    );
    await tester.pumpAndSettle();

    final axes = find.byKey(const Key('stats-fixed-y-axis'));
    expect(axes, findsNWidgets(2));

    for (var index = 0; index < axes.evaluate().length; index++) {
      final axis = axes.at(index);
      final axisBox = tester.renderObject<RenderBox>(axis);
      final axisTop = axisBox.localToGlobal(Offset.zero).dy;
      final axisBottom = axisBox
          .localToGlobal(Offset(0, axisBox.size.height))
          .dy;

      final labels = find.descendant(of: axis, matching: find.byType(Text));
      expect(labels, findsWidgets, reason: 'eixo $index');
      for (
        var labelIndex = 0;
        labelIndex < labels.evaluate().length;
        labelIndex++
      ) {
        final labelBox = tester.renderObject<RenderBox>(labels.at(labelIndex));
        final labelTop = labelBox.localToGlobal(Offset.zero).dy;
        final labelBottom = labelBox
            .localToGlobal(Offset(0, labelBox.size.height))
            .dy;
        expect(
          labelTop,
          greaterThanOrEqualTo(axisTop - 1),
          reason: 'eixo $index, rótulo $labelIndex',
        );
        expect(
          labelBottom,
          lessThanOrEqualTo(axisBottom + 1),
          reason: 'eixo $index, rótulo $labelIndex',
        );
      }
    }
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
