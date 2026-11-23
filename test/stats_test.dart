import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/core/formatters.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';

Work work({
  required int id,
  String type = WorkType.livro,
  String title = 'Obra',
  String author = 'Autor',
  String genre = 'Gênero',
}) => Work(
  id: id,
  type: type,
  title: title,
  author: author,
  genre: genre,
  status: WorkStatus.queroLer,
  createdAt: DateTime(2026, 1, 1),
);

Reading reading({
  required int id,
  required int workId,
  int number = 1,
  String status = WorkStatus.queroLer,
  double? rating,
  DateTime? finishedAt,
}) => Reading(
  id: id,
  workId: workId,
  number: number,
  status: status,
  rating: rating,
  finishedAt: finishedAt,
  createdAt: DateTime(2026, 1, 1),
);

ReadingSession session(DateTime date, int pagesRead) => ReadingSession(
  id: 1,
  workId: 1,
  readingId: 1,
  date: date,
  pagesRead: pagesRead,
  note: null,
);

StatsSummary summarize(
  List<Work> works,
  List<Reading> readings,
  List<ReadingSession> sessions, {
  StatsGranularity granularity = StatsGranularity.day,
}) => buildStatsSummary(works, readings, sessions, (granularity: granularity));

double total(List<StatsDatum> series) =>
    series.fold<double>(0, (sum, item) => sum + item.value);

