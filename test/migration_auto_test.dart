import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/data/database.dart';

class _LegacyUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    final ddl = <String>[
      'CREATE TABLE "works" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"type" TEXT NOT NULL DEFAULT \'livro\', "title" TEXT NOT NULL, '
      '"author" TEXT NOT NULL, "genre" TEXT NOT NULL, "year" INTEGER NULL, '
      '"pages" INTEGER NULL, "status" TEXT NOT NULL DEFAULT \'quero_ler\', '
      '"rating" REAL NULL, "started_at" INTEGER NULL, '
      '"finished_at" INTEGER NULL, "created_at" INTEGER NOT NULL)',
      'CREATE TABLE "reading_sessions" ("id" INTEGER NOT NULL PRIMARY KEY '
      'AUTOINCREMENT, "work_id" INTEGER NOT NULL REFERENCES works (id) ON '
      'DELETE CASCADE, "date" INTEGER NOT NULL, "pages_read" INTEGER NOT NULL, '
      '"note" TEXT NULL)',
      'CREATE TABLE "notes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"work_id" INTEGER NOT NULL REFERENCES works (id) ON DELETE CASCADE, '
      '"label" TEXT NOT NULL DEFAULT \'\', "summary" TEXT NOT NULL DEFAULT \'\', '
      '"thesis" TEXT NOT NULL DEFAULT \'\', "concepts" TEXT NOT NULL DEFAULT \'\', '
      '"critique" TEXT NOT NULL DEFAULT \'\', "created_at" INTEGER NOT NULL, '
      '"updated_at" INTEGER NOT NULL)',
      'CREATE TABLE "quotes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"note_id" INTEGER NOT NULL REFERENCES notes (id) ON DELETE CASCADE, '
      '"text" TEXT NOT NULL, "page" INTEGER NULL, "comment" TEXT NULL)',
      'CREATE TABLE "analyses" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"title" TEXT NOT NULL, "body" TEXT NOT NULL, "created_at" INTEGER NOT NULL, '
      '"updated_at" INTEGER NOT NULL)',
      'CREATE TABLE "analysis_works" ("analysis_id" INTEGER NOT NULL REFERENCES '
      'analyses (id) ON DELETE CASCADE, "work_id" INTEGER NOT NULL REFERENCES '
      'works (id) ON DELETE CASCADE, PRIMARY KEY ("analysis_id", "work_id"))',
    ];
    Future<void> runBatch(List<String> statements) => executor.runBatched(
          BatchedStatements(statements, [
            for (var i = 0; i < statements.length; i++)
              ArgumentsForBatchedStatement(i, const []),
          ]),
        );

    await runBatch(ddl);
    await runBatch([
      "INSERT INTO works (id, type, title, author, genre, status, rating, "
      'started_at, finished_at, created_at) VALUES '
      "(1, 'livro', 'Obra', 'Autor', 'Gênero', 'lido', 4.5, "
      '1767225600, 1767225600, 1767225600)',
      'INSERT INTO reading_sessions (work_id, date, pages_read, note) '
      'VALUES (1, 1767225600, 30, NULL)',
    ]);
  }
}

void main() {
  test('migração automática', () async {
    final dir = await Directory.systemTemp.createTemp('reading_migration_');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/old.db';

    final oldConnection = NativeDatabase(File(path));
    await oldConnection.ensureOpen(_LegacyUser());
    await oldConnection.close();

    final db = AppDatabase.connect(NativeDatabase(File(path)));
    addTearDown(db.close);

    final readings = await db.readingsDao.getByWork(1);
    expect(readings, hasLength(1));
    expect(readings.single.status, WorkStatus.lido);
    final sessions = await db.readingSessionsDao.watchByWork(1).first;
    expect(sessions.single.readingId, readings.single.id);
  });
}
