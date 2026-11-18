import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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

@DataClassName('ReadingSession')
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get workId =>
      integer().references(Works, #id, onDelete: KeyAction.cascade)();

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

  Future<int> insertWork(WorksCompanion work) => into(works).insert(work);

  Future<bool> updateWork(Work work) => update(works).replace(work);

  Future<int> deleteWork(int id) =>
      (delete(works)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [ReadingSessions])
class ReadingSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingSessionsDaoMixin {
  ReadingSessionsDao(super.db);

  Stream<List<ReadingSession>> watchAll() => select(readingSessions).watch();

  Stream<List<ReadingSession>> watchByWork(int workId) =>
      (select(readingSessions)..where((t) => t.workId.equals(workId))).watch();

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
  tables: [Works, ReadingSessions, Notes, Quotes, Analyses, AnalysisWorks],
  daos: [
    WorksDao,
    ReadingSessionsDao,
    NotesDao,
    QuotesDao,
    AnalysesDao,
    AnalysisWorksDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'diario_leituras'));

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
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
