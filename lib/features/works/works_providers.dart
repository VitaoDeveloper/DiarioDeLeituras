import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';

final worksProvider = StreamProvider<List<Work>>((ref) {
  return ref.watch(appDatabaseProvider).worksDao.watchAll();
});

final sessionsForWorkProvider =
    StreamProvider.family<List<ReadingSession>, int>((ref, workId) {
  return ref.watch(appDatabaseProvider).readingSessionsDao.watchByWork(workId);
});
