import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/core/formatters.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/works/reading_session_form.dart';
import 'package:reading_management/features/works/readings_providers.dart';
import 'package:reading_management/features/works/works_providers.dart';

Future<void> pumpFrames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    await initializeFormatting();
  });

  late AppDatabase db;
  late Work work;
  late Reading reading;
  late int workId;

  setUp(() async {
    db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 1, 1);
    workId = await createWorkWithReading(
      db: db,
      work: WorksCompanion(
        type: Value(WorkType.livro),
        title: const Value('Obra'),
        author: const Value('Autor'),
        genre: const Value('Gênero'),
        pages: const Value(100),
      ),
      reading: const ReadingWrite(status: WorkStatus.lendo),
      now: now,
    );
    work = (await db.worksDao.findById(workId))!;
    reading = (await db.readingsDao.getByWork(workId)).single;
  });

  Future<void> openDialog(
    WidgetTester tester, {
    required int currentTotal,
    ReadingSession? session,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: SizedBox(key: Key('dialog-host')),
        ),
      ),
    );
    unawaited(
      showDialog<bool>(
        context: tester.element(find.byKey(const Key('dialog-host'))),
        builder: (_) => ReadingSessionFormDialog(
          work: work,
          reading: reading,
          currentTotal: currentTotal,
          session: session,
        ),
      ),
    );
    await pumpFrames(tester);
  }

  testWidgets('bloqueia sessão que ultrapassa o total de páginas',
      (tester) async {
    await db.readingSessionsDao.insertSession(
      ReadingSessionsCompanion(
        workId: Value(workId),
        readingId: Value(reading.id),
        date: const Value(DateTime(2026, 1, 1)),
        pagesRead: const Value(80),
      ),
    );
    await openDialog(tester, currentTotal: 80);

    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.tap(find.text(AppStrings.save));
    await pumpFrames(tester);

    expect(find.text(AppStrings.pagesOverflowValidation), findsOneWidget);
    final sessions = await db.readingSessionsDao.watchByReading(reading.id).first;
    expect(sessions, hasLength(1));
    expect(sessions.single.pagesRead, 80);
  });

  testWidgets('permite editar sessão já computada no total da leitura',
      (tester) async {
    await db.readingSessionsDao.insertSession(
      ReadingSessionsCompanion(
        workId: Value(workId),
        readingId: Value(reading.id),
        date: const Value(DateTime(2026, 1, 1)),
        pagesRead: const Value(80),
      ),
    );
    final session =
        (await db.readingSessionsDao.watchByReading(reading.id).first).single;
    // A tela de detalhe desconta a sessão em edição do total da leitura.
    await openDialog(tester, currentTotal: 0, session: session);

    await tester.enterText(find.byType(TextFormField).first, '90');
    await tester.tap(find.text(AppStrings.save));
    await pumpFrames(tester, 15);

    final sessions = await db.readingSessionsDao.watchByReading(reading.id).first;
    expect(sessions, hasLength(1));
    expect(sessions.single.pagesRead, 90);
  });
}
