import 'package:drift/drift.dart' show Value;
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

/// Dados de uma citação a gravar. [original] identifica uma citação já salva.
class QuoteWrite {
  const QuoteWrite({
    this.original,
    required this.content,
    this.page,
    this.comment,
    this.targetNoteId,
  });

  final Quote? original;
  final String content;
  final int? page;
  final String? comment;

  /// Id do fichamento da citação. Quando omitido, usa o fichamento salvo.
  final int? targetNoteId;
}

/// Grava o fichamento e todas as operações de citações. Deve ser chamado dentro
/// de uma transação do banco para que nada fique parcial em caso de erro.
Future<int> writeNote({
  required AppDatabase db,
  required Note? existing,
  required int workId,
  required String label,
  required String summary,
  required String thesis,
  required String concepts,
  required String critique,
  required List<QuoteWrite> quotes,
  required Set<int> originalQuoteIds,
  required DateTime now,
}) async {
  final int noteId;
  if (existing == null) {
    noteId = await db.notesDao.insertNote(
      NotesCompanion(
        workId: Value(workId),
        label: Value(label),
        summary: Value(summary),
        thesis: Value(thesis),
        concepts: Value(concepts),
        critique: Value(critique),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  } else {
    noteId = existing.id;
    await db.notesDao.updateNote(
      existing.copyWith(
        workId: workId,
        label: label,
        summary: summary,
        thesis: thesis,
        concepts: concepts,
        critique: critique,
        updatedAt: now,
      ),
    );
  }

  final keptQuoteIds = <int>{};
  for (final quote in quotes) {
    final original = quote.original;
    if (original == null) {
      await db.quotesDao.insertQuote(
        QuotesCompanion(
          noteId: Value(quote.targetNoteId ?? noteId),
          content: Value(quote.content),
          page: Value(quote.page),
          comment: Value(quote.comment),
        ),
      );
    } else {
      await db.quotesDao.updateQuote(
        original.copyWith(
          content: quote.content,
          page: Value(quote.page),
          comment: Value(quote.comment),
        ),
      );
      keptQuoteIds.add(original.id);
    }
  }

  for (final id in originalQuoteIds.difference(keptQuoteIds)) {
    await db.quotesDao.deleteQuote(id);
  }
  return noteId;
}
