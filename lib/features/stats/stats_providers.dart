import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../works/readings_providers.dart';
import '../works/works_providers.dart';

enum StatsPeriod { month, year }

typedef StatsFilter = ({StatsPeriod period, DateTime reference});

class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.atRisk,
    required this.readDays,
  });

  final int current;
  final int best;
  final bool atRisk;
  final Set<int> readDays;
}

class StatsDatum {
  const StatsDatum({required this.label, required this.value, this.detail});

  final String label;
  final double value;
  final String? detail;
}

class StatsSummary {
  const StatsSummary({
    required this.statusCounts,
    required this.typeCounts,
    required this.genreCounts,
    required this.pagesSeries,
    required this.completedSeries,
    required this.ratingByGenre,
    required this.ratingByAuthor,
    required this.hasWorks,
    required this.hasReadings,
    required this.hasSessions,
    required this.hasPagesInPeriod,
    required this.hasFinishedReadings,
    required this.hasCompletedInPeriod,
    required this.hasRatings,
  });

  final List<StatsDatum> statusCounts;
  final List<StatsDatum> typeCounts;
  final List<StatsDatum> genreCounts;
  final List<StatsDatum> pagesSeries;
  final List<StatsDatum> completedSeries;
  final List<StatsDatum> ratingByGenre;
  final List<StatsDatum> ratingByAuthor;
  final bool hasWorks;
  final bool hasReadings;
  final bool hasSessions;
  final bool hasPagesInPeriod;
  final bool hasFinishedReadings;
  final bool hasCompletedInPeriod;
  final bool hasRatings;
}

int dayKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;

DateTime _dateFromKey(int key) =>
    DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);

int _previousDay(int key) =>
    dayKey(_dateFromKey(key).subtract(const Duration(days: 1)));

int _nextDay(int key) => dayKey(_dateFromKey(key).add(const Duration(days: 1)));

Set<int> readDayKeys(List<ReadingSession> sessions, {DateTime? now}) {
  final today = dayKey(now ?? DateTime.now());
  return sessions
      .where((session) => session.pagesRead > 0)
      .map((session) => dayKey(session.date))
      .where((key) => key <= today)
      .toSet();
}

