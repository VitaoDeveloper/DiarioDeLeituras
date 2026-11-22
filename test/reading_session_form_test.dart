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

class _FormHost extends StatelessWidget {
  const _FormHost({
    required this.work,
    required this.reading,
    required this.currentTotal,
    this.session,
  });

  final Work work;
  final Reading reading;
  final int currentTotal;
  final ReadingSession? session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReadingSessionFormDialog(
        work: work,
        reading: reading,
        currentTotal: currentTotal,
        session: session,
      ),
    );
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

  Future<void> openForm(
    WidgetTester tester, {
    required int currentTotal,
    ReadingSession? session,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => _FormHost(
                work: work,
                reading: reading,
                currentTotal: currentTotal,
                session: session,
              ),
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
  }

  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, 10);
    await db.close();
  }

  Future<void> addExistingSession() async {
    await db.readingSessionsDao.insertSession(
      ReadingSessionsCompanion(
        workId: Value(workId),
        readingId: Value(reading.id),
        date: Value(DateTime(2026, 1, 1)),
        pagesRead: const Value(80),
      ),
    );
  }

  testWidgets('bloqueia sessão que ultrapassa o total de páginas',
      (tester) async {
    await addExistingSession();
    await openForm(tester, currentTotal: 80);

    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.tap(find.text(AppStrings.save));
    await pumpFrames(tester);

    expect(find.text(AppStrings.pagesOverflowValidation), findsOneWidget);
    final sessions = await db.select(db.readingSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.pagesRead, 80);
    await closeApp(tester);
  });

  testWidgets('permite editar sessão já computada no total da leitura',
      (tester) async {
    await addExistingSession();
    final session = (await db.select(db.readingSessions).get()).single;
    // A tela de detalhe desconta a sessão em edição do total da leitura.
    await openForm(tester, currentTotal: 0, session: session);

    await tester.enterText(find.byType(TextFormField).first, '90');
    await tester.tap(find.text(AppStrings.save));
    await pumpFrames(tester, 15);

    final sessions = await db.select(db.readingSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.pagesRead, 90);
    await closeApp(tester);
  });
}
