import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/works/readings_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  WorksCompanion newWork() => WorksCompanion(
        type: Value(WorkType.livro),
        title: const Value('Obra'),
        author: const Value('Autor'),
        genre: const Value('Gênero'),
        pages: const Value(100),
      );

  test('obra nova começa com uma leitura e espelha o status na obra', () async {
    final now = DateTime(2026, 1, 1);
    final workId = await createWorkWithReading(
      db: db,
      work: newWork(),
      reading: const ReadingWrite(status: WorkStatus.queroLer),
      now: now,
    );

    final readings = await db.readingsDao.getByWork(workId);
    expect(readings, hasLength(1));
    expect(readings.single.number, 1);
    expect(readings.single.status, WorkStatus.queroLer);

    final work = await db.worksDao.findById(workId);
    expect(work!.status, WorkStatus.queroLer);
  });

  test('releituras são numeradas e a obra espelha a leitura mais recente',
      () async {
    final now = DateTime(2026, 1, 1);
    final workId = await createWorkWithReading(
      db: db,
      work: newWork(),
      reading: ReadingWrite(
        status: WorkStatus.lido,
        rating: 4,
        finishedAt: now,
      ),
      now: now,
    );

    await addReading(
      db: db,
      workId: workId,
      reading: const ReadingWrite(status: WorkStatus.lendo, rating: 4.5),
      now: now.add(const Duration(days: 1)),
    );

    var readings = await db.readingsDao.getByWork(workId);
    expect(readings.map((item) => item.number), [1, 2]);

    var work = await db.worksDao.findById(workId);
    expect(work!.status, WorkStatus.lendo);
    expect(work.rating, 4.5);

    await saveReading(
      db: db,
      reading: readings.last,
      data: const ReadingWrite(status: WorkStatus.lido, rating: 5),
      now: now.add(const Duration(days: 2)),
    );

    final updated = await db.readingsDao.findById(readings.last.id);
    expect(updated!.status, WorkStatus.lido);
    expect(updated.rating, 5);
    expect(updated.finishedAt, now.add(const Duration(days: 2)));

    work = await db.worksDao.findById(workId);
    expect(work!.status, WorkStatus.lido);
    expect(work.rating, 5);

    readings = await db.readingsDao.getByWork(workId);
    expect(readings, hasLength(2));
  });

  test('sessões são separadas por leitura', () async {
    final now = DateTime(2026, 1, 1);
    final workId = await createWorkWithReading(
      db: db,
      work: newWork(),
      reading: const ReadingWrite(status: WorkStatus.lido),
      now: now,
    );
    final firstReadingId = (await db.readingsDao.getByWork(workId)).single.id;
    final secondReadingId = await addReading(
      db: db,
      workId: workId,
      reading: const ReadingWrite(status: WorkStatus.lendo),
      now: now,
    );

    await db.readingSessionsDao.insertSession(
      ReadingSessionsCompanion(
        workId: Value(workId),
        readingId: Value(firstReadingId),
        date: Value(now),
        pagesRead: const Value(10),
      ),
    );
    await db.readingSessionsDao.insertSession(
      ReadingSessionsCompanion(
        workId: Value(workId),
        readingId: Value(secondReadingId),
        date: Value(now),
        pagesRead: const Value(20),
      ),
    );

    final firstSessions =
        await db.readingSessionsDao.watchByReading(firstReadingId).first;
    final secondSessions =
        await db.readingSessionsDao.watchByReading(secondReadingId).first;
    expect(firstSessions.single.pagesRead, 10);
    expect(secondSessions.single.pagesRead, 20);
  });

  test('não é possível excluir a única leitura de uma obra', () async {
    final now = DateTime(2026, 1, 1);
    final workId = await createWorkWithReading(
      db: db,
      work: newWork(),
      reading: const ReadingWrite(status: WorkStatus.queroLer),
      now: now,
    );
    final first = (await db.readingsDao.getByWork(workId)).single;

    await expectLater(
      deleteReading(db: db, readingId: first.id),
      throwsA(isA<LastReadingException>()),
    );

    final secondId = await addReading(
      db: db,
      workId: workId,
      reading: const ReadingWrite(status: WorkStatus.lendo),
      now: now,
    );
    await deleteReading(db: db, readingId: secondId);
    expect(await db.readingsDao.getByWork(workId), hasLength(1));
  });

  test('migração de v1 cria a leitura original e vincula as sessões', () async {
    final timestamp = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;

    // Recria o estado do schema 1: sem tabela de leituras e sem reading_id.
    await db.customStatement('DROP TABLE reading_sessions');
    await db.customStatement('DROP TABLE readings');
    await db.customStatement(
      'CREATE TABLE "reading_sessions" ("id" INTEGER NOT NULL PRIMARY KEY '
      'AUTOINCREMENT, "work_id" INTEGER NOT NULL REFERENCES works (id) ON '
      'DELETE CASCADE, "date" INTEGER NOT NULL, "pages_read" INTEGER NOT NULL, '
      '"note" TEXT NULL)',
    );
    await db.customStatement(
      'INSERT INTO works (id, type, title, author, genre, status, rating, '
      'started_at, finished_at, created_at) VALUES '
      "(1, 'livro', 'Obra', 'Autor', 'Gênero', 'lido', 4.5, "
      '$timestamp, $timestamp, $timestamp)',
    );
    await db.customStatement(
      'INSERT INTO reading_sessions (work_id, date, pages_read, note) '
      "VALUES (1, $timestamp, 30, NULL)",
    );

    await db.migration.onUpgrade(Migrator(db), 1, 2);

    final readings = await db.readingsDao.getByWork(1);
    expect(readings, hasLength(1));
    expect(readings.single.workId, 1);
    expect(readings.single.number, 1);
    expect(readings.single.status, WorkStatus.lido);
    expect(readings.single.rating, 4.5);
    expect(readings.single.finishedAt,
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

    final sessions = await db.readingSessionsDao.watchByWork(1).first;
    expect(sessions, hasLength(1));
    expect(sessions.single.readingId, readings.single.id);
  });
}
