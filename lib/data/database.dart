import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

abstract final class WorkType {
  static const String livro = 'livro';
  static const String artigo = 'artigo';
  static const String outro = 'outro';
  static const List<String> values = [livro, artigo, outro];
}

abstract final class WorkStatus {
  static const String queroLer = 'quero_ler';
  static const String lendo = 'lendo';
  static const String lido = 'lido';
  static const List<String> values = [queroLer, lendo, lido];
}

@DataClassName('Work')
class Works extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type =>
      text().withDefault(const Constant(WorkType.livro))();

  TextColumn get title => text()();

  TextColumn get author => text()();

  TextColumn get genre => text()();

  IntColumn get year => integer().nullable()();

  IntColumn get pages => integer().nullable()();

  TextColumn get status =>
      text().withDefault(const Constant(WorkStatus.queroLer))();

  RealColumn get rating => real().nullable()();

  DateTimeColumn get startedAt => dateTime().nullable()();

  DateTimeColumn get finishedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

/// Um ciclo de leitura de uma obra. A mesma obra pode ter várias leituras
/// (releituras), cada uma com seu próprio status, nota e período.
@DataClassName('Reading')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get workId =>
      integer().references(Works, #id, onDelete: KeyAction.cascade)();

  /// Número sequencial da leitura dentro da obra (1, 2, 3...).
  IntColumn get number => integer()();

  TextColumn get status =>
      text().withDefault(const Constant(WorkStatus.queroLer))();

  RealColumn get rating => real().nullable()();

  DateTimeColumn get startedAt => dateTime().nullable()();

  DateTimeColumn get finishedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}

@DataClassName('ReadingSession')
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get workId =>
      integer().references(Works, #id, onDelete: KeyAction.cascade)();

  /// Leitura à qual a sessão pertence. Pode ser nulo apenas em dados antigos
  /// importados antes do suporte a releituras.
  IntColumn get readingId => integer()
      .nullable()
      .references(Readings, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get date => dateTime()();

  IntColumn get pagesRead => integer()();

  TextColumn get note => text().nullable()();
}

@DataClassName('Note')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get workId =>
      integer().references(Works, #id, onDelete: KeyAction.cascade)();

  TextColumn get label => text().withDefault(const Constant(''))();

  TextColumn get summary => text().withDefault(const Constant(''))();

  TextColumn get thesis => text().withDefault(const Constant(''))();

  TextColumn get concepts => text().withDefault(const Constant(''))();

  TextColumn get critique => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

@DataClassName('Quote')
class Quotes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();

  TextColumn get content => text().named('text')();

  IntColumn get page => integer().nullable()();

  TextColumn get comment => text().nullable()();
}

@DataClassName('Analysis')
class Analyses extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  TextColumn get body => text()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
}

