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
}) =>
    Work(
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
}) =>
    Reading(
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
  StatsPeriod period = StatsPeriod.month,
  DateTime? reference,
}) =>
    buildStatsSummary(
      works,
      readings,
      sessions,
      (
        period: period,
        reference: reference ?? DateTime(2026, 11),
      ),
    );

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
      summary.statusCounts.where((item) => item.label == AppStrings.statusLido).single.value,
      2,
    );
    expect(
      summary.statusCounts.where((item) => item.label == AppStrings.statusLendo).single.value,
      1,
    );
    expect(
      summary.typeCounts.where((item) => item.label == AppStrings.typeLivro).single.value,
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
      summary.statusCounts.where((item) => item.label == AppStrings.statusLido).single.value,
      1,
    );
    expect(
      summary.statusCounts.where((item) => item.label == AppStrings.statusLendo).single.value,
      1,
    );
  });

  test('páginas lidas por mês e por ano', () {
    final sessions = [
      session(DateTime(2026, 11, 1), 10),
      session(DateTime(2026, 11, 15), 20),
      session(DateTime(2026, 11, 16), 5),
      session(DateTime(2026, 10, 2), 30),
      session(DateTime(2025, 12, 31), 40),
    ];

    final month = summarize([], [], sessions, reference: DateTime(2026, 11));
    expect(month.pagesSeries[0].value, 10);
    expect(month.pagesSeries[14].value, 20);
    expect(month.pagesSeries[15].value, 5);
    expect(month.hasPagesInPeriod, true);

    final year = summarize([], [], sessions,
        period: StatsPeriod.year, reference: DateTime(2026));
    expect(year.pagesSeries[9].value, 30);
    expect(year.pagesSeries[10].value, 35);
    expect(year.pagesSeries.length, 12);
  });

  test('leituras concluídas por mês e por ano, incluindo releituras', () {
    final readings = [
      reading(id: 1, workId: 1, finishedAt: DateTime(2026, 11, 3)),
      reading(id: 2, workId: 1, number: 2, finishedAt: DateTime(2026, 11, 20)),
      reading(id: 3, workId: 2, finishedAt: DateTime(2026, 10, 1)),
      reading(id: 4, workId: 3, finishedAt: DateTime(2025, 12, 31)),
    ];

    final month = summarize([work(id: 1), work(id: 2)], readings, const [],
        reference: DateTime(2026, 11));
    expect(month.completedSeries[2].value, 1);
    expect(month.completedSeries[19].value, 1);
    expect(month.hasCompletedInPeriod, true);

    final year = summarize([], readings, const [],
        period: StatsPeriod.year, reference: DateTime(2026));
    expect(year.completedSeries[9].value, 1);
    expect(year.completedSeries[10].value, 2);
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

    final author = summary.ratingByAuthor.where((item) => item.label == 'A').single;
    expect(author.value, 4.5);
    expect(author.detail, AppStrings.readingCountLabel(2));
    expect(summary.ratingByAuthor.where((item) => item.label == 'C'), isEmpty);
  });

  test('estados vazios', () {
    final empty = summarize(const [], const [], const []);
    expect(empty.hasWorks, false);
    expect(empty.hasReadings, false);
    expect(empty.hasSessions, false);
    expect(empty.hasPagesInPeriod, false);
    expect(empty.hasFinishedReadings, false);
    expect(empty.hasCompletedInPeriod, false);
    expect(empty.hasRatings, false);

    final noDataInPeriod = summarize(
      [work(id: 1)],
      [reading(id: 1, workId: 1, rating: 4)],
      [session(DateTime(2025, 1, 1), 10)],
      reference: DateTime(2026, 11),
    );
    expect(noDataInPeriod.hasWorks, true);
    expect(noDataInPeriod.hasReadings, true);
    expect(noDataInPeriod.hasSessions, true);
    expect(noDataInPeriod.hasPagesInPeriod, false);
    expect(noDataInPeriod.hasRatings, true);
  });
}
