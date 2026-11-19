import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';

final analysesDaoProvider = Provider<AnalysesDao>((ref) {
  return ref.watch(appDatabaseProvider).analysesDao;
});

final analysisWorksDaoProvider = Provider<AnalysisWorksDao>((ref) {
  return ref.watch(appDatabaseProvider).analysisWorksDao;
});

final analysesProvider = StreamProvider<List<Analysis>>((ref) {
  return ref.watch(analysesDaoProvider).watchAll();
});

final linksForAnalysisProvider =
    StreamProvider.family<List<AnalysisWork>, int>((ref, analysisId) {
  return ref.watch(analysisWorksDaoProvider).watchByAnalysis(analysisId);
});

/// Grava a análise e o diff de vínculos. Deve ser chamado dentro de uma
/// transação do banco para que análise e vínculos sejam gravados juntos.
Future<int> writeAnalysis({
  required AppDatabase db,
  required Analysis? existing,
  required String title,
  required String body,
  required Set<int> workIds,
  required DateTime now,
}) async {
  final int analysisId;
  if (existing == null) {
    analysisId = await db.analysesDao.insertAnalysis(
      AnalysesCompanion(
        title: Value(title),
        body: Value(body),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  } else {
    analysisId = existing.id;
    await db.analysesDao.updateAnalysis(
      existing.copyWith(
        title: title,
        body: body,
        updatedAt: now,
      ),
    );
  }

  final links = await db.analysisWorksDao.getByAnalysis(analysisId);
  final currentIds = links.map((link) => link.workId).toSet();
  for (final workId in workIds.difference(currentIds)) {
    await db.analysisWorksDao.insertLink(
      AnalysisWorksCompanion(
        analysisId: Value(analysisId),
        workId: Value(workId),
      ),
    );
  }
  for (final workId in currentIds.difference(workIds)) {
    await db.analysisWorksDao.deleteLink(analysisId, workId);
  }
  return analysisId;
}