void main() {
  setUpAll(() async {
    await initializeFormatting();
  });

  test('contagens por status das leituras, tipo e gênero das obras', () {
    final summary = summarize(
      [
        work(id: 1, type: WorkType.livro, genre: 'Ficção'),
        work(id: 2, type: WorkType.artigo, genre: 'Ficção'),
        work(id: 3, type: WorkType.livro, genre: 'História'),
      ],
      [
        reading(id: 1, workId: 1, status: WorkStatus.lido),
        reading(id: 2, workId: 2, status: WorkStatus.lendo),
        reading(id: 3, workId: 3, status: WorkStatus.lido),
      ],
      const [],
    );

    expect(
      summary.statusCounts
          .where((item) => item.label == AppStrings.statusLido)
          .single
          .value,
      2,
    );
    expect(
      summary.statusCounts
          .where((item) => item.label == AppStrings.statusLendo)
          .single
          .value,
      1,
    );
    expect(
      summary.typeCounts
          .where((item) => item.label == AppStrings.typeLivro)
          .single
          .value,
      2,
    );
    expect(
      summary.genreCounts.where((item) => item.label == 'Ficção').single.value,
      2,
    );
  });

  test('releituras entram na contagem de status', () {
    final summary = summarize(
      [work(id: 1)],
      [
        reading(id: 1, workId: 1, number: 1, status: WorkStatus.lido),
        reading(id: 2, workId: 1, number: 2, status: WorkStatus.lendo),
      ],
      const [],
    );

    expect(summary.hasReadings, true);
    expect(
      summary.statusCounts
          .where((item) => item.label == AppStrings.statusLido)
          .single
          .value,
      1,
    );
    expect(
      summary.statusCounts
          .where((item) => item.label == AppStrings.statusLendo)
          .single
          .value,
      1,
    );
  });

  test('páginas por dia preenche zeros e marca viradas de mês e ano', () {
    final series = pagesByPeriod([
      session(DateTime(2026, 10, 31), 10),
      session(DateTime(2026, 11, 1), 20),
      session(DateTime(2026, 11, 15), 5),
      session(DateTime(2027, 1, 2), 7),
    ], StatsGranularity.day);

    expect(series.length, 64);
    expect(series.first.label, '31');
    expect(series.first.value, 10);
    expect(series[1].label, '1');
    expect(series[1].value, 20);
    expect(series[1].groupLabel, 'nov/2026');
    expect(series[2].value, 0);
    expect(series[15].value, 5);
    expect(series[31].groupLabel, 'dez/2026');
    expect(series[62].groupLabel, 'jan/2027');
    expect(series.last.label, '2');
    expect(series.last.value, 7);
    expect(total(series), 42);
  });

  test('páginas por mês preenche meses sem sessões', () {
    final series = pagesByPeriod([
      session(DateTime(2026, 10, 31), 10),
      session(DateTime(2026, 11, 1), 20),
      session(DateTime(2026, 11, 15), 5),
      session(DateTime(2027, 1, 2), 7),
    ], StatsGranularity.month);

    expect(series.map((item) => item.label).toList(), [
      formatMonthShort(10),
      formatMonthShort(11),
      formatMonthShort(12),
      formatMonthShort(1),
    ]);
    expect(series.map((item) => item.value).toList(), [10, 25, 0, 7]);
    expect(series.last.groupLabel, '2027');
  });

  test('leituras concluídas por dia conta cada ciclo na data de conclusão', () {
    final series = completedReadingsByPeriod([
      reading(id: 1, workId: 1, finishedAt: DateTime(2026, 10, 31)),
      reading(id: 2, workId: 1, number: 2, finishedAt: DateTime(2026, 11, 1)),
      reading(id: 3, workId: 1, number: 3, finishedAt: DateTime(2026, 11, 1)),
      reading(id: 4, workId: 2, finishedAt: DateTime(2027, 1, 2)),
    ], StatsGranularity.day);

    expect(series.length, 64);
    expect(series.first.value, 1);
    expect(series[1].value, 2);
    expect(series[2].value, 0);
    expect(series[63].value, 1);
    expect(total(series), 4);
    expect(
      series.every((item) => item.value == item.value.roundToDouble()),
      isTrue,
    );
  });

  test('leituras concluídas por mês inclui releituras e zeros', () {
    final series = completedReadingsByPeriod([
      reading(id: 1, workId: 1, finishedAt: DateTime(2026, 10, 31)),
      reading(id: 2, workId: 1, number: 2, finishedAt: DateTime(2026, 11, 1)),
      reading(id: 3, workId: 1, number: 3, finishedAt: DateTime(2026, 11, 1)),
      reading(id: 4, workId: 2, finishedAt: DateTime(2027, 1, 2)),
    ], StatsGranularity.month);

    expect(series.map((item) => item.value).toList(), [1, 2, 0, 1]);
    expect(series.last.groupLabel, '2027');
  });

  test('regressão: páginas e conclusões nunca são a mesma série', () {
    final sessions = [
      session(DateTime(2026, 11, 3), 12),
      session(DateTime(2026, 11, 20), 18),
    ];
    final readings = [
      reading(id: 1, workId: 1, finishedAt: DateTime(2026, 11, 3)),
    ];
    final summary = summarize([work(id: 1)], readings, sessions);

    expect(total(summary.pagesSeries), 30);
    expect(total(summary.completedSeries), 1);
    expect(summary.completedSeries, isNot(summary.pagesSeries));
    expect(
      summary.completedSeries.map((item) => item.value).toList(),
      isNot(summary.pagesSeries.map((item) => item.value).toList()),
    );
  });

  test('séries vazias', () {
    final empty = summarize(const [], const [], const []);
    expect(empty.pagesSeries, isEmpty);
    expect(empty.completedSeries, isEmpty);
    expect(empty.hasWorks, false);
    expect(empty.hasReadings, false);
    expect(empty.hasSessions, false);
    expect(empty.hasPagesInPeriod, false);
    expect(empty.hasFinishedReadings, false);
    expect(empty.hasCompletedInPeriod, false);
    expect(empty.hasRatings, false);
  });

  test('nota média considera cada leitura e informa a quantidade', () {
    final summary = summarize(
      [
        work(id: 1, genre: 'Ficção', author: 'A'),
        work(id: 2, genre: 'História', author: 'B'),
      ],
      [
        reading(id: 1, workId: 1, rating: 4),
        reading(id: 2, workId: 1, number: 2, rating: 5),
        reading(id: 3, workId: 2, rating: 2),
      ],
      const [],
    );

    final genre = summary.ratingByGenre
        .where((item) => item.label == 'Ficção')
        .single;
    expect(genre.value, 4.5);
    expect(genre.detail, AppStrings.readingCountLabel(2));

    final author = summary.ratingByAuthor
        .where((item) => item.label == 'A')
        .single;
    expect(author.value, 4.5);
    expect(author.detail, AppStrings.readingCountLabel(2));
    expect(summary.ratingByAuthor.where((item) => item.label == 'C'), isEmpty);
  });
}
