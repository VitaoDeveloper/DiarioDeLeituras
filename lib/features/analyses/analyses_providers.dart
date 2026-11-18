import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';

final analysesProvider = StreamProvider<List<Analysis>>((ref) {
  return ref.watch(appDatabaseProvider).analysesDao.watchAll();
});

final linksForAnalysisProvider =
    StreamProvider.family<List<AnalysisWork>, int>((ref, analysisId) {
  return ref
      .watch(appDatabaseProvider)
      .analysisWorksDao
      .watchByAnalysis(analysisId);
});
