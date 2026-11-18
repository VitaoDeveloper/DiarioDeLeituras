import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/backup_service.dart';
import 'package:reading_management/data/database.dart';

void main() {
  late AppDatabase db;
  late BackupService service;
  final date = DateTime(2026, 1, 2, 3, 4, 5);

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> populate() async {
    await db.into(db.works).insert(
          WorksCompanion(
            id: const Value(1),
            type: Value(WorkType.livro),
            title: const Value('Livro'),
            author: const Value('Autor'),
            genre: const Value('Gênero'),
            year: const Value(2020),
            pages: const Value(100),
            status: Value(WorkStatus.lido),
            rating: const Value(4.5),
            startedAt: Value(date),
            finishedAt: Value(date),
            createdAt: Value(date),
          ),
        );
    await db.into(db.readingSessions).insert(
          ReadingSessionsCompanion(
            id: const Value(1),
            workId: const Value(1),
            date: Value(date),
            pagesRead: const Value(50),
            note: const Value('Nota'),
          ),
        );
    await db.into(db.notes).insert(
          NotesCompanion(
            id: const Value(1),
            workId: const Value(1),
            label: const Value('Cap. 1'),
            summary: const Value('Resumo'),
            thesis: const Value('Tese'),
            concepts: const Value('Conceitos'),
            critique: const Value('Crítica'),
            createdAt: Value(date),
            updatedAt: Value(date),
          ),
        );
    await db.into(db.quotes).insert(
          QuotesCompanion(
            id: const Value(1),
            noteId: const Value(1),
            content: const Value('Citação'),
            page: const Value(10),
            comment: const Value('Comentário'),
          ),
        );
    await db.into(db.analyses).insert(
          AnalysesCompanion(
            id: const Value(1),
            title: const Value('Análise'),
            body: const Value('Corpo'),
            createdAt: Value(date),
            updatedAt: Value(date),
          ),
        );
    await db.into(db.analysisWorks).insert(
          AnalysisWorksCompanion(
            analysisId: const Value(1),
            workId: const Value(1),
          ),
        );
  }

  test('exportar e importar reproduz exatamente os mesmos dados', () async {
    await populate();

    final before = await service.exportJson();
    final parsed = parseBackup(before);
    expect(parsed.workCount, 1);
    expect(parsed.noteCount, 1);
    expect(parsed.analysisCount, 1);

    await service.importBackup(parsed);
    expect(await service.exportJson(), before);
  });

  test('importação substitui os dados anteriores', () async {
    await populate();
    final backup = parseBackup(await service.exportJson());

    await db.delete(db.works).go();
    expect(await db.select(db.works).get(), isEmpty);

    await service.importBackup(backup);
    expect(await db.select(db.works).get(), hasLength(1));
    expect(await db.select(db.notes).get(), hasLength(1));
    expect(await db.select(db.analyses).get(), hasLength(1));
  });

  test('importação inválida não altera os dados', () async {
    await populate();
    final before = await service.exportJson();
    final badData = parseBackup(before);
    final broken = BackupData(
      works: badData.works,
      sessions: badData.sessions,
      notes: badData.notes,
      quotes: badData.quotes,
      analyses: badData.analyses,
      links: [
        AnalysisWork(analysisId: 99, workId: 99),
      ],
    );

    expect(service.importBackup(broken), throwsA(isA<BackupException>()));
    expect(await service.exportJson(), before);
  });

  test('rejeita JSON inválido', () {
    expect(
      () => parseBackup('{'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          AppStrings.invalidJson,
        ),
      ),
    );
  });

  test('rejeita estrutura inválida', () {
    expect(
      () => parseBackup(jsonEncode({'version': backupVersion})),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          AppStrings.invalidBackup,
        ),
      ),
    );
  });

  test('rejeita versão não suportada', () {
    expect(
      () => parseBackup(jsonEncode({'version': backupVersion + 1})),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          AppStrings.unsupportedVersion,
        ),
      ),
    );
  });
}
