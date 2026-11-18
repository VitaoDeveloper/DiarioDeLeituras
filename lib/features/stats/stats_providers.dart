import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';

final readingSessionsProvider = StreamProvider<List<ReadingSession>>((ref) {
  return ref.watch(appDatabaseProvider).readingSessionsDao.watchAll();
});
