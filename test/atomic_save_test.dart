import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/analyses/analyses_providers.dart';
import 'package:reading_management/features/notes/notes_providers.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 1, 2, 3, 4, 5);

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> createWork() => db.into(db.works).insert(
        WorksCompanion(
          type: Value(WorkType.livro),
          title: const Value('Obra'),
          author: const Value('Autor'),
          genre: const Value('Gênero'),
          status: Value(WorkStatus.queroLer),
        ),
      );

  test('falha no vínculo não deixa análise gravada', () async {
    await expectLater(
      db.transaction(
        () => writeAnalysis(
          db: db,
          existing: null,
          title: 'Análise',
          body: 'Corpo',
          workIds: const {999},
          now: now,
        ),
      ),
      throwsA(anything),
    );

    expect(await db.select(db.analyses).get(), isEmpty);
    expect(await db.select(db.analysisWorks).get(), isEmpty);
  });

  test('falha na citação não deixa fichamento gravado', () async {
    final workId = await createWork();

    await expectLater(
      db.transaction(
        () => writeNote(
          db: db,
          existing: null,
          workId: workId,
          label: 'Cap. 1',
          summary: 'Resumo',
          thesis: 'Tese',
          concepts: 'Conceitos',
          critique: 'Crítica',
          quotes: const [
            QuoteWrite(content: 'Citação inválida', targetNoteId: 999),
          ],
          originalQuoteIds: const <int>{},
          now: now,
        ),
      ),
      throwsA(anything),
    );

    expect(await db.select(db.notes).get(), isEmpty);
    expect(await db.select(db.quotes).get(), isEmpty);
  });

  test('análise e vínculos são gravados juntos', () async {
    final workId = await createWork();
    final analysisId = await db.transaction(
      () => writeAnalysis(
        db: db,
        existing: null,
        title: 'Análise',
        body: 'Corpo',
        workIds: {workId},
        now: now,
      ),
    );

    expect(await db.select(db.analyses).get(), hasLength(1));
    expect(await db.analysisWorksDao.getByAnalysis(analysisId), hasLength(1));

    final saved = await db.analysesDao.findById(analysisId);
    await db.transaction(
      () => writeAnalysis(
        db: db,
        existing: saved,
        title: 'Análise revisada',
        body: 'Corpo revisado',
        workIds: const <int>{},
        now: now,
      ),
    );

    expect(await db.select(db.analyses).get(), hasLength(1));
    expect(await db.analysisWorksDao.getByAnalysis(analysisId), isEmpty);
  });

  test('fichamento e citações são gravados juntos', () async {
    final workId = await createWork();
    final noteId = await db.transaction(
      () => writeNote(
        db: db,
        existing: null,
        workId: workId,
        label: 'Cap. 1',
        summary: 'Resumo',
        thesis: 'Tese',
        concepts: 'Conceitos',
        critique: 'Crítica',
        quotes: const [QuoteWrite(content: 'Citação')],
        originalQuoteIds: const <int>{},
        now: now,
      ),
    );

    final quotes = await db.quotesDao.getByNote(noteId);
    expect(quotes, hasLength(1));
    expect(quotes.single.noteId, noteId);
  });
}