@DataClassName('AnalysisWork')
class AnalysisWorks extends Table {
  IntColumn get analysisId =>
      integer().references(Analyses, #id, onDelete: KeyAction.cascade)();

  IntColumn get workId =>
      integer().references(Works, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {analysisId, workId};
}

@DriftAccessor(tables: [Works])
class WorksDao extends DatabaseAccessor<AppDatabase> with _$WorksDaoMixin {
  WorksDao(super.db);

  Stream<List<Work>> watchAll() => select(works).watch();

  Future<Work?> findById(int id) =>
      (select(works)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Work?> watchById(int id) =>
      (select(works)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertWork(WorksCompanion work) => into(works).insert(work);

  Future<bool> updateWork(Work work) => update(works).replace(work);

  Future<int> deleteWork(int id) =>
      (delete(works)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Readings])
class ReadingsDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingsDaoMixin {
  ReadingsDao(super.db);

  Stream<List<Reading>> watchAll() => (select(readings)
        ..orderBy([
          (t) => OrderingTerm.asc(t.workId),
          (t) => OrderingTerm.asc(t.number),
        ]))
      .watch();

  Stream<List<Reading>> watchByWork(int workId) => (select(readings)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.number)]))
      .watch();

  Future<List<Reading>> getByWork(int workId) => (select(readings)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.asc(t.number)]))
      .get();

  Future<Reading?> findById(int id) =>
      (select(readings)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Reading?> watchById(int id) =>
      (select(readings)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> insertReading(ReadingsCompanion reading) =>
      into(readings).insert(reading);

  Future<bool> updateReading(Reading reading) =>
      update(readings).replace(reading);

  Future<int> deleteReading(int id) =>
      (delete(readings)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [ReadingSessions])
class ReadingSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingSessionsDaoMixin {
  ReadingSessionsDao(super.db);

  Stream<List<ReadingSession>> watchAll() => select(readingSessions).watch();

  Stream<List<ReadingSession>> watchByWork(int workId) =>
      (select(readingSessions)..where((t) => t.workId.equals(workId))).watch();

  Stream<List<ReadingSession>> watchByReading(int readingId) =>
      (select(readingSessions)
            ..where((t) => t.readingId.equals(readingId))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .watch();

  Future<int> insertSession(ReadingSessionsCompanion session) =>
      into(readingSessions).insert(session);

  Future<bool> updateSession(ReadingSession session) =>
      update(readingSessions).replace(session);

  Future<int> deleteSession(int id) =>
      (delete(readingSessions)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Stream<List<Note>> watchAll() => (select(notes)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<Note>> watchByWork(int workId) => (select(notes)
        ..where((t) => t.workId.equals(workId))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Future<Note?> findById(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);

  Future<bool> updateNote(Note note) => update(notes).replace(note);

  Future<int> deleteNote(int id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Quotes])
class QuotesDao extends DatabaseAccessor<AppDatabase> with _$QuotesDaoMixin {
  QuotesDao(super.db);

  Stream<List<Quote>> watchByNote(int noteId) =>
      (select(quotes)..where((t) => t.noteId.equals(noteId))).watch();

  Future<List<Quote>> getByNote(int noteId) =>
      (select(quotes)..where((t) => t.noteId.equals(noteId))).get();

  Future<int> insertQuote(QuotesCompanion quote) => into(quotes).insert(quote);

  Future<bool> updateQuote(Quote quote) => update(quotes).replace(quote);

  Future<int> deleteQuote(int id) =>
      (delete(quotes)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Analyses])
class AnalysesDao extends DatabaseAccessor<AppDatabase> with _$AnalysesDaoMixin {
  AnalysesDao(super.db);

  Stream<List<Analysis>> watchAll() => (select(analyses)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Future<Analysis?> findById(int id) =>
      (select(analyses)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertAnalysis(AnalysesCompanion analysis) =>
      into(analyses).insert(analysis);

  Future<bool> updateAnalysis(Analysis analysis) =>
      update(analyses).replace(analysis);

  Future<int> deleteAnalysis(int id) =>
      (delete(analyses)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [AnalysisWorks])
class AnalysisWorksDao extends DatabaseAccessor<AppDatabase>
    with _$AnalysisWorksDaoMixin {
  AnalysisWorksDao(super.db);

  Stream<List<AnalysisWork>> watchByAnalysis(int analysisId) =>
      (select(analysisWorks)..where((t) => t.analysisId.equals(analysisId)))
          .watch();

  Future<List<AnalysisWork>> getByAnalysis(int analysisId) =>
      (select(analysisWorks)..where((t) => t.analysisId.equals(analysisId)))
          .get();

  Stream<List<AnalysisWork>> watchByWork(int workId) =>
      (select(analysisWorks)..where((t) => t.workId.equals(workId))).watch();

  Future<int> insertLink(AnalysisWorksCompanion link) =>
      into(analysisWorks).insert(link);

  Future<int> deleteLink(int analysisId, int workId) =>
      (delete(analysisWorks)
            ..where((t) =>
                t.analysisId.equals(analysisId) & t.workId.equals(workId)))
          .go();

  Future<int> deleteLinksByAnalysis(int analysisId) =>
      (delete(analysisWorks)..where((t) => t.analysisId.equals(analysisId)))
          .go();
}

@DriftDatabase(
  tables: [
    Works,
    Readings,
    ReadingSessions,
    Notes,
    Quotes,
    Analyses,
    AnalysisWorks,
  ],
  daos: [
    WorksDao,
    ReadingsDao,
    ReadingSessionsDao,
    NotesDao,
    QuotesDao,
    AnalysesDao,
    AnalysisWorksDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'diario_leituras',
          web: kIsWeb
              ? DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                )
              : null,
        ),
      );

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await m.createTable(readings);
            await m.addColumn(readingSessions, readingSessions.readingId);

            // Cada obra existente passa a ter uma leitura (a original), com o
            // status, a nota e as datas que antes viviam na própria obra.
            final existingWorks = await select(works).get();
            for (final work in existingWorks) {
              final readingId = await into(readings).insert(
                ReadingsCompanion(
                  workId: Value(work.id),
                  number: const Value(1),
                  status: Value(work.status),
                  rating: Value(work.rating),
                  startedAt: Value(work.startedAt),
                  finishedAt: Value(work.finishedAt),
                  createdAt: Value(work.createdAt),
                ),
              );
              await (update(readingSessions)
                    ..where((session) => session.workId.equals(work.id)))
                  .write(
                ReadingSessionsCompanion(readingId: Value(readingId)),
              );
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
