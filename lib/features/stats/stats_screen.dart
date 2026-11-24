import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_drawer_button.dart';
import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../works/readings_providers.dart';
import '../works/works_providers.dart';
import 'stats_chart.dart';
import 'stats_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsGranularity _granularity = StatsGranularity.day;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftCalendar(int delta) {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + delta,
      );
    });
  }

  Widget _chartCard(
    String title, {
    required String subtitle,
    required String axisXTitle,
    required String axisYTitle,
    required List<StatsDatum> data,
    required StatsValueKind kind,
    String? emptyMessage,
    StatsXAxisMode mode = StatsXAxisMode.categories,
    bool horizontal = false,
    int maxInitialItems = 8,
    double height = 220,
    bool periodSummary = false,
    bool scrollable = false,
    String Function(StatsDatum item, int index)? tooltipLabelBuilder,
  }) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: captionStyle),
            const SizedBox(height: 8),
            if (emptyMessage != null)
              Text(emptyMessage, style: captionStyle)
            else ...[
              Text(
                statsSummaryText(
                  kind,
                  data,
                  label: periodSummary
                      ? AppStrings.totalVisiblePeriod
                      : AppStrings.chartTotalLabel,
                ),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              StatsBarChart(
                data: data,
                kind: kind,
                mode: mode,
                horizontal: horizontal,
                scrollable: scrollable,
                maxInitialItems: maxInitialItems,
                height: height,
                axisXTitle: axisXTitle,
                axisYTitle: axisYTitle,
                tooltipLabelBuilder: tooltipLabelBuilder,
              ),
            ],
          ],
        ),
      ),
    );
  }

  StatsXAxisMode get _periodAxisMode => _granularity == StatsGranularity.day
      ? StatsXAxisMode.days
      : StatsXAxisMode.months;

  String Function(StatsDatum item, int index)? get _periodTooltipLabel =>
      _granularity == StatsGranularity.day
      ? (item, index) => item.fullLabel ?? item.label
      : null;

  String get _granularityLabel => _granularity == StatsGranularity.day
      ? AppStrings.granularityDay
      : AppStrings.periodMonth;

  Widget _streakCard(StreakInfo streak) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.currentStreak,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.streakLabel(streak.current),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (streak.atRisk) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${AppStrings.streakAtRisk} • ${AppStrings.readTodayHint}',
                    ),
                  ),
                ],
              ),
            ] else if (streak.current == 0) ...[
              const SizedBox(height: 4),
              const Text(AppStrings.noStreak),
            ],
            const SizedBox(height: 8),
            Text(
              '${AppStrings.bestStreak}: '
              '${AppStrings.streakLabel(streak.best)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(int day, Set<int> readDays) {
    final key = dayKey(
      DateTime(_calendarMonth.year, _calendarMonth.month, day),
    );
    final read = readDays.contains(key);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$day'),
        if (read)
          const Icon(Icons.check, size: 14)
        else
          const SizedBox(height: 14),
      ],
    );
  }

  Widget _calendarCard(Set<int> readDays) {
    final daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;
    final leading =
        DateTime(_calendarMonth.year, _calendarMonth.month, 1).weekday - 1;
    final cells = <int?>[
      for (var index = 0; index < leading; index++) null,
      for (var day = 1; day <= daysInMonth; day++) day,
    ];
    final rows = <TableRow>[
      TableRow(
        children: [
          for (final weekday in AppStrings.weekdayInitials)
            Center(child: Text(weekday)),
        ],
      ),
    ];
    for (var index = 0; index < cells.length; index += 7) {
      rows.add(
        TableRow(
          children: [
            for (var offset = 0; offset < 7; offset++) ...[
              Center(
                child:
                    index + offset < cells.length &&
                        cells[index + offset] != null
                    ? _dayCell(cells[index + offset]!, readDays)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _shiftCalendar(-1),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: AppStrings.previousPeriod,
                ),
                Expanded(
                  child: Center(child: Text(formatMonthYear(_calendarMonth))),
                ),
                IconButton(
                  onPressed: () => _shiftCalendar(1),
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: AppStrings.nextPeriod,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Table(
              defaultColumnWidth: const FixedColumnWidth(40),
              children: rows,
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodSelector() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<StatsGranularity>(
        segments: const [
          ButtonSegment(
            value: StatsGranularity.day,
            label: Text(AppStrings.granularityDay),
          ),
          ButtonSegment(
            value: StatsGranularity.month,
            label: Text(AppStrings.periodMonth),
          ),
        ],
        selected: {_granularity},
        onSelectionChanged: (selection) =>
            setState(() => _granularity = selection.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worksAsync = ref.watch(worksProvider);
    final readingsAsync = ref.watch(readingsProvider);
    final sessionsAsync = ref.watch(readingSessionsProvider);

    if (worksAsync.isLoading ||
        readingsAsync.isLoading ||
        sessionsAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.stats),
          leading: const AppDrawerButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (worksAsync.hasError ||
        readingsAsync.hasError ||
        sessionsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.stats),
          leading: const AppDrawerButton(),
        ),
        body: const Center(child: Text(AppStrings.loadError)),
      );
    }

    final streak = ref.watch(streakProvider);
    final filter = (granularity: _granularity);
    final summary = ref.watch(statsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.stats),
        leading: const AppDrawerButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _streakCard(streak),
            const SizedBox(height: 16),
            _calendarCard(streak.readDays),
            const SizedBox(height: 16),
            _periodSelector(),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.statusChart,
              subtitle: AppStrings.chartSubtitle(
                AppStrings.readings,
                AppStrings.status.toLowerCase(),
              ),
              axisXTitle: AppStrings.status,
              axisYTitle: AppStrings.readings,
              data: summary.statusCounts,
              emptyMessage: summary.hasReadings
                  ? null
                  : summary.hasWorks
                  ? AppStrings.emptyReadingsChart
                  : AppStrings.emptyWorksChart,
              kind: StatsValueKind.readings,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.typeChart,
              subtitle: AppStrings.chartSubtitle(
                AppStrings.works,
                AppStrings.type.toLowerCase(),
              ),
              axisXTitle: AppStrings.type,
              axisYTitle: AppStrings.works,
              data: summary.typeCounts,
              emptyMessage: summary.hasWorks
                  ? null
                  : AppStrings.emptyWorksChart,
              kind: StatsValueKind.works,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.genreChart,
              subtitle: AppStrings.chartSubtitle(
                AppStrings.works,
                AppStrings.genre.toLowerCase(),
              ),
              axisXTitle: AppStrings.genre,
              axisYTitle: AppStrings.works,
              data: summary.genreCounts,
              emptyMessage: summary.hasWorks
                  ? null
                  : AppStrings.emptyWorksChart,
              kind: StatsValueKind.works,
              horizontal: true,
              height: 300,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.pagesChart,
              subtitle: AppStrings.chartSubtitle(
                AppStrings.pagesRead,
                _granularityLabel,
              ),
              axisXTitle: _granularityLabel,
              axisYTitle: AppStrings.pages,
              data: summary.pagesSeries,
              emptyMessage: !summary.hasSessions
                  ? AppStrings.emptySessionsChart
                  : summary.hasPagesInPeriod
                  ? null
                  : AppStrings.emptyStatsPeriod,
              kind: StatsValueKind.pages,
              mode: _periodAxisMode,
              periodSummary: true,
              scrollable: true,
              tooltipLabelBuilder: _periodTooltipLabel,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.completedChart,
              subtitle: AppStrings.chartSubtitle(
                AppStrings.completedReadings,
                _granularityLabel,
              ),
              axisXTitle: _granularityLabel,
              axisYTitle: AppStrings.completedReadings,
              data: summary.completedSeries,
              emptyMessage: !summary.hasFinishedReadings
                  ? AppStrings.emptyFinishedChart
                  : summary.hasCompletedInPeriod
                  ? null
                  : AppStrings.emptyStatsPeriod,
              kind: StatsValueKind.readings,
              mode: _periodAxisMode,
              periodSummary: true,
              scrollable: true,
              tooltipLabelBuilder: _periodTooltipLabel,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.ratingByGenre,
              subtitle: AppStrings.ratingByGenreSubtitle,
              axisXTitle: AppStrings.genre,
              axisYTitle: AppStrings.axisAverageRating,
              data: summary.ratingByGenre,
              emptyMessage: summary.hasRatings
                  ? null
                  : AppStrings.emptyRatingsChart,
              kind: StatsValueKind.ratings,
              horizontal: true,
              maxInitialItems: 6,
              height: 280,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.ratingByAuthor,
              subtitle: AppStrings.ratingByAuthorSubtitle,
              axisXTitle: AppStrings.author,
              axisYTitle: AppStrings.axisAverageRating,
              data: summary.ratingByAuthor,
              emptyMessage: summary.hasRatings
                  ? null
                  : AppStrings.emptyRatingsChart,
              kind: StatsValueKind.ratings,
              horizontal: true,
              maxInitialItems: 6,
              height: 280,
            ),
          ],
        ),
      ),
    );
  }
}
