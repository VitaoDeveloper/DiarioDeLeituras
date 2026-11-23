import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_management/app.dart';
import 'package:reading_management/core/formatters.dart';
import 'package:reading_management/core/router.dart';
import 'package:reading_management/core/strings.dart';
import 'package:reading_management/data/backup_service.dart';
import 'package:reading_management/data/database.dart';
import 'package:reading_management/features/stats/stats_providers.dart';
import 'package:reading_management/features/works/works_providers.dart';

Future<void> pumpFrames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _FakeBackupService extends BackupService {
  _FakeBackupService(super.db, this.data);

  final BackupData data;
  bool imported = false;

  @override
  Future<BackupData?> pickBackup() async => data;

  @override
  Future<void> importBackup(BackupData value) async {
    imported = true;
    await super.importBackup(value);
  }
}

void main() {
  setUpAll(() async {
    await initializeFormatting();
  });

  late AppDatabase db;
  late _FakeBackupService service;

  Future<void> pumpSettings(WidgetTester tester) async {
    db = AppDatabase.connect(NativeDatabase.memory());
    service = _FakeBackupService(
      db,
      const BackupData(
        works: [],
        readings: [],
        sessions: [],
        notes: [],
        quotes: [],
        analyses: [],
        links: [],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          backupServiceProvider.overrideWithValue(service),
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
    appRouter.go('/settings');
    await pumpFrames(tester, 20);
  }

  Future<void> closeApp(WidgetTester tester) async {
    // Desmonta o escopo antes de fechar o banco para cancelar os streams.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpFrames(tester, 10);
    await db.close();
  }

  testWidgets('confirmar importação executa a importação e volta para Obras', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text(AppStrings.exportData), findsOneWidget);

    await tester.tap(find.text(AppStrings.importData));
    await pumpFrames(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.confirm),
      ),
    );
    await pumpFrames(tester, 20);

    expect(service.imported, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    // A restauração bem-sucedida leva de volta à lista de obras.
    expect(find.text(AppStrings.importSuccess), findsOneWidget);
    expect(find.text(AppStrings.works), findsWidgets);
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });

  testWidgets('cancelar importação não altera os dados', (tester) async {
    await pumpSettings(tester);
    expect(find.text(AppStrings.exportData), findsOneWidget);

    await tester.tap(find.text(AppStrings.importData));
    await pumpFrames(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(AppStrings.cancel),
      ),
    );
    await pumpFrames(tester, 20);

    expect(service.imported, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(AppStrings.exportData), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });
}
