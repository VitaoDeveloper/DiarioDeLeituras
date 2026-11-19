import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_drawer_button.dart';
import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../works/works_providers.dart';
import 'stats_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.month;
  DateTime _reference = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftPeriod(int delta) {
    setState(() {
      _reference = _period == StatsPeriod.month
          ? DateTime(_reference.year, _reference.month + delta)
          : DateTime(_reference.year + delta);
    });
  }

  void _shiftCalendar(int delta) {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + delta,
      );
    });
  }

  Widget _barChart(List<StatsDatum> data) {
    final color = Theme.of(context).colorScheme.primary;
    final maxValue = data.fold<double>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    final labelInterval = data.length > 12 ? (data.length / 8).ceil() : 1;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue == 0 ? 1 : maxValue * 1.2,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: labelInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final label = data[index].label;
                  final shortLabel = label.length > 8
                      ? '${label.substring(0, 8)}…'
                      : label;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(shortLabel, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: [
            for (var index = 0; index < data.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data[index].value,
                    color: color,
                    width: 12,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(
    String title,
    List<StatsDatum> data,
    String? emptyMessage, {
    bool showDetail = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (emptyMessage != null)
              Text(emptyMessage)
            else ...[
              _barChart(data),
              if (showDetail) ...[
                const SizedBox(height: 8),
                for (final item in data)
                  Text(
                    '${item.label}: ${formatRating(item.value)} '
                    '(${item.detail ?? ''})',
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

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
    final key = dayKey(DateTime(_calendarMonth.year, _calendarMonth.month, day));
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
    final leading = DateTime(
      _calendarMonth.year,
      _calendarMonth.month,
      1,
    ).weekday - 1;
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
                child: index + offset < cells.length &&
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
                  child: Center(
                    child: Text(formatMonthYear(_calendarMonth)),
                  ),
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
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        SegmentedButton<StatsPeriod>(
          segments: const [
            ButtonSegment(
              value: StatsPeriod.month,
              label: Text(AppStrings.periodMonth),
            ),
            ButtonSegment(
              value: StatsPeriod.year,
              label: Text(AppStrings.periodYear),
            ),
          ],
          selected: {_period},
          onSelectionChanged: (selection) => setState(() {
            _period = selection.first;
            _reference = DateTime(DateTime.now().year, DateTime.now().month);
          }),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _shiftPeriod(-1),
              icon: const Icon(Icons.arrow_back),
              tooltip: AppStrings.previousPeriod,
            ),
            Text(
              _period == StatsPeriod.month
                  ? formatMonthYear(_reference)
                  : _reference.year.toString(),
            ),
            IconButton(
              onPressed: () => _shiftPeriod(1),
              icon: const Icon(Icons.arrow_forward),
              tooltip: AppStrings.nextPeriod,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final worksAsync = ref.watch(worksProvider);
    final sessionsAsync = ref.watch(readingSessionsProvider);

    if (worksAsync.isLoading || sessionsAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.stats),
          leading: const AppDrawerButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (worksAsync.hasError || sessionsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.stats),
          leading: const AppDrawerButton(),
        ),
        body: const Center(child: Text(AppStrings.loadError)),
      );
    }

    final streak = ref.watch(streakProvider);
    final filter = (period: _period, reference: _reference);
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
              summary.statusCounts,
              summary.hasWorks ? null : AppStrings.emptyWorksChart,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.typeChart,
              summary.typeCounts,
              summary.hasWorks ? null : AppStrings.emptyWorksChart,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.genreChart,
              summary.genreCounts,
              summary.hasWorks ? null : AppStrings.emptyWorksChart,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.pagesChart,
              summary.pagesSeries,
              !summary.hasSessions
                  ? AppStrings.emptySessionsChart
                  : summary.hasPagesInPeriod
                      ? null
                      : AppStrings.emptyPeriod,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.completedChart,
              summary.completedSeries,
              !summary.hasFinishedWorks
                  ? AppStrings.emptyFinishedChart
                  : summary.hasCompletedInPeriod
                      ? null
                      : AppStrings.emptyPeriod,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.ratingByGenre,
              summary.ratingByGenre,
              summary.hasRatings ? null : AppStrings.emptyRatingsChart,
              showDetail: true,
            ),
            const SizedBox(height: 16),
            _chartCard(
              AppStrings.ratingByAuthor,
              summary.ratingByAuthor,
              summary.hasRatings ? null : AppStrings.emptyRatingsChart,
              showDetail: true,
            ),
          ],
        ),
      ),
    );
  }
}
