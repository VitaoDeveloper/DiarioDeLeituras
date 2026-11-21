import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/app.dart';
import 'package:reading_management/core/formatters.dart';
import 'package:reading_management/core/router.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';
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
  late int workId;
  late int secondReadingId;

  setUp(() async {
    db = AppDatabase.connect(NativeDatabase.memory());
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
    secondReadingId = await addReading(
      db: db,
      workId: workId,
      reading: const ReadingWrite(status: WorkStatus.lido),
      now: now,
    );
    await db.readingSessionsDao.insertSession(
      ReadingSessionsCompanion(
        workId: Value(workId),
        readingId: Value(secondReadingId),
        date: Value(now),
        pagesRead: const Value(30),
      ),
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          worksProvider.overrideWith((ref) => db.worksDao.watchAll()),
          genresProvider.overrideWithValue(const <String>[]),
          streakProvider.overrideWithValue(
            const StreakInfo(
              current: 0,
              best: 0,
              atRisk: false,
              readDays: <int>{},
            ),
          ),
        ],
        child: const App(),
      ),
    );
    appRouter.go('/works/$workId');
    await pumpFrames(tester, 20);

    // Desmonta o escopo antes de fechar o banco para cancelar os streams.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpFrames(tester, 5);
      await db.close();
    });
  }

  testWidgets('exclui leitura pelo diálogo no roteador real', (tester) async {
    await pumpApp(tester);

    final card = find.ancestor(
      of: find.text(AppStrings.readingLabel(2)),
      matching: find.byType(Card),
    );
    final deleteButton = find.descendant(
      of: card,
      matching: find.byIcon(Icons.delete),
    ).first;
    await tester.ensureVisible(deleteButton);
    await pumpFrames(tester);
    await tester.tap(deleteButton);
    await pumpFrames(tester);

    expect(find.byType(AlertDialog), findsOneWidget);

    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(AppStrings.delete),
    );
    await tester.tap(confirmButton);
    await pumpFrames(tester, 20);

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      (await db.readingsDao.getByWork(workId)).map((item) => item.number),
      [1],
    );
    expect(
      await db.readingSessionsDao.watchByReading(secondReadingId).first,
      isEmpty,
    );
  });
}