int _bestStreak(Set<int> days) {
  if (days.isEmpty) return 0;
  final sorted = days.toList()..sort();
  var best = 0;
  var run = 0;
  int? previous;
  for (final day in sorted) {
    run = previous != null && day == _nextDay(previous) ? run + 1 : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}

StreakInfo calculateStreak(List<ReadingSession> sessions, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = dayKey(reference);
  final yesterday = dayKey(reference.subtract(const Duration(days: 1)));
  final days = readDayKeys(sessions, now: reference);

  var cursor = today;
  var atRisk = false;
  if (!days.contains(cursor)) {
    if (!days.contains(yesterday)) {
      return StreakInfo(
        current: 0,
        best: _bestStreak(days),
        atRisk: false,
        readDays: days,
      );
    }
    cursor = yesterday;
    atRisk = true;
  }

  var current = 0;
  while (days.contains(cursor)) {
    current++;
    cursor = _previousDay(cursor);
  }

  return StreakInfo(
    current: current,
    best: _bestStreak(days),
    atRisk: atRisk,
    readDays: days,
  );
}

List<StatsDatum> _counts(Iterable<String> values, List<String> preferredOrder) {
  final counts = <String, int>{};
  for (final value in values) {
    final key = value.trim();
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final sorted = counts.keys.toList()..sort();
  final labels = <String>[
    ...preferredOrder.where(sorted.contains),
    ...sorted.where((key) => !preferredOrder.contains(key)),
  ];
  return [
    for (final label in labels)
      StatsDatum(label: label, value: counts[label]!.toDouble()),
  ];
}

List<StatsDatum> _ratings(
  Iterable<(String, double)> entries, {
  required String Function(int) countLabel,
}) {
  final grouped = <String, List<double>>{};
  for (final entry in entries) {
    final key = entry.$1.trim();
    if (key.isEmpty) continue;
    grouped.putIfAbsent(key, () => []).add(entry.$2);
  }
  final keys = grouped.keys.toList()..sort();
  return [
    for (final key in keys)
      StatsDatum(
        label: key,
        value: grouped[key]!.reduce((a, b) => a + b) / grouped[key]!.length,
        detail: countLabel(grouped[key]!.length),
      ),
  ];
}

({List<StatsDatum> series, bool hasData}) _periodSeries({
  required StatsFilter filter,
  required List<ReadingSession> sessions,
  required List<Reading> readings,
  required bool pages,
}) {
  final reference = filter.reference;
  final slots = filter.period == StatsPeriod.month
      ? DateTime(reference.year, reference.month + 1, 0).day
      : 12;
  final buckets = List<double>.filled(slots, 0);

  void add(int index, double amount) {
    if (index >= 0 && index < slots) buckets[index] += amount;
  }

  for (final session in sessions) {
    if (filter.period == StatsPeriod.month) {
      if (session.date.year == reference.year &&
          session.date.month == reference.month) {
        add(session.date.day - 1, session.pagesRead.toDouble());
      }
    } else if (session.date.year == reference.year) {
      add(session.date.month - 1, session.pagesRead.toDouble());
    }
  }

  if (!pages) {
    for (final reading in readings) {
      final finishedAt = reading.finishedAt;
      if (finishedAt == null) continue;
      if (filter.period == StatsPeriod.month) {
        if (finishedAt.year == reference.year &&
            finishedAt.month == reference.month) {
          add(finishedAt.day - 1, 1);
        }
      } else if (finishedAt.year == reference.year) {
        add(finishedAt.month - 1, 1);
      }
    }
  }

  return (
    series: [
      for (var index = 0; index < slots; index++)
        StatsDatum(
          label: filter.period == StatsPeriod.month
              ? '${index + 1}'
              : formatMonthShort(index + 1),
          value: buckets[index],
        ),
    ],
    hasData: buckets.any((value) => value > 0),
  );
}

StatsSummary buildStatsSummary(
  List<Work> works,
  List<Reading> readings,
  List<ReadingSession> sessions,
  StatsFilter filter,
) {
  final pages = _periodSeries(
    filter: filter,
    sessions: sessions,
    readings: readings,
    pages: true,
  );
  final completed = _periodSeries(
    filter: filter,
    sessions: sessions,
    readings: readings,
    pages: false,
  );

  final worksById = <int, Work>{
    for (final work in works) work.id: work,
  };
  final ratedReadings = readings.where(
    (reading) => reading.rating != null && worksById.containsKey(reading.workId),
  );

  return StatsSummary(
    statusCounts: _counts(
      readings.map((reading) => AppStrings.workStatusLabel(reading.status)),
      WorkStatus.values.map(AppStrings.workStatusLabel).toList(),
    ),
    typeCounts: _counts(
      works.map((work) => AppStrings.workTypeLabel(work.type)),
      WorkType.values.map(AppStrings.workTypeLabel).toList(),
    ),
    genreCounts: _counts(works.map((work) => work.genre), const []),
    pagesSeries: pages.series,
    completedSeries: completed.series,
    ratingByGenre: _ratings(
      ratedReadings.map(
        (reading) => (worksById[reading.workId]!.genre, reading.rating!),
      ),
      countLabel: AppStrings.readingCountLabel,
    ),
    ratingByAuthor: _ratings(
      ratedReadings.map(
        (reading) => (worksById[reading.workId]!.author, reading.rating!),
      ),
      countLabel: AppStrings.readingCountLabel,
    ),
    hasWorks: works.isNotEmpty,
    hasReadings: readings.isNotEmpty,
    hasSessions: sessions.isNotEmpty,
    hasPagesInPeriod: pages.hasData,
    hasFinishedReadings: readings.any((reading) => reading.finishedAt != null),
    hasCompletedInPeriod: completed.hasData,
    hasRatings: ratedReadings.isNotEmpty,
  );
}

final readingSessionsProvider = StreamProvider<List<ReadingSession>>((ref) {
  return ref.watch(readingSessionsDaoProvider).watchAll();
});

final streakProvider = Provider<StreakInfo>((ref) {
  final sessions =
      ref.watch(readingSessionsProvider).value ?? const <ReadingSession>[];
  return calculateStreak(sessions);
});

final statsProvider = Provider.family<StatsSummary, StatsFilter>((ref, filter) {
  final works = ref.watch(worksProvider).value ?? const <Work>[];
  final readings = ref.watch(readingsProvider).value ?? const <Reading>[];
  final sessions =
      ref.watch(readingSessionsProvider).value ?? const <ReadingSession>[];
  return buildStatsSummary(works, readings, sessions, filter);
});
