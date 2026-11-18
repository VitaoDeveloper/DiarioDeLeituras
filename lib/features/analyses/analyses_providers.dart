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
