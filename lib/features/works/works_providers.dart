import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../analyses/analyses_providers.dart';

final worksDaoProvider = Provider<WorksDao>((ref) {
  return ref.watch(appDatabaseProvider).worksDao;
});

final readingSessionsDaoProvider = Provider<ReadingSessionsDao>((ref) {
  return ref.watch(appDatabaseProvider).readingSessionsDao;
});

final worksProvider = StreamProvider<List<Work>>((ref) {
  return ref.watch(worksDaoProvider).watchAll();
});

final workProvider = StreamProvider.family<Work?, int>((ref, workId) {
  return ref.watch(worksDaoProvider).watchById(workId);
});

final sessionsForWorkProvider =
    StreamProvider.family<List<ReadingSession>, int>((ref, workId) {
  return ref.watch(readingSessionsDaoProvider).watchByWork(workId);
});

final genresProvider = Provider<List<String>>((ref) {
  final works = ref.watch(worksProvider).value ?? const <Work>[];
  final genres = works
      .map((work) => work.genre.trim())
      .where((genre) => genre.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return genres;
});

final linksForWorkProvider =
    StreamProvider.family<List<AnalysisWork>, int>((ref, workId) {
  return ref.watch(appDatabaseProvider).analysisWorksDao.watchByWork(workId);
});

final analysesForWorkProvider = Provider.family<List<Analysis>, int>((
  ref,
  workId,
) {
  final analyses = ref.watch(analysesProvider).value ?? const <Analysis>[];
  final links = ref.watch(linksForWorkProvider(workId)).value ??
      const <AnalysisWork>[];
  final linkedIds = links.map((link) => link.analysisId).toSet();
  return analyses.where((analysis) => linkedIds.contains(analysis.id)).toList();
});
