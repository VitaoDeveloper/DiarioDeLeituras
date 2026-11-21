import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import 'works_providers.dart';

final readingsDaoProvider = Provider<ReadingsDao>((ref) {
  return ref.watch(appDatabaseProvider).readingsDao;
});

final readingsProvider = StreamProvider<List<Reading>>((ref) {
  return ref.watch(readingsDaoProvider).watchAll();
});

final readingsForWorkProvider =
    StreamProvider.family<List<Reading>, int>((ref, workId) {
  return ref.watch(readingsDaoProvider).watchByWork(workId);
});

final readingProvider = StreamProvider.family<Reading?, int>((ref, readingId) {
  return ref.watch(readingsDaoProvider).watchById(readingId);
});

final sessionsForReadingProvider =
    StreamProvider.family<List<ReadingSession>, int>((ref, readingId) {
  return ref.watch(readingSessionsDaoProvider).watchByReading(readingId);
});

/// Dados de uma leitura informados pelos formulários.
class ReadingWrite {
  const ReadingWrite({
    required this.status,
    this.rating,
    this.startedAt,
    this.finishedAt,
  });

  final String status;
  final double? rating;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  ReadingWrite normalized(DateTime now) => ReadingWrite(
        status: status,
        rating: rating,
        startedAt: status == WorkStatus.lendo ? (startedAt ?? now) : startedAt,
        finishedAt:
            status == WorkStatus.lido ? (finishedAt ?? now) : finishedAt,
      );
}

/// Não é permitido remover a única leitura de uma obra.
class LastReadingException implements Exception {
  const LastReadingException();
}

/// Mantém os campos legados de `works` espelhando a leitura mais recente.
/// Assim, listagens antigas e backups continuam mostrando o estado atual.
Future<void> syncWorkReading(AppDatabase db, int workId) async {
  final work = await db.worksDao.findById(workId);
  if (work == null) return;

  final readings = await db.readingsDao.getByWork(workId);
  final latest = readings.isEmpty ? null : readings.last;
  await db.worksDao.updateWork(
    work.copyWith(
      status: latest?.status ?? WorkStatus.queroLer,
      rating: Value(latest?.rating),
      startedAt: Value(latest?.startedAt),
      finishedAt: Value(latest?.finishedAt),
    ),
  );
}

Future<int> createWorkWithReading({
  required AppDatabase db,
  required WorksCompanion work,
  required ReadingWrite reading,
  required DateTime now,
}) async {
  final data = reading.normalized(now);
  return db.transaction(() async {
    final workId = await db.worksDao.insertWork(work);
    await db.readingsDao.insertReading(
      ReadingsCompanion(
        workId: Value(workId),
        number: const Value(1),
        status: Value(data.status),
        rating: Value(data.rating),
        startedAt: Value(data.startedAt),
        finishedAt: Value(data.finishedAt),
        createdAt: Value(now),
      ),
    );
    await syncWorkReading(db, workId);
    return workId;
  });
}

Future<int> addReading({
  required AppDatabase db,
  required int workId,
  required ReadingWrite reading,
  required DateTime now,
}) async {
  final data = reading.normalized(now);
  return db.transaction(() async {
    final existing = await db.readingsDao.getByWork(workId);
    if (existing.isEmpty) {
      throw StateError('A obra precisa ter ao menos uma leitura.');
    }
    final number = existing.fold<int>(
      0,
      (max, item) => item.number > max ? item.number : max,
    );

    final readingId = await db.readingsDao.insertReading(
      ReadingsCompanion(
        workId: Value(workId),
        number: Value(number + 1),
        status: Value(data.status),
        rating: Value(data.rating),
        startedAt: Value(data.startedAt),
        finishedAt: Value(data.finishedAt),
        createdAt: Value(now),
      ),
    );
    await syncWorkReading(db, workId);
    return readingId;
  });
}

Future<void> saveReading({
  required AppDatabase db,
  required Reading reading,
  required ReadingWrite data,
  required DateTime now,
}) async {
  final normalized = data.normalized(now);
  await db.transaction(() async {
    await db.readingsDao.updateReading(
      reading.copyWith(
        status: normalized.status,
        rating: Value(normalized.rating),
        startedAt: Value(normalized.startedAt),
        finishedAt: Value(normalized.finishedAt),
      ),
    );
    await syncWorkReading(db, reading.workId);
  });
}

Future<void> deleteReading({
  required AppDatabase db,
  required int readingId,
}) async {
  await db.transaction(() async {
    final reading = await db.readingsDao.findById(readingId);
    if (reading == null) return;

    final readings = await db.readingsDao.getByWork(reading.workId);
    if (readings.length <= 1) throw const LastReadingException();

    await db.readingsDao.deleteReading(readingId);
    await syncWorkReading(db, reading.workId);
  });
}
