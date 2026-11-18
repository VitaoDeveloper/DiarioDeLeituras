import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';

final notesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(appDatabaseProvider).notesDao.watchAll();
});

final quotesForNoteProvider =
    StreamProvider.family<List<Quote>, int>((ref, noteId) {
  return ref.watch(appDatabaseProvider).quotesDao.watchByNote(noteId);
});
