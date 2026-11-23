import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/strings.dart';
import '../../data/database.dart';
import '../works/readings_providers.dart';
import '../works/works_providers.dart';

/// Granularidade das séries temporais dos gráficos.
enum StatsGranularity { day, month }

typedef StatsFilter = ({StatsGranularity granularity});

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
  const StatsDatum({
    required this.label,
    required this.value,
    this.detail,
    this.groupLabel,
    this.fullLabel,
  });

  /// Texto curto mostrado no eixo/tooltip (dia, mês ou categoria).
  final String label;

  final double value;

  /// Informação extra, como a quantidade de leituras de uma nota média.
  final String? detail;

  /// Rótulo de contexto no início de um bloco: "nov/2026" ou "2027".
  final String? groupLabel;

  /// Rótulo completo usado no tooltip ("21 de nov de 2026").
  final String? fullLabel;
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

DateTime _bucketStart(DateTime date, StatsGranularity granularity) =>
    granularity == StatsGranularity.day
    ? DateTime(date.year, date.month, date.day)
    : DateTime(date.year, date.month);

DateTime _nextBucket(DateTime bucket, StatsGranularity granularity) =>
    granularity == StatsGranularity.day
    ? bucket.add(const Duration(days: 1))
    : DateTime(bucket.year, bucket.month + 1);

String? _groupLabel(DateTime bucket, StatsGranularity granularity) {
  if (granularity == StatsGranularity.day) {
    return bucket.day == 1 ? formatMonthYearShort(bucket) : null;
  }
  return bucket.month == 1 ? '${bucket.year}' : null;
}

List<StatsDatum> _seriesFromBuckets(
  Iterable<DateTime> events,
  StatsGranularity granularity,
  double Function(DateTime bucket) valueAt,
) {
  DateTime? first;
  DateTime? last;
  for (final event in events) {
    final bucket = _bucketStart(event, granularity);
    if (first == null || bucket.isBefore(first)) first = bucket;
    if (last == null || bucket.isAfter(last)) last = bucket;
  }
  if (first == null || last == null) return const <StatsDatum>[];

  final series = <StatsDatum>[];
  var cursor = first;
  while (!cursor.isAfter(last)) {
    series.add(
      StatsDatum(
        label: granularity == StatsGranularity.day
            ? '${cursor.day}'
            : formatMonthShort(cursor.month),
        value: valueAt(cursor),
        groupLabel: _groupLabel(cursor, granularity),
        fullLabel: granularity == StatsGranularity.day
            ? formatStatsDayLabel(cursor)
            : formatMonthYear(cursor),
      ),
    );
    cursor = _nextBucket(cursor, granularity);
  }
  return series;
}

/// Soma das páginas das sessões, agrupada por dia ou por mês.
///
/// A linha do tempo vai da primeira à última sessão e inclui posições vazias
/// com valor zero, para que a rolagem mostre o período contínuo.
List<StatsDatum> pagesByPeriod(
  List<ReadingSession> sessions,
  StatsGranularity granularity,
) {
  final totals = <DateTime, double>{};
  for (final session in sessions) {
    final bucket = _bucketStart(session.date, granularity);
    totals[bucket] = (totals[bucket] ?? 0) + session.pagesRead;
  }
  return _seriesFromBuckets(
    totals.keys,
    granularity,
    (bucket) => totals[bucket] ?? 0,
  );
}

/// Contagem de ciclos concluídos, agrupada pela data `fim` da leitura.
///
/// Cada leitura/releitura conta separadamente. Esta função não lê sessões:
/// páginas e conclusões são grandezas distintas.
List<StatsDatum> completedReadingsByPeriod(
  List<Reading> readings,
  StatsGranularity granularity,
) {
  final totals = <DateTime, double>{};
  for (final reading in readings) {
    final finishedAt = reading.finishedAt;
    if (finishedAt == null) continue;
    final bucket = _bucketStart(finishedAt, granularity);
    totals[bucket] = (totals[bucket] ?? 0) + 1;
  }
  return _seriesFromBuckets(
    totals.keys,
    granularity,
    (bucket) => totals[bucket] ?? 0,
  );
}

StatsSummary buildStatsSummary(
  List<Work> works,
  List<Reading> readings,
  List<ReadingSession> sessions,
  StatsFilter filter,
) {
  final pagesSeries = pagesByPeriod(sessions, filter.granularity);
  final completedSeries = completedReadingsByPeriod(
    readings,
    filter.granularity,
  );

  final worksById = <int, Work>{for (final work in works) work.id: work};
  final ratedReadings = readings.where(
    (reading) =>
        reading.rating != null && worksById.containsKey(reading.workId),
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
    pagesSeries: pagesSeries,
    completedSeries: completedSeries,
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
    hasPagesInPeriod: pagesSeries.any((item) => item.value > 0),
    hasFinishedReadings: readings.any((reading) => reading.finishedAt != null),
    hasCompletedInPeriod: completedSeries.any((item) => item.value > 0),
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

/// Provider nomeado para a série de páginas por período.
final pagesByPeriodProvider = Provider.family<List<StatsDatum>, StatsFilter>((
  ref,
  filter,
) {
  final sessions =
      ref.watch(readingSessionsProvider).value ?? const <ReadingSession>[];
  return pagesByPeriod(sessions, filter.granularity);
});

/// Provider nomeado para a série de leituras concluídas por período.
final completedReadingsByPeriodProvider =
    Provider.family<List<StatsDatum>, StatsFilter>((ref, filter) {
      final readings = ref.watch(readingsProvider).value ?? const <Reading>[];
      return completedReadingsByPeriod(readings, filter.granularity);
    });

final statsProvider = Provider.family<StatsSummary, StatsFilter>((ref, filter) {
  final works = ref.watch(worksProvider).value ?? const <Work>[];
  final readings = ref.watch(readingsProvider).value ?? const <Reading>[];
  final sessions =
      ref.watch(readingSessionsProvider).value ?? const <ReadingSession>[];
  return buildStatsSummary(works, readings, sessions, filter);
});
