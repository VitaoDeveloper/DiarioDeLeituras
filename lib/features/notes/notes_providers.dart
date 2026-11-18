import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';

final notesDaoProvider = Provider<NotesDao>((ref) {
  return ref.watch(appDatabaseProvider).notesDao;
});

final quotesDaoProvider = Provider<QuotesDao>((ref) {
  return ref.watch(appDatabaseProvider).quotesDao;
});

final notesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(notesDaoProvider).watchAll();
});

final notesForWorkProvider = StreamProvider.family<List<Note>, int>((ref, workId) {
  return ref.watch(notesDaoProvider).watchByWork(workId);
});

final quotesForNoteProvider =
    StreamProvider.family<List<Quote>, int>((ref, noteId) {
  return ref.watch(quotesDaoProvider).watchByNote(noteId);
});
